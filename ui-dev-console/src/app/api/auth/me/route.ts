import { NextRequest, NextResponse } from "next/server";
import { requireSession } from "@/lib/auth";

export async function GET(request: NextRequest) {
  const auth = requireSession(request);
  if (!auth.ok) return auth.response;

  return NextResponse.json({
    success: true,
    user: {
      oracleUser: auth.session.oracleUser,
      expiresAt: auth.session.expiresAt,
    },
  });
}
