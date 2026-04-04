import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

type DailyBranchSalesRow = {
  SALE_DATE: string;
  BRANCH_ID: number;
  BRANCH_NAME: string;
  TOTAL_ORDERS: number;
  CANCELLED_ORDERS: number;
  DELIVERED_ORDERS: number;
  TOTAL_UNITS_SOLD: number;
  GROSS_MERCHANDISE_VALUE: number;
  TOTAL_DISCOUNT_AMOUNT: number;
  TOTAL_SHIPPING_FEE: number;
  TOTAL_FINAL_AMOUNT: number;
};

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");
  const fromDate = searchParams.get("fromDate");
  const toDate = searchParams.get("toDate");

  try {
    const conditions: string[] = [];
    const binds: Record<string, number | Date> = {};

    if (branchId && branchId !== "ALL") {
      const parsedBranchId = Number.parseInt(branchId, 10);
      if (!Number.isNaN(parsedBranchId)) {
        conditions.push("branch_id = :branchId");
        binds.branchId = parsedBranchId;
      }
    }

    if (fromDate) {
      conditions.push("sale_date >= :fromDate");
      binds.fromDate = new Date(`${fromDate}T00:00:00`);
    }

    if (toDate) {
      conditions.push("sale_date < :toDate + 1");
      binds.toDate = new Date(`${toDate}T00:00:00`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        sale_date AS SALE_DATE,
        branch_id AS BRANCH_ID,
        branch_name AS BRANCH_NAME,
        total_orders AS TOTAL_ORDERS,
        cancelled_orders AS CANCELLED_ORDERS,
        delivered_orders AS DELIVERED_ORDERS,
        total_units_sold AS TOTAL_UNITS_SOLD,
        gross_merchandise_value AS GROSS_MERCHANDISE_VALUE,
        total_discount_amount AS TOTAL_DISCOUNT_AMOUNT,
        total_shipping_fee AS TOTAL_SHIPPING_FEE,
        total_final_amount AS TOTAL_FINAL_AMOUNT
      FROM mv_daily_branch_sales
      ${whereClause}
      ORDER BY sale_date DESC, branch_id
      FETCH FIRST 300 ROWS ONLY
    `;

    const rows = await query<DailyBranchSalesRow>(sql, binds);

    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    console.error("[API/reports/daily-branch-sales] Error:", error);
    return NextResponse.json(
      { success: false, message: "Không thể tải dữ liệu materialized view." },
      { status: 500 }
    );
  }
}
