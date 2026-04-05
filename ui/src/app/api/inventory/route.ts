import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { BranchInventory } from "@/types/database";

export const dynamic = "force-dynamic";


export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId") || searchParams.get("branch_id");
  const lowStockOnly = searchParams.get("low_stock") === "true";
  const bookId = searchParams.get("book_id");
  const categoryId = searchParams.get("categoryId");
  const publisherId = searchParams.get("publisherId");
  const stockStatus = searchParams.get("stockStatus"); // all, in, low, out

  try {
    const conditions: string[] = ["b.is_active = 1"];
    const binds: any = {};
    
    if (branchId && branchId !== "ALL") {
      conditions.push("bi.branch_id = :branchId");
      binds.branchId = Number(branchId);
    }
    if (categoryId && categoryId !== "ALL") {
      conditions.push("b.category_id = :categoryId");
      binds.categoryId = Number(categoryId);
    }
    if (publisherId && publisherId !== "ALL") {
      conditions.push("b.publisher_id = :publisherId");
      binds.publisherId = Number(publisherId);
    }
    if (lowStockOnly || stockStatus === "low") {
      conditions.push("NVL(bi.quantity_available, 0) <= NVL(bi.low_stock_threshold, 10)");
    } else if (stockStatus === "out") {
      conditions.push("NVL(bi.quantity_available, 0) = 0");
    } else if (stockStatus === "in") {
      conditions.push("NVL(bi.quantity_available, 0) > NVL(bi.low_stock_threshold, 10)");
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        bi.inventory_id AS INVENTORY_ID,
        bi.branch_id AS BRANCH_ID,
        br.branch_name AS BRANCH_NAME,
        b.book_id AS BOOK_ID,
        b.title AS BOOK_TITLE,
        b.isbn AS ISBN,
        NVL(bi.quantity_available, 0) AS QUANTITY_AVAILABLE,
        NVL(bi.low_stock_threshold, 10) AS LOW_STOCK_THRESHOLD,
        bi.last_stock_in_at AS LAST_STOCK_IN_AT
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
