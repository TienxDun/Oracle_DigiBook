import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { requireSession } from "@/lib/auth";
import { isAllowedView } from "@/lib/contracts";
import { getConnection, normalizeOracleError } from "@/lib/oracle";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const auth = requireSession(request);
  if (!auth.ok) return auth.response;

  let connection;
  try {
    const body = (await request.json()) as { viewName?: string; limit?: number };
    const viewName = (body.viewName ?? "").toUpperCase().trim();

    if (!isAllowedView(viewName)) {
      return NextResponse.json(
        { success: false, message: "View khong nam trong danh sach cho phep." },
        { status: 400 }
      );
    }

    const rawLimit = Number(body.limit ?? 20);
    const limit = Math.min(100, Math.max(1, Number.isNaN(rawLimit) ? 20 : rawLimit));

    connection = await getConnection({
      oracleUser: auth.session.oracleUser,
      oraclePassword: auth.session.oraclePassword,
    });

    const sql = `SELECT * FROM ${viewName} FETCH FIRST :limit ROWS ONLY`;
    const result = await connection.execute<Record<string, unknown>>(sql, { limit }, { outFormat: oracledb.OUT_FORMAT_OBJECT });

    return NextResponse.json({
      success: true,
      viewName,
      rows: result.rows ?? [],
      rowCount: (result.rows ?? []).length,
    });
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      { success: false, message: detail.message, code: detail.code },
      { status: 500 }
    );
  } finally {
    if (connection) await connection.close();
  }
}
