import { NextRequest, NextResponse } from "next/server";
import { SESSION_COOKIE_NAME } from "@/lib/contracts";
import { getOracleSession } from "@/lib/session";

export function getSessionFromRequest(request: NextRequest) {
  const token = request.cookies.get(SESSION_COOKIE_NAME)?.value;
  return getOracleSession(token ?? null);
}

export function requireSession(request: NextRequest): { ok: true; session: NonNullable<ReturnType<typeof getSessionFromRequest>> } | { ok: false; response: NextResponse } {
  const session = getSessionFromRequest(request);
  if (!session) {
    return {
      ok: false,
      response: NextResponse.json(
        { success: false, message: "Session Oracle khong hop le hoac da het han." },
        { status: 401 }
      ),
    };
  }

  return { ok: true, session };
}
