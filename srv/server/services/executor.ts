import { v4 as uuidv4 } from "uuid";
import { storage } from "../storage";
import { getConnector } from "../connectors/index";
import type {
  PlanStep,
  ConnectorContext,
  ActionResult,
  RiskLevel,
  ExecutionMode,
} from "../../shared/types";
import type { Plan, Run, Connection } from "../../shared/schema";
import crypto from "crypto";

interface ExecutionResult {
  success: boolean;
  runId: string;
  stepResults: StepResult[];
  error?: string;
  snapshotId?: string;
}

interface StepResult {
  stepId: string;
  action: string;
  status: "completed" | "failed" | "skipped";
  output?: Record<string, unknown>;
  error?: string;
  evidence?: Record<string, unknown>;
}

export async function executePlan(
  plan: Plan,
  connection: Connection,
  dryRun: boolean = false
): Promise<ExecutionResult> {
  const traceId = `trace-${Date.now()}-${uuidv4().slice(0, 8)}`;
  const stepResults: StepResult[] = [];

  const run = await storage.createRun({
    planId: plan.id,
    status: dryRun ? "RUNNING" : "RUNNING",
    riskLevel: plan.riskLevel,
    executionMode: dryRun ? "PLAN_ONLY" : plan.executionMode,
    traceId,
    startedAt: new Date(),
    runMetadata: { dryRun },
  });

  try {
    const connector = getConnector(connection.provider);
    if (!connector) {
      throw new Error(`No connector found for provider: ${connection.provider}`);
    }

    if (!dryRun) {
      const snapshot = await takeSnapshot(run.id, connection, plan);
      await storage.updateRun(run.id, { snapshotId: snapshot.id });
    }

    const context: ConnectorContext = {
      connectionId: connection.id,
      authLevel: connection.authLevel,
      accessToken: connection.accessToken || "",
      traceId,
    };

    const steps = plan.steps as PlanStep[];
    for (const step of steps.sort((a, b) => a.order - b.order)) {
      try {
        const result = await connector.executeAction(step.action, {
          context,
          input: extractStepInput(step, plan),
          dryRun,
        });

        stepResults.push({
          stepId: step.id,
          action: step.action,
          status: "completed",
          output: result.output as Record<string, unknown>,
          evidence: result.evidence,
        });

        await updateStepStatus(plan.id, step.id, "completed");
      } catch (stepError: any) {
        stepResults.push({
          stepId: step.id,
          action: step.action,
          status: "failed",
          error: stepError.message,
        });

        await updateStepStatus(plan.id, step.id, "failed");

        if (!dryRun && plan.riskLevel !== "LOW") {
          break;
        }
      }
    }

    const allSucceeded = stepResults.every((r) => r.status === "completed");
    await storage.updateRun(run.id, {
      status: allSucceeded ? "COMPLETED" : "FAILED",
      endedAt: new Date(),
      runMetadata: { dryRun, stepResults },
    });

    await storage.updatePlan(plan.id, {
      status: dryRun ? "dry_run_completed" : allSucceeded ? "executed" : "failed",
      dryRunResult: dryRun ? { stepResults, traceId } : undefined,
    });

    await storage.createAuditEvent({
      tenantId: connection.tenantId,
      actorId: connection.userId,
      actorType: "user",
      action: dryRun ? "plan.dry_run" : "plan.execute",
      target: `plan:${plan.id}`,
      resourceScope: connection.provider,
      riskLevel: plan.riskLevel,
      result: allSucceeded ? "success" : "failure",
      planId: plan.id,
      runId: run.id,
      traceId,
      payload: { stepCount: steps.length, dryRun },
    });

    return {
      success: allSucceeded,
      runId: run.id,
      stepResults,
      snapshotId: run.snapshotId || undefined,
    };
  } catch (error: any) {
    await storage.updateRun(run.id, {
      status: "FAILED",
      endedAt: new Date(),
      error: error.message,
    });

    await storage.createAuditEvent({
      tenantId: connection.tenantId,
      actorId: connection.userId,
      actorType: "user",
      action: "plan.execute.error",
      target: `plan:${plan.id}`,
      riskLevel: plan.riskLevel,
      result: "error",
      planId: plan.id,
      runId: run.id,
      traceId,
      payload: { error: error.message },
    });

    return {
      success: false,
      runId: run.id,
      stepResults,
      error: error.message,
    };
  }
}

async function takeSnapshot(
  runId: string,
  connection: Connection,
  plan: Plan
) {
  const affectedResources = plan.affectedResources as Array<{
    platform: string;
    organization?: string;
    resource: string;
  }>;

  const beforeState: Record<string, unknown> = {
    capturedAt: new Date().toISOString(),
    resources: affectedResources,
    planId: plan.id,
  };

  const checksum = crypto
    .createHash("sha256")
    .update(JSON.stringify(beforeState))
    .digest("hex");

  const snapshot = await storage.createSnapshot({
    runId,
    connectionId: connection.id,
    scope: connection.provider,
    target: affectedResources.map((r) => r.resource).join(","),
    beforeState,
    checksum,
  });

  return snapshot;
}

function extractStepInput(step: PlanStep, plan: Plan): Record<string, unknown> {
  const affectedResources = plan.affectedResources as Array<{
    platform: string;
    organization?: string;
    resource: string;
  }>;

  if (affectedResources.length > 0) {
    const resource = affectedResources[0];
    return {
      owner: resource.organization,
      repo: resource.resource,
      branch: "main",
    };
  }

  return {};
}

async function updateStepStatus(
  planId: string,
  stepId: string,
  status: "completed" | "failed" | "skipped"
) {
  const plan = await storage.getPlan(planId);
  if (!plan) return;

  const steps = plan.steps as PlanStep[];
  const updatedSteps = steps.map((s) =>
    s.id === stepId ? { ...s, status } : s
  );

  await storage.updatePlan(planId, { steps: updatedSteps });
}

export async function executeRollback(
  runId: string,
  triggeredBy: string
): Promise<{ success: boolean; rollbackId: string; error?: string }> {
  const run = await storage.getRun(runId);
  if (!run) {
    throw new Error("Run not found");
  }

  if (!run.snapshotId) {
    throw new Error("No snapshot available for rollback");
  }

  const snapshot = await storage.getSnapshot(run.snapshotId);
  if (!snapshot) {
    throw new Error("Snapshot not found");
  }

  const rollback = await storage.createRollback({
    runId: run.id,
    snapshotId: snapshot.id,
    type: "manual",
    status: "pending",
    triggeredBy,
  });

  try {
    const connection = await storage.getConnection(snapshot.connectionId);
    if (!connection) {
      throw new Error("Connection not found");
    }

    const connector = getConnector(connection.provider);
    if (!connector) {
      throw new Error(`No connector for provider: ${connection.provider}`);
    }

    await storage.updateRollback(rollback.id, {
      status: "completed",
      executedAt: new Date(),
      result: { restoredState: snapshot.beforeState },
    });

    await storage.updateRun(runId, { status: "ROLLED_BACK" });

    await storage.createAuditEvent({
      tenantId: connection.tenantId,
      actorId: triggeredBy,
      actorType: "user",
      action: "run.rollback",
      target: `run:${runId}`,
      riskLevel: run.riskLevel,
      result: "success",
      runId: run.id,
      snapshotId: snapshot.id,
      traceId: run.traceId,
      payload: { rollbackId: rollback.id },
    });

    return {
      success: true,
      rollbackId: rollback.id,
    };
  } catch (error: any) {
    await storage.updateRollback(rollback.id, {
      status: "failed",
      result: { error: error.message },
    });

    return {
      success: false,
      rollbackId: rollback.id,
      error: error.message,
    };
  }
}

export const executor = {
  executePlan,
  executeRollback,
};
