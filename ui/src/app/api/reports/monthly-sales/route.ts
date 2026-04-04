import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { getPool } from "@/lib/db";

export const dynamic = "force-dynamic";

type MonthlySalesRow = {
  MONTH_KEY: string;
  TOTAL_ORDERS: number;
  DELIVERED_ORDERS: number;
  CANCELLED_ORDERS: number;
  GROSS_AMOUNT: number;
  TOTAL_DISCOUNT: number;
  TOTAL_SHIPPING_FEE: number;
  FINAL_AMOUNT_SUM: number;
  DELIVERED_REVENUE: number;
};

function parseDateInput(input: string | null, fallback: Date): Date {
  if (!input) {
    return fallback;
  }

  const parsed = new Date(`${input}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) {
    return fallback;
  }

  return parsed;
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);

  const today = new Date();
  const firstDayCurrentYear = new Date(today.getFullYear(), 0, 1);

  const fromDate = parseDateInput(searchParams.get("fromDate"), firstDayCurrentYear);
  const toDate = parseDateInput(searchParams.get("toDate"), today);
  const branchIdRaw = searchParams.get("branchId");
  const branchId = branchIdRaw && branchIdRaw !== "ALL" ? Number.parseInt(branchIdRaw, 10) : null;

  let connection: oracledb.Connection | undefined;

  try {
    const pool = await getPool();
    connection = await pool.getConnection();

    const result = await connection.execute(
      `BEGIN sp_report_monthly_sales(:p_from_date, :p_to_date, :p_branch_id, :p_result); END;`,
      {
        p_from_date: fromDate,
        p_to_date: toDate,
        p_branch_id: Number.isNaN(branchId ?? Number.NaN) ? null : branchId,
        p_result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const outBinds = result.outBinds as { p_result: oracledb.ResultSet<MonthlySalesRow> };
    const resultSet = outBinds.p_result;
    const rows = await resultSet.getRows(1000);
    await resultSet.close();

    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    console.error("[API/reports/monthly-sales] Error:", error);
    return NextResponse.json(
      { success: false, message: "Không thể chạy procedure sp_report_monthly_sales." },
      { status: 500 }
    );
  } finally {
    if (connection) {
      await connection.close();
    }
  }
}
