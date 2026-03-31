import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { BranchInventory } from "@/types/database";

export const dynamic = "force-dynamic";


export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branch_id");
  const lowStockOnly = searchParams.get("low_stock") === "true";

  try {
    const conditions: string[] = ["b.is_active = 1"];
    const binds: Record<string, string | number> = {};
    
    if (branchId) {
      conditions.push("bi.branch_id = :branch_id");
      binds.branch_id = parseInt(branchId);
    }
    if (lowStockOnly) {
      conditions.push("bi.quantity_available <= bi.low_stock_threshold");
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        bi.inventory_id,
        bi.branch_id,
        br.branch_name,
        bi.book_id,
        b.title AS book_title,
        b.isbn,
        bi.quantity_available,
        bi.low_stock_threshold,
        bi.last_stock_in_at
      FROM branch_inventory bi
      JOIN branches br ON bi.branch_id = br.branch_id
      JOIN books b ON bi.book_id = b.book_id
      ${whereClause}
      ORDER BY br.branch_name, b.title
    `;

    const rows = await query<BranchInventory>(sql, binds);

    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    console.error("[API/inventory] Error:", error);
    return NextResponse.json(
      { success: false, error: "Không thể tải dữ liệu tồn kho." },
      { status: 500 }
    );
  }
}
