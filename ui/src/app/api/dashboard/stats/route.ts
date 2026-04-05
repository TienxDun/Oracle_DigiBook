import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { DashboardStats } from "@/types/database";

export const dynamic = "force-dynamic";


export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");

  try {
    const branchCondition = branchId && branchId !== "ALL" ? `WHERE branch_id = :branchId` : "";
    const branchJoinCondition = branchId && branchId !== "ALL" ? `AND branch_id = :branchId` : "";
    const branchWhereCondition = branchId && branchId !== "ALL" ? `WHERE branch_id = :branchId` : "";
    
    const binds: any = {};
    if (branchId && branchId !== "ALL") {
      binds.branchId = branchId;
    }

    const sql = `
      WITH stats AS (
        SELECT
          (SELECT COUNT(*) FROM orders ${branchWhereCondition}) AS TOTAL_ORDERS,
          (SELECT COUNT(*) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} order_date >= SYSDATE - 30) AS O_CUR,
          (SELECT COUNT(*) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} order_date >= SYSDATE - 60 AND order_date < SYSDATE - 30) AS O_PREV,
          
          (SELECT NVL(SUM(final_amount), 0) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} status_code != 'CANCELLED') AS TOTAL_REVENUE,
          (SELECT NVL(SUM(final_amount), 0) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} status_code != 'CANCELLED' AND order_date >= SYSDATE - 30) AS R_CUR,
          (SELECT NVL(SUM(final_amount), 0) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} status_code != 'CANCELLED' AND order_date >= SYSDATE - 60 AND order_date < SYSDATE - 30) AS R_PREV,
          
          (SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory ${branchWhereCondition}) AS TOTAL_STOCK,
          (SELECT NVL(SUM(CASE WHEN txn_type IN ('IN', 'TRANSFER_IN', 'RETURN') THEN quantity ELSE -quantity END), 0) 
           FROM inventory_transactions ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} created_at >= SYSDATE - 30) AS S_NET_CUR,
          (SELECT NVL(SUM(CASE WHEN txn_type IN ('IN', 'TRANSFER_IN', 'RETURN') THEN quantity ELSE -quantity END), 0) 
           FROM inventory_transactions ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} created_at >= SYSDATE - 60 AND created_at < SYSDATE - 30) AS S_NET_PREV,

          (SELECT COUNT(*) FROM customers) AS TOTAL_CUSTOMERS,
          (SELECT COUNT(*) FROM customers WHERE created_at >= SYSDATE - 30) AS C_CUR,
          (SELECT COUNT(*) FROM customers WHERE created_at >= SYSDATE - 60 AND created_at < SYSDATE - 30) AS C_PREV,
          
          (SELECT COUNT(*) FROM orders ${branchWhereCondition} ${branchWhereCondition ? 'AND' : 'WHERE'} status_code = 'PENDING') AS PENDING_ORDERS,
          (SELECT COUNT(*) 
           FROM branch_inventory bi
           JOIN books b ON b.book_id = bi.book_id
           WHERE b.is_active = 1 
           AND bi.quantity_available <= bi.low_stock_threshold
           ${branchId && branchId !== 'ALL' ? 'AND bi.branch_id = :branchId' : ''}
          ) AS LOW_STOCK_COUNT
        FROM DUAL
      )
      SELECT 
        TOTAL_ORDERS, TOTAL_REVENUE, TOTAL_STOCK, TOTAL_CUSTOMERS, PENDING_ORDERS, LOW_STOCK_COUNT,
        ROUND(NVL((O_CUR - O_PREV) / NULLIF(O_PREV, 0) * 100, 0), 1) AS ORDERS_CHANGE,
        ROUND(NVL((R_CUR - R_PREV) / NULLIF(R_PREV, 0) * 100, 0), 1) AS REVENUE_CHANGE,
        ROUND(NVL((S_NET_CUR - S_NET_PREV) / NULLIF(ABS(S_NET_PREV), 0) * 100, 0), 1) AS STOCK_CHANGE,
        ROUND(NVL((C_CUR - C_PREV) / NULLIF(C_PREV, 0) * 100, 0), 1) AS CUSTOMERS_CHANGE
      FROM stats
    `;

    const rows = await query<DashboardStats>(sql, binds);
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
