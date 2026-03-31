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
    
    const bookId = searchParams.get("book_id");

    if (branchId && branchId !== "ALL") {
      conditions.push("bi.branch_id = :branch_id");
      binds.branch_id = Number(branchId);
    }
    if (bookId) {
      conditions.push("bi.book_id = :book_id");
      binds.book_id = Number(bookId);
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
        b.book_id,
        b.title AS book_title,
        b.isbn,
        NVL(bi.quantity_available, 0) as quantity_available,
        NVL(bi.low_stock_threshold, 10) as low_stock_threshold,
        bi.last_stock_in_at
      FROM books b
      LEFT JOIN branch_inventory bi ON b.book_id = bi.book_id
      LEFT JOIN branches br ON bi.branch_id = br.branch_id
      ${whereClause}
      ORDER BY b.title, br.branch_name
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
