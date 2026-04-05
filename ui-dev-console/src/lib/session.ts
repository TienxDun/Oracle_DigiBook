import crypto from "crypto";
import { SESSION_COOKIE_NAME } from "@/lib/contracts";

export type OracleSession = {
  token: string;
  oracleUser: string;
  oraclePassword: string;
  createdAt: number;
  expiresAt: number;
};

// Use global scope to persist across hot module reloads in development
// This ensures sessions aren't lost during Next.js HMR
declare global {
  var sessionStoreGlobal: Map<string, OracleSession> | undefined;
}

function getSessionStore(): Map<string, OracleSession> {
  if (!globalThis.sessionStoreGlobal) {
    globalThis.sessionStoreGlobal = new Map<string, OracleSession>();
  }
  return globalThis.sessionStoreGlobal;
}

function sessionTtlMs(): number {
  const value = Number.parseInt(process.env.SESSION_TTL_MINUTES ?? "120", 10);
  const minutes = Number.isNaN(value) ? 120 : Math.max(10, value);
  return minutes * 60 * 1000;
}

export function createOracleSession(oracleUser: string, oraclePassword: string): OracleSession {
  const now = Date.now();
  const token = crypto.randomBytes(24).toString("hex");
  const session: OracleSession = {
    token,
    oracleUser,
    oraclePassword,
    createdAt: now,
    expiresAt: now + sessionTtlMs(),
  };
  getSessionStore().set(token, session);
  return session;
}

export function getOracleSession(token?: string | null): OracleSession | null {
  if (!token) return null;
  const session = getSessionStore().get(token);
  if (!session) return null;

  if (Date.now() > session.expiresAt) {
    getSessionStore().delete(token);
    return null;
  }

  return session;
}

export function deleteOracleSession(token?: string | null): void {
  if (!token) return;
  getSessionStore().delete(token);
}

export function extractTokenFromCookie(cookieHeader: string | null): string | null {
  if (!cookieHeader) return null;

  for (const segment of cookieHeader.split(";")) {
    const [rawKey, ...rawValue] = segment.trim().split("=");
    if (rawKey === SESSION_COOKIE_NAME) {
      return rawValue.join("=") || null;
    }
  }

  return null;
}
