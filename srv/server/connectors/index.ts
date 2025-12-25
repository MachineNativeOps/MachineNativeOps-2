import { githubConnector } from "./github";
import type {
  ActionCapability,
  CapabilityDiscoveryResult,
  ConnectorContext,
  ActionExecuteParams,
  ActionResult,
} from "../../shared/types";

export interface Connector {
  id: string;
  name: string;
  generateOAuthUrl(state: string): string;
  exchangeCodeForToken(code: string): Promise<{
    accessToken: string;
    refreshToken?: string;
    expiresAt?: Date;
  }>;
  discoverCapabilities(accessToken: string): Promise<CapabilityDiscoveryResult>;
  getActions(): ActionCapability[];
  executeAction<I, O>(
    actionId: string,
    params: ActionExecuteParams<I>
  ): Promise<ActionResult<O>>;
}

const connectorRegistry: Map<string, Connector> = new Map();

connectorRegistry.set("github", githubConnector as Connector);

export function getConnector(provider: string): Connector | undefined {
  return connectorRegistry.get(provider);
}

export function getAllConnectors(): Connector[] {
  return Array.from(connectorRegistry.values());
}

export function getAvailableProviders(): string[] {
  return Array.from(connectorRegistry.keys());
}

export function registerConnector(connector: Connector): void {
  connectorRegistry.set(connector.id, connector);
}

export { githubConnector };
