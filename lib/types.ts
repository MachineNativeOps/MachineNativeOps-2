export type RiskLevel = "LOW" | "MED" | "HIGH";
export type ExecutionMode = "AUTO" | "PLAN_ONLY" | "READ_ONLY";
export type Rollbackability = "YES" | "PARTIAL" | "NO";
export type AuthLevel = "READ" | "WRITE_LOW" | "WRITE_HIGH";
export type RunStatus = "PENDING" | "RUNNING" | "COMPLETED" | "FAILED" | "ROLLED_BACK";
export type ConnectionStatus = "ACTIVE" | "EXPIRED" | "REVOKED";

export interface ActionCapability {
  id: string;
  version: string;
  authLevel: AuthLevel;
  supportedModes: ExecutionMode[];
  rollback: Rollbackability;
  risk: RiskLevel;
  policyConstraints?: string[];
  limitations?: string[];
}

export interface CapabilityDiscoveryResult {
  actions: ActionCapability[];
  readableScopes: string[];
  writableScopes: string[];
  missingScopes: string[];
  metadata: Record<string, unknown>;
}

export interface ConnectorContext {
  connectionId: string;
  authLevel: AuthLevel;
  accessToken: string;
  traceId: string;
}

export interface ActionExecuteParams<Input> {
  context: ConnectorContext;
  input: Input;
  dryRun?: boolean;
}

export interface ActionResult<Output> {
  output: Output;
  evidence: Record<string, unknown>;
  snapshot?: Record<string, unknown>;
  rollbackPlan?: Record<string, unknown>;
  executionMode: ExecutionMode;
  degradeReason?: string;
}

export interface PlanStep {
  id: string;
  action: string;
  description: string;
  order: number;
  status: "pending" | "running" | "completed" | "failed" | "skipped";
}

export interface RequiredPermission {
  scope: string;
  description: string;
  hasPermission: boolean;
}

export interface AffectedResource {
  platform: string;
  organization?: string;
  project?: string;
  resource: string;
}

export interface PlanCardData {
  id: string;
  title: string;
  description?: string;
  steps: PlanStep[];
  riskLevel: RiskLevel;
  executionMode: ExecutionMode;
  rollbackability: Rollbackability;
  requiredPermissions: RequiredPermission[];
  affectedResources: AffectedResource[];
  status: string;
  canApprove: boolean;
  canDryRun: boolean;
  canRollback: boolean;
  confirmRequired: boolean;
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  planCard?: PlanCardData;
  createdAt: string;
}

export interface BaselinePack {
  id: string;
  name: string;
  version: string;
  provider: string;
  description: string;
  requiredAuthLevel: AuthLevel;
  riskLevel: RiskLevel;
  rollbackability: Rollbackability;
  checks: BaselineCheck[];
  changes: BaselineChange[];
  verification: BaselineVerification[];
}

export interface BaselineCheck {
  id: string;
  name: string;
  description: string;
  action: string;
  expectedResult: Record<string, unknown>;
}

export interface BaselineChange {
  id: string;
  name: string;
  description: string;
  action: string;
  params: Record<string, unknown>;
  rollbackAction?: string;
}

export interface BaselineVerification {
  id: string;
  name: string;
  description: string;
  action: string;
  expectedResult: Record<string, unknown>;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  traceId?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
