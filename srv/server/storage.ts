import { db } from "../db/index";
import { eq, desc, and } from "drizzle-orm";
import {
  tenants,
  users,
  connections,
  capabilityProfiles,
  chatSessions,
  messages,
  plans,
  runs,
  snapshots,
  rollbacks,
  auditEvents,
  InsertTenant,
  InsertUser,
  InsertConnection,
  InsertCapabilityProfile,
  InsertChatSession,
  InsertMessage,
  InsertPlan,
  InsertRun,
  InsertSnapshot,
  InsertRollback,
  InsertAuditEvent,
} from "../shared/schema";

const DEMO_TENANT_ID = "00000000-0000-0000-0000-000000000001";
const DEMO_USER_ID = "00000000-0000-0000-0000-000000000002";

export async function createDemoUserIfNeeded() {
  const existingUser = await db
    .select()
    .from(users)
    .where(eq(users.id, DEMO_USER_ID))
    .limit(1);

  if (existingUser.length > 0) {
    return existingUser[0];
  }

  const existingTenant = await db
    .select()
    .from(tenants)
    .where(eq(tenants.id, DEMO_TENANT_ID))
    .limit(1);

  if (existingTenant.length === 0) {
    await db.insert(tenants).values({
      id: DEMO_TENANT_ID,
      name: "Demo Organization",
    });
  }

  const [newUser] = await db
    .insert(users)
    .values({
      id: DEMO_USER_ID,
      tenantId: DEMO_TENANT_ID,
      email: "demo@chatops.local",
      name: "Demo User",
      role: "admin",
      status: "active",
    })
    .returning();

  return newUser;
}

export async function getConnectionsByUser(userId: string) {
  return db
    .select()
    .from(connections)
    .where(eq(connections.userId, userId))
    .orderBy(desc(connections.createdAt));
}

export async function createConnection(data: InsertConnection) {
  const [connection] = await db.insert(connections).values(data).returning();
  return connection;
}

export async function getConnection(connectionId: string) {
  const [connection] = await db
    .select()
    .from(connections)
    .where(eq(connections.id, connectionId))
    .limit(1);
  return connection;
}

export async function updateConnection(
  connectionId: string,
  data: Partial<InsertConnection>
) {
  const [updated] = await db
    .update(connections)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(connections.id, connectionId))
    .returning();
  return updated;
}

export async function getCapabilityProfile(connectionId: string) {
  const [profile] = await db
    .select()
    .from(capabilityProfiles)
    .where(eq(capabilityProfiles.connectionId, connectionId))
    .orderBy(desc(capabilityProfiles.discoveredAt))
    .limit(1);
  return profile;
}

export async function createCapabilityProfile(data: InsertCapabilityProfile) {
  const [profile] = await db
    .insert(capabilityProfiles)
    .values(data)
    .returning();
  return profile;
}

export async function createChatSession(data: InsertChatSession) {
  const [session] = await db.insert(chatSessions).values(data).returning();
  return session;
}

export async function getChatSessions(userId: string) {
  return db
    .select()
    .from(chatSessions)
    .where(eq(chatSessions.userId, userId))
    .orderBy(desc(chatSessions.createdAt));
}

export async function getChatSession(sessionId: string) {
  const [session] = await db
    .select()
    .from(chatSessions)
    .where(eq(chatSessions.id, sessionId))
    .limit(1);
  return session;
}

export async function getMessages(sessionId: string) {
  return db
    .select()
    .from(messages)
    .where(eq(messages.sessionId, sessionId))
    .orderBy(messages.createdAt);
}

export async function createMessage(data: InsertMessage) {
  const [message] = await db.insert(messages).values(data).returning();
  return message;
}

export async function createPlan(data: InsertPlan) {
  const [plan] = await db.insert(plans).values(data).returning();
  return plan;
}

export async function getPlan(planId: string) {
  const [plan] = await db
    .select()
    .from(plans)
    .where(eq(plans.id, planId))
    .limit(1);
  return plan;
}

export async function updatePlan(planId: string, data: Partial<InsertPlan>) {
  const [updated] = await db
    .update(plans)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(plans.id, planId))
    .returning();
  return updated;
}

export async function createRun(data: InsertRun) {
  const [run] = await db.insert(runs).values(data).returning();
  return run;
}

export async function getRun(runId: string) {
  const [run] = await db
    .select()
    .from(runs)
    .where(eq(runs.id, runId))
    .limit(1);
  return run;
}

export async function updateRun(runId: string, data: Partial<InsertRun>) {
  const [updated] = await db
    .update(runs)
    .set(data)
    .where(eq(runs.id, runId))
    .returning();
  return updated;
}

export async function createSnapshot(data: InsertSnapshot) {
  const [snapshot] = await db.insert(snapshots).values(data).returning();
  return snapshot;
}

export async function getSnapshot(snapshotId: string) {
  const [snapshot] = await db
    .select()
    .from(snapshots)
    .where(eq(snapshots.id, snapshotId))
    .limit(1);
  return snapshot;
}

export async function createRollback(data: InsertRollback) {
  const [rollback] = await db.insert(rollbacks).values(data).returning();
  return rollback;
}

export async function getRollback(rollbackId: string) {
  const [rollback] = await db
    .select()
    .from(rollbacks)
    .where(eq(rollbacks.id, rollbackId))
    .limit(1);
  return rollback;
}

export async function updateRollback(
  rollbackId: string,
  data: Partial<InsertRollback>
) {
  const [updated] = await db
    .update(rollbacks)
    .set(data)
    .where(eq(rollbacks.id, rollbackId))
    .returning();
  return updated;
}

export async function createAuditEvent(data: InsertAuditEvent) {
  const [event] = await db.insert(auditEvents).values(data).returning();
  return event;
}

export async function getAuditEvents(
  tenantId: string,
  filters?: {
    action?: string;
    actorId?: string;
    riskLevel?: string;
    limit?: number;
    offset?: number;
  }
) {
  let query = db
    .select()
    .from(auditEvents)
    .where(eq(auditEvents.tenantId, tenantId))
    .orderBy(desc(auditEvents.createdAt));

  if (filters?.limit) {
    query = query.limit(filters.limit) as typeof query;
  }
  if (filters?.offset) {
    query = query.offset(filters.offset) as typeof query;
  }

  return query;
}

export const storage = {
  createDemoUserIfNeeded,
  getConnectionsByUser,
  createConnection,
  getConnection,
  updateConnection,
  getCapabilityProfile,
  createCapabilityProfile,
  createChatSession,
  getChatSessions,
  getChatSession,
  getMessages,
  createMessage,
  createPlan,
  getPlan,
  updatePlan,
  createRun,
  getRun,
  updateRun,
  createSnapshot,
  getSnapshot,
  createRollback,
  getRollback,
  updateRollback,
  createAuditEvent,
  getAuditEvents,
};
