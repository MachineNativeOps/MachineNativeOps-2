import {
  pgTable,
  text,
  timestamp,
  uuid,
  boolean,
  jsonb,
  integer,
  pgEnum,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const riskLevelEnum = pgEnum("risk_level", ["LOW", "MED", "HIGH"]);
export const executionModeEnum = pgEnum("execution_mode", ["AUTO", "PLAN_ONLY", "READ_ONLY"]);
export const rollbackabilityEnum = pgEnum("rollbackability", ["YES", "PARTIAL", "NO"]);
export const authLevelEnum = pgEnum("auth_level", ["READ", "WRITE_LOW", "WRITE_HIGH"]);
export const runStatusEnum = pgEnum("run_status", ["PENDING", "RUNNING", "COMPLETED", "FAILED", "ROLLED_BACK"]);
export const connectionStatusEnum = pgEnum("connection_status", ["ACTIVE", "EXPIRED", "REVOKED"]);

export const tenants = pgTable("tenants", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  tenantId: uuid("tenant_id").references(() => tenants.id).notNull(),
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  role: text("role").notNull().default("user"),
  status: text("status").notNull().default("active"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const connections = pgTable("connections", {
  id: uuid("id").primaryKey().defaultRandom(),
  tenantId: uuid("tenant_id").references(() => tenants.id).notNull(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  provider: text("provider").notNull(),
  accountId: text("account_id"),
  accountName: text("account_name"),
  authLevel: authLevelEnum("auth_level").notNull().default("READ"),
  scopes: jsonb("scopes").$type<string[]>().default([]),
  status: connectionStatusEnum("status").notNull().default("ACTIVE"),
  vaultRef: text("vault_ref"),
  accessToken: text("access_token"),
  refreshToken: text("refresh_token"),
  tokenExpiresAt: timestamp("token_expires_at"),
  lastDiscoveredAt: timestamp("last_discovered_at"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const capabilityProfiles = pgTable("capability_profiles", {
  id: uuid("id").primaryKey().defaultRandom(),
  connectionId: uuid("connection_id").references(() => connections.id).notNull(),
  actions: jsonb("actions").$type<{
    id: string;
    version: string;
    authLevel: string;
    supportedModes: string[];
    rollback: string;
    risk: string;
    limitations?: string[];
  }[]>().default([]),
  readableCapabilities: jsonb("readable_capabilities").$type<string[]>().default([]),
  writeCapabilities: jsonb("write_capabilities").$type<string[]>().default([]),
  limitations: jsonb("limitations").$type<string[]>().default([]),
  discoveredAt: timestamp("discovered_at").defaultNow().notNull(),
});

export const featureFlags = pgTable("feature_flags", {
  id: uuid("id").primaryKey().defaultRandom(),
  tenantId: uuid("tenant_id").references(() => tenants.id),
  flagKey: text("flag_key").notNull(),
  flagVersion: text("flag_version"),
  enabled: boolean("enabled").notNull().default(true),
  metadata: jsonb("metadata").$type<Record<string, unknown>>().default({}),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const chatSessions = pgTable("chat_sessions", {
  id: uuid("id").primaryKey().defaultRandom(),
  tenantId: uuid("tenant_id").references(() => tenants.id).notNull(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  title: text("title"),
  status: text("status").notNull().default("active"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const messages = pgTable("messages", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id").references(() => chatSessions.id).notNull(),
  role: text("role").notNull(),
  content: text("content").notNull(),
  traceId: text("trace_id"),
  planId: uuid("plan_id"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const plans = pgTable("plans", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id").references(() => chatSessions.id).notNull(),
  connectionId: uuid("connection_id").references(() => connections.id),
  title: text("title").notNull(),
  description: text("description"),
  steps: jsonb("steps").$type<{
    id: string;
    action: string;
    description: string;
    order: number;
    status: string;
  }[]>().default([]),
  riskLevel: riskLevelEnum("risk_level").notNull().default("LOW"),
  executionMode: executionModeEnum("execution_mode").notNull().default("AUTO"),
  rollbackability: rollbackabilityEnum("rollbackability").notNull().default("YES"),
  requiredPermissions: jsonb("required_permissions").$type<{
    scope: string;
    description: string;
    hasPermission: boolean;
  }[]>().default([]),
  policyDecision: text("policy_decision"),
  affectedResources: jsonb("affected_resources").$type<{
    platform: string;
    organization?: string;
    project?: string;
    resource: string;
  }[]>().default([]),
  baselinePackId: text("baseline_pack_id"),
  dryRunResult: jsonb("dry_run_result"),
  status: text("status").notNull().default("draft"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const runs = pgTable("runs", {
  id: uuid("id").primaryKey().defaultRandom(),
  planId: uuid("plan_id").references(() => plans.id).notNull(),
  status: runStatusEnum("status").notNull().default("PENDING"),
  riskLevel: riskLevelEnum("risk_level").notNull(),
  executionMode: executionModeEnum("execution_mode").notNull(),
  confirmToken: text("confirm_token"),
  startedAt: timestamp("started_at"),
  endedAt: timestamp("ended_at"),
  snapshotId: uuid("snapshot_id"),
  traceId: text("trace_id").notNull(),
  runMetadata: jsonb("run_metadata").$type<Record<string, unknown>>().default({}),
  error: text("error"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const snapshots = pgTable("snapshots", {
  id: uuid("id").primaryKey().defaultRandom(),
  runId: uuid("run_id").references(() => runs.id),
  connectionId: uuid("connection_id").references(() => connections.id).notNull(),
  scope: text("scope").notNull(),
  target: text("target").notNull(),
  beforeState: jsonb("before_state").$type<Record<string, unknown>>().notNull(),
  afterState: jsonb("after_state").$type<Record<string, unknown>>(),
  checksum: text("checksum").notNull(),
  storageRef: text("storage_ref"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const rollbacks = pgTable("rollbacks", {
  id: uuid("id").primaryKey().defaultRandom(),
  runId: uuid("run_id").references(() => runs.id).notNull(),
  snapshotId: uuid("snapshot_id").references(() => snapshots.id).notNull(),
  type: text("type").notNull(),
  status: text("status").notNull().default("pending"),
  triggeredBy: uuid("triggered_by").references(() => users.id),
  executedAt: timestamp("executed_at"),
  result: jsonb("result").$type<Record<string, unknown>>(),
  evidenceRef: text("evidence_ref"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const auditEvents = pgTable("audit_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  tenantId: uuid("tenant_id").references(() => tenants.id).notNull(),
  actorId: uuid("actor_id"),
  actorType: text("actor_type").notNull(),
  action: text("action").notNull(),
  target: text("target").notNull(),
  resourceScope: text("resource_scope"),
  riskLevel: riskLevelEnum("risk_level"),
  result: text("result").notNull(),
  planId: uuid("plan_id"),
  runId: uuid("run_id"),
  snapshotId: uuid("snapshot_id"),
  traceId: text("trace_id"),
  payload: jsonb("payload").$type<Record<string, unknown>>(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const tenantsRelations = relations(tenants, ({ many }) => ({
  users: many(users),
  connections: many(connections),
  chatSessions: many(chatSessions),
  featureFlags: many(featureFlags),
  auditEvents: many(auditEvents),
}));

export const usersRelations = relations(users, ({ one, many }) => ({
  tenant: one(tenants, { fields: [users.tenantId], references: [tenants.id] }),
  connections: many(connections),
  chatSessions: many(chatSessions),
}));

export const connectionsRelations = relations(connections, ({ one, many }) => ({
  tenant: one(tenants, { fields: [connections.tenantId], references: [tenants.id] }),
  user: one(users, { fields: [connections.userId], references: [users.id] }),
  capabilityProfiles: many(capabilityProfiles),
  plans: many(plans),
  snapshots: many(snapshots),
}));

export const chatSessionsRelations = relations(chatSessions, ({ one, many }) => ({
  tenant: one(tenants, { fields: [chatSessions.tenantId], references: [tenants.id] }),
  user: one(users, { fields: [chatSessions.userId], references: [users.id] }),
  messages: many(messages),
  plans: many(plans),
}));

export const plansRelations = relations(plans, ({ one, many }) => ({
  session: one(chatSessions, { fields: [plans.sessionId], references: [chatSessions.id] }),
  connection: one(connections, { fields: [plans.connectionId], references: [connections.id] }),
  runs: many(runs),
}));

export const runsRelations = relations(runs, ({ one, many }) => ({
  plan: one(plans, { fields: [runs.planId], references: [plans.id] }),
  snapshots: many(snapshots),
  rollbacks: many(rollbacks),
}));

export type Tenant = typeof tenants.$inferSelect;
export type InsertTenant = typeof tenants.$inferInsert;
export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;
export type Connection = typeof connections.$inferSelect;
export type InsertConnection = typeof connections.$inferInsert;
export type CapabilityProfile = typeof capabilityProfiles.$inferSelect;
export type InsertCapabilityProfile = typeof capabilityProfiles.$inferInsert;
export type ChatSession = typeof chatSessions.$inferSelect;
export type InsertChatSession = typeof chatSessions.$inferInsert;
export type Message = typeof messages.$inferSelect;
export type InsertMessage = typeof messages.$inferInsert;
export type Plan = typeof plans.$inferSelect;
export type InsertPlan = typeof plans.$inferInsert;
export type Run = typeof runs.$inferSelect;
export type InsertRun = typeof runs.$inferInsert;
export type Snapshot = typeof snapshots.$inferSelect;
export type InsertSnapshot = typeof snapshots.$inferInsert;
export type Rollback = typeof rollbacks.$inferSelect;
export type InsertRollback = typeof rollbacks.$inferInsert;
export type AuditEvent = typeof auditEvents.$inferSelect;
export type InsertAuditEvent = typeof auditEvents.$inferInsert;
export type FeatureFlag = typeof featureFlags.$inferSelect;
export type InsertFeatureFlag = typeof featureFlags.$inferInsert;
