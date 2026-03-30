import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { DashboardStats } from "@/types/database";

export const dynamic = "force-dynamic";


export async function GET() {
  try {
    const sql = `
      SELECT
        (SELECT COUNT(*) FROM orders) AS TOTAL_ORDERS,
        (SELECT NVL(SUM(final_amount), 0) FROM orders WHERE status_code != 'CANCELLED') AS TOTAL_REVENUE,
        (SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory) AS TOTAL_STOCK,
        (SELECT COUNT(*) FROM customers) AS TOTAL_CUSTOMERS,
        (SELECT COUNT(*) FROM orders WHERE status_code = 'PENDING') AS PENDING_ORDERS,
        (SELECT COUNT(*) FROM branch_inventory WHERE quantity_available <= low_stock_threshold) AS LOW_STOCK_COUNT
      FROM DUAL
    `;

    const rows = await query<DashboardStats>(sql);
    const stats = rows[0];

    return NextResponse.json({ success: true, data: stats });
  } catch (error) {
    console.error("[API/dashboard/stats] Error:", error);
    return NextResponse.json(
      { success: false, error: "Không thể tải dữ liệu thống kê." },
      { status: 500 }
    );
  }
}
