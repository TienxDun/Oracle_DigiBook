import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");

  try {
    const branchCondition = branchId && branchId !== "ALL" ? `AND o.branch_id = :branchId` : "";
    const binds: any = {};
    if (branchId && branchId !== "ALL") {
      binds.branchId = branchId;
    }

    // Truy vấn doanh thu 7 ngày gần nhất (bao gồm cả các ngày có doanh thu = 0)
    const sql = `
      WITH date_range AS (
        SELECT TRUNC(SYSDATE) - (LEVEL - 1) AS dt
        FROM DUAL
        CONNECT BY LEVEL <= 30
      )
      SELECT 
        TO_CHAR(dr.dt, 'DD/MM') as "name",
        NVL(SUM(o.final_amount), 0) as "total"
      FROM date_range dr
      LEFT JOIN orders o ON TRUNC(o.order_date) = dr.dt ${branchCondition}
      GROUP BY dr.dt
      ORDER BY dr.dt ASC
    `;

    const result = await query<{ name: string; total: number }>(sql, binds);

    return NextResponse.json({
      success: true,
      data: result,
    });
  } catch (error: any) {
    console.error("Database Error (Revenue):", error);
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
