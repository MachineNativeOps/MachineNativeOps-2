import { Router, type Request, type Response, type NextFunction } from "express";
import { v4 as uuidv4 } from "uuid";
import { storage } from "./storage";
import { getConnector, getAvailableProviders } from "./connectors/index";
import { planner } from "./services/planner";
import { executor } from "./services/executor";
import { basicRateLimit } from "./middleware/rate-limit";
import type { ApiResponse } from "../shared/types";

const router = Router();

const DEMO_USER_ID = "00000000-0000-0000-0000-000000000002";
const DEMO_TENANT_ID = "00000000-0000-0000-0000-000000000001";

function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

function sendResponse<T>(res: Response, data: T, status: number = 200) {
  const response: ApiResponse<T> = {
    success: true,
    data,
    traceId: `trace-${Date.now()}`,
  };
  res.status(status).json(response);
}

function sendError(res: Response, message: string, status: number = 400) {
  const response: ApiResponse<null> = {
    success: false,
    error: message,
    traceId: `trace-${Date.now()}`,
  };
  res.status(status).json(response);
}

router.get("/api/health", (_req, res) => {
  sendResponse(res, {
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  });
});

router.post(
  "/api/auth/demo-login",
  asyncHandler(async (_req, res) => {
    const user = await storage.createDemoUserIfNeeded();
    sendResponse(res, {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        tenantId: user.tenantId,
      },
      token: `demo-token-${user.id}`,
    });
  })
);

router.get(
  "/api/connections",
  asyncHandler(async (req, res) => {
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;
    const connections = await storage.getConnectionsByUser(userId);
    sendResponse(res, connections);
  })
);

router.post(
  "/api/connections/:provider/start",
  basicRateLimit,
  asyncHandler(async (req, res) => {
    const { provider } = req.params;
    const connector = getConnector(provider);

    if (!connector) {
      return sendError(res, `Unknown provider: ${provider}`, 404);
    }

    const state = uuidv4();
    const authUrl = connector.generateOAuthUrl(state);

    sendResponse(res, {
      authUrl,
      state,
      provider,
    });
  })
);

router.post(
  "/api/connections/:provider/callback",
  basicRateLimit,
  asyncHandler(async (req, res) => {
    const { provider } = req.params;
    const { code, state } = req.body;
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;

    const connector = getConnector(provider);
    if (!connector) {
      return sendError(res, `Unknown provider: ${provider}`, 404);
    }

    try {
      const tokens = await connector.exchangeCodeForToken(code);

      const connection = await storage.createConnection({
        tenantId: DEMO_TENANT_ID,
        userId,
        provider,
        authLevel: "READ",
        scopes: [],
        status: "ACTIVE",
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        tokenExpiresAt: tokens.expiresAt,
      });

      sendResponse(res, connection, 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  })
);

router.post(
  "/api/connections/:provider/connect",
  asyncHandler(async (req, res) => {
    const { provider } = req.params;
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;

    const connector = getConnector(provider);
    if (!connector) {
      return sendError(res, `Unknown provider: ${provider}`, 404);
    }

    try {
      const tokens = await connector.exchangeCodeForToken("demo");

      const connection = await storage.createConnection({
        tenantId: DEMO_TENANT_ID,
        userId,
        provider,
        accountId: "demo-account",
        accountName: "Demo GitHub Account",
        authLevel: "WRITE_HIGH",
        scopes: ["repo", "read:org", "admin:repo_hook", "read:user"],
        status: "ACTIVE",
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        tokenExpiresAt: tokens.expiresAt,
      });

      const capabilities = await connector.discoverCapabilities(tokens.accessToken);
      
      await storage.createCapabilityProfile({
        connectionId: connection.id,
        actions: capabilities.actions,
        readableCapabilities: capabilities.readableScopes,
        writeCapabilities: capabilities.writableScopes,
        limitations: capabilities.missingScopes,
      });

      await storage.updateConnection(connection.id, {
        lastDiscoveredAt: new Date(),
      });

      await storage.createAuditEvent({
        tenantId: DEMO_TENANT_ID,
        actorId: userId,
        actorType: "user",
        action: "connection.create",
        target: `connection:${connection.id}`,
        resourceScope: provider,
        result: "success",
        payload: { provider, demoMode: true },
      });

      sendResponse(res, {
        ...connection,
        capabilities,
      }, 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  })
);

router.post(
  "/api/connections/:provider/discover",
  asyncHandler(async (req, res) => {
    const { provider } = req.params;
    const { connectionId } = req.body;

    const connection = await storage.getConnection(connectionId);
    if (!connection) {
      return sendError(res, "Connection not found", 404);
    }

    const connector = getConnector(provider);
    if (!connector) {
      return sendError(res, `Unknown provider: ${provider}`, 404);
    }

    try {
      const capabilities = await connector.discoverCapabilities(
        connection.accessToken || ""
      );

      const profile = await storage.createCapabilityProfile({
        connectionId: connection.id,
        actions: capabilities.actions,
        readableCapabilities: capabilities.readableScopes,
        writeCapabilities: capabilities.writableScopes,
        limitations: capabilities.missingScopes,
      });

      await storage.updateConnection(connection.id, {
        lastDiscoveredAt: new Date(),
        authLevel: capabilities.writableScopes.length > 0 ? "WRITE_LOW" : "READ",
      });

      sendResponse(res, profile);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  })
);

router.get(
  "/api/connections/:id/capabilities",
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const profile = await storage.getCapabilityProfile(id);

    if (!profile) {
      return sendError(res, "Capability profile not found", 404);
    }

    sendResponse(res, profile);
  })
);

router.get(
  "/api/chat/sessions",
  asyncHandler(async (req, res) => {
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;
    const sessions = await storage.getChatSessions(userId);
    sendResponse(res, sessions);
  })
);

router.post(
  "/api/chat/sessions",
  asyncHandler(async (req, res) => {
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;
    const { title } = req.body;

    const session = await storage.createChatSession({
      tenantId: DEMO_TENANT_ID,
      userId,
      title: title || "New Chat",
      status: "active",
    });

    sendResponse(res, session, 201);
  })
);

router.get(
  "/api/chat/sessions/:id/messages",
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const messages = await storage.getMessages(id);
    sendResponse(res, messages);
  })
);

router.post(
  "/api/chat/sessions/:id/messages",
  asyncHandler(async (req, res) => {
    const { id: sessionId } = req.params;
    const { content } = req.body;
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;

    const session = await storage.getChatSession(sessionId);
    if (!session) {
      return sendError(res, "Session not found", 404);
    }

    const userMessage = await storage.createMessage({
      sessionId,
      role: "user",
      content,
    });

    const connections = await storage.getConnectionsByUser(userId);
    const activeConnection = connections.find((c) => c.status === "ACTIVE");

    const plan = await planner.generatePlan(content, {
      userId,
      tenantId: DEMO_TENANT_ID,
      connectionId: activeConnection?.id,
      provider: activeConnection?.provider,
    });

    let assistantContent: string;
    let planId: string | undefined;

    if (plan) {
      const savedPlan = await storage.createPlan({
        sessionId,
        connectionId: activeConnection?.id,
        title: plan.title,
        description: plan.description,
        steps: plan.steps,
        riskLevel: plan.riskLevel,
        executionMode: plan.executionMode,
        rollbackability: plan.rollbackability,
        requiredPermissions: plan.requiredPermissions,
        affectedResources: plan.affectedResources,
        status: "draft",
      });

      planId = savedPlan.id;
      assistantContent = `I've created a plan: **${plan.title}**\n\n${plan.description}\n\nThis plan has ${plan.steps.length} steps and is rated as **${plan.riskLevel}** risk. ${plan.confirmRequired ? "Your approval is required to proceed." : "You can execute this directly."}\n\nWould you like me to run a dry-run first, or proceed with execution?`;
    } else {
      assistantContent = planner.generateHelpResponse();
    }

    const assistantMessage = await storage.createMessage({
      sessionId,
      role: "assistant",
      content: assistantContent,
      planId,
    });

    sendResponse(res, {
      userMessage,
      assistantMessage,
      plan: plan ? { ...plan, id: planId } : null,
    });
  })
);

router.get(
  "/api/plans/:id",
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const plan = await storage.getPlan(id);

    if (!plan) {
      return sendError(res, "Plan not found", 404);
    }

    sendResponse(res, plan);
  })
);

router.post(
  "/api/plans/:id/dry-run",
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    const plan = await storage.getPlan(id);
    if (!plan) {
      return sendError(res, "Plan not found", 404);
    }

    if (!plan.connectionId) {
      return sendError(res, "No connection associated with plan", 400);
    }

    const connection = await storage.getConnection(plan.connectionId);
    if (!connection) {
      return sendError(res, "Connection not found", 404);
    }

    const result = await executor.executePlan(plan, connection, true);

    sendResponse(res, {
      runId: result.runId,
      success: result.success,
      stepResults: result.stepResults,
      error: result.error,
    });
  })
);

router.post(
  "/api/plans/:id/approve",
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    const plan = await storage.getPlan(id);
    if (!plan) {
      return sendError(res, "Plan not found", 404);
    }

    if (!plan.connectionId) {
      return sendError(res, "No connection associated with plan", 400);
    }

    const connection = await storage.getConnection(plan.connectionId);
    if (!connection) {
      return sendError(res, "Connection not found", 404);
    }

    await storage.updatePlan(id, { status: "approved" });

    const result = await executor.executePlan(plan, connection, false);

    sendResponse(res, {
      runId: result.runId,
      success: result.success,
      stepResults: result.stepResults,
      snapshotId: result.snapshotId,
      error: result.error,
    });
  })
);

router.get(
  "/api/runs/:id",
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const run = await storage.getRun(id);

    if (!run) {
      return sendError(res, "Run not found", 404);
    }

    sendResponse(res, run);
  })
);

router.post(
  "/api/runs/:id/rollback",
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.headers["x-user-id"] as string || DEMO_USER_ID;

    try {
      const result = await executor.executeRollback(id, userId);
      sendResponse(res, result);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  })
);

router.get(
  "/api/audit",
  asyncHandler(async (req, res) => {
    const tenantId = req.headers["x-tenant-id"] as string || DEMO_TENANT_ID;
    const { action, limit, offset } = req.query;

    const events = await storage.getAuditEvents(tenantId, {
      action: action as string,
      limit: limit ? parseInt(limit as string) : 50,
      offset: offset ? parseInt(offset as string) : 0,
    });

    sendResponse(res, events);
  })
);

router.get("/api/providers", (_req, res) => {
  sendResponse(res, getAvailableProviders());
});

export default router;
