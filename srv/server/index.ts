import "dotenv/config";
import express, { type Request, type Response, type NextFunction } from "express";
import cors from "cors";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import path from "path";
import { fileURLToPath } from "url";
import routes from "./routes";
import { setupVite, serveStatic } from "./vite";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const server = createServer(app);

app.use(cors({ origin: "*" }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

app.use(routes);

const wss = new WebSocketServer({ server, path: "/ws" });

interface WSClient {
  ws: WebSocket;
  userId?: string;
  subscriptions: Set<string>;
}

const clients: Map<WebSocket, WSClient> = new Map();

wss.on("connection", (ws) => {
  console.log("WebSocket client connected");

  const client: WSClient = {
    ws,
    subscriptions: new Set(),
  };
  clients.set(ws, client);

  ws.on("message", (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleWSMessage(client, message);
    } catch (error) {
      console.error("Invalid WebSocket message:", error);
    }
  });

  ws.on("close", () => {
    console.log("WebSocket client disconnected");
    clients.delete(ws);
  });

  ws.on("error", (error) => {
    console.error("WebSocket error:", error);
    clients.delete(ws);
  });
});

function handleWSMessage(client: WSClient, message: any) {
  switch (message.type) {
    case "auth":
      client.userId = message.userId;
      break;

    case "subscribe":
      if (message.channel) {
        client.subscriptions.add(message.channel);
      }
      break;

    case "unsubscribe":
      if (message.channel) {
        client.subscriptions.delete(message.channel);
      }
      break;

    case "ping":
      client.ws.send(JSON.stringify({ type: "pong" }));
      break;

    default:
      console.log("Unknown message type:", message.type);
  }
}

export function broadcast(channel: string, data: any) {
  const message = JSON.stringify({ channel, data, timestamp: Date.now() });

  clients.forEach((client) => {
    if (client.subscriptions.has(channel) && client.ws.readyState === WebSocket.OPEN) {
      client.ws.send(message);
    }
  });
}

export function notifyUser(userId: string, data: any) {
  const message = JSON.stringify({ type: "notification", data, timestamp: Date.now() });

  clients.forEach((client) => {
    if (client.userId === userId && client.ws.readyState === WebSocket.OPEN) {
      client.ws.send(message);
    }
  });
}

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error("Error:", err);

  res.status(500).json({
    success: false,
    error: process.env.NODE_ENV === "production" 
      ? "Internal server error" 
      : err.message,
    traceId: `trace-${Date.now()}`,
  });
});

const PORT = parseInt(process.env.PORT || "5000", 10);
const HOST = "0.0.0.0";

async function startServer() {
  const isDev = process.env.NODE_ENV !== "production";

  if (isDev) {
    try {
      await setupVite(app, server);
      console.log("Vite dev middleware enabled");
    } catch (error) {
      console.warn("Vite setup failed, serving static files:", error);
      serveStatic(app);
    }
  } else {
    serveStatic(app);
  }

  server.listen(PORT, HOST, () => {
    console.log(`Server running at http://${HOST}:${PORT}`);
    console.log(`WebSocket available at ws://${HOST}:${PORT}/ws`);
    console.log(`Environment: ${isDev ? "development" : "production"}`);
  });
}

startServer().catch((error) => {
  console.error("Failed to start server:", error);
  process.exit(1);
});
