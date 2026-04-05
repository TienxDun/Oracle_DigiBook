import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { getPool } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");
  let connection: oracledb.Connection | undefined;

  try {
    const p_branch_id = branchId && branchId !== "ALL" ? Number(branchId) : null;
    const pool = await getPool();
    connection = await pool.getConnection();

    const sql = `
      BEGIN
        sp_print_low_stock_inventory(
          p_branch_id => :p_branch_id,
          p_result => :p_result
        );
      END;
    `;

    const binds = {
      p_branch_id: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: p_branch_id },
      p_result: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
    };

    const result = await connection.execute(sql, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
    const outBinds = result.outBinds as { p_result: oracledb.ResultSet<any> };
    const resultSet = outBinds.p_result;
    const rows = await resultSet.getRows(1000);
    await resultSet.close();

    return NextResponse.json({ success: true, data: rows });

  } catch (error: unknown) {
    console.error("[API/inventory/low-stock] Error:", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { success: false, error: message },
      { status: 500 }
    );
  } finally {
    if (connection) {
      await connection.close();
    }
  }
}
