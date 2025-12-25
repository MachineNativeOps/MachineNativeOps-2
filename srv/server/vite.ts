import type { Express } from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { createServer as createViteServer, type ViteDevServer } from "vite";
import { basicRateLimit } from "./middleware/rate-limit";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function setupVite(app: Express, server: any) {
  const vite = await createViteServer({
    server: {
      middlewareMode: true,
      hmr: { server },
    },
    appType: "spa",
  });

  app.use(vite.middlewares);
  return vite;
}

export function serveStatic(app: Express) {
  const distPath = path.resolve(__dirname, "..", "dist", "public");

  if (!fs.existsSync(distPath)) {
    console.warn(`Static files directory not found: ${distPath}`);
    console.warn("Run 'npm run build' to generate static files");
    return;
  }

  const { default: express } = require("express");
  app.use(express.static(distPath));

  app.get("*", basicRateLimit, (_req, res, next) => {
    if (_req.path.startsWith("/api")) {
      return next();
    }
    const indexPath = path.join(distPath, "index.html");
    if (fs.existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      next();
    }
  });
}

export async function createViteDevMiddleware(): Promise<ViteDevServer> {
  const vite = await createViteServer({
    server: {
      middlewareMode: true,
    },
    appType: "spa",
  });
  return vite;
}
