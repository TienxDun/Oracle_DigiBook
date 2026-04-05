import { NextRequest, NextResponse } from "next/server";
import { SESSION_COOKIE_NAME } from "@/lib/contracts";
import { testOracleLogin, normalizeOracleError } from "@/lib/oracle";
import { createOracleSession } from "@/lib/session";

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as { oracleUser?: string; oraclePassword?: string };
    const oracleUser = body.oracleUser?.trim();
    const oraclePassword = body.oraclePassword?.trim();

    if (!oracleUser || !oraclePassword) {
      return NextResponse.json(
        { success: false, message: "Vui long nhap Oracle username va password." },
        { status: 400 }
      );
    }

    const loginInfo = await testOracleLogin({ oracleUser, oraclePassword });
    const session = createOracleSession(oracleUser.toUpperCase(), oraclePassword);

    const response = NextResponse.json({
      success: true,
      message: "Dang nhap Oracle thanh cong.",
      user: {
        oracleUser: loginInfo.currentUser,
        currentSchema: loginInfo.currentSchema,
      },
    });

    response.cookies.set(SESSION_COOKIE_NAME, session.token, {
      httpOnly: true,
      sameSite: "lax",
      secure: false,
      path: "/",
      maxAge: Number.parseInt(process.env.SESSION_TTL_MINUTES ?? "120", 10) * 60,
    });

    return response;
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      { success: false, message: detail.message, code: detail.code },
      { status: 401 }
    );
  }
}
