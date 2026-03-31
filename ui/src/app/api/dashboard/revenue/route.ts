import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    // Truy vấn doanh thu 7 ngày gần nhất (bao gồm cả các ngày có doanh thu = 0)
    // Sử dụng CONNECT BY để tạo dải 7 ngày
    const sql = `
      WITH date_range AS (
        SELECT TRUNC(SYSDATE) - (LEVEL - 1) AS dt
        FROM DUAL
        CONNECT BY LEVEL <= 7
      )
      SELECT 
        TO_CHAR(dr.dt, 'Dy') as "name",
        NVL(SUM(o.final_amount), 0) as "total",
        dr.dt as "sort_dt"
      FROM date_range dr
      LEFT JOIN orders o ON TRUNC(o.order_date) = dr.dt AND o.status_code != 'CANCELLED'
      GROUP BY dr.dt, TO_CHAR(dr.dt, 'Dy')
      ORDER BY dr.dt ASC
    `;

    const result = await query<{ name: string; total: number }>(sql);

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
