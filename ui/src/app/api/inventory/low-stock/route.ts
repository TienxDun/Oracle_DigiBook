import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const branchId = searchParams.get("branchId");
    const severity = searchParams.get("severity") || "all"; // 'critical', 'warning', 'all'

    let sql = `
      SELECT 
        bi.inventory_id,
        bi.branch_id,
        br.branch_name,
        b.book_id,
        b.title,
        b.isbn,
        NVL(bi.quantity_available, 0) as quantity_available,
        NVL(bi.low_stock_threshold, 10) as low_stock_threshold,
        NVL(bi.reorder_point, 20) as reorder_point,
        CASE 
          WHEN NVL(bi.quantity_available, 0) = 0 THEN 'CRITICAL'
          WHEN NVL(bi.quantity_available, 0) <= NVL(bi.low_stock_threshold, 10) THEN 'WARNING'
          ELSE 'OK'
        END as severity,
        bi.last_stock_in_at
      FROM branch_inventory bi
      JOIN branches br ON bi.branch_id = br.branch_id
      JOIN books b ON bi.book_id = b.book_id
      WHERE (NVL(bi.quantity_available, 0) <= NVL(bi.reorder_point, 20))
        AND b.is_active = 1
    `;

    const binds: any = {};

    if (branchId && branchId !== "ALL") {
      sql += " AND bi.branch_id = :branchId";
      binds.branchId = Number(branchId);
    }

    if (severity !== "all") {
      sql += ` AND (CASE 
        WHEN NVL(bi.quantity_available, 0) = 0 THEN 'CRITICAL'
        WHEN NVL(bi.quantity_available, 0) <= NVL(bi.low_stock_threshold, 10) THEN 'WARNING'
        ELSE 'OK'
      END) = :severity`;
      binds.severity = severity.toUpperCase();
    }

    sql += " ORDER BY bi.quantity_available ASC, br.branch_name ASC";

    const alerts = await query(sql, binds);

    // Count by severity
    const summary = {
      critical: alerts.filter((a: any) => a.SEVERITY === "CRITICAL").length,
      warning: alerts.filter((a: any) => a.SEVERITY === "WARNING").length,
      total: alerts.length
    };

    return NextResponse.json({
      success: true,
      summary,
      data: alerts
    });
  } catch (error: any) {
    console.error("[API/inventory/low-stock] Error:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch low stock alerts" },
      { status: 500 }
    );
  }
}
