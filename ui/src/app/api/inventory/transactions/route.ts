import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branch_id");
  const limit = parseInt(searchParams.get("limit") ?? "50");

  try {
    let whereClause = "";
    const binds: any = { limit };

    if (branchId && branchId !== "ALL") {
      whereClause = "WHERE t.branch_id = :branchId";
      binds.branchId = parseInt(branchId);
    }

    const sql = `
      SELECT 
        t.txn_id,
        t.txn_type,
        t.quantity,
        t.reference_type,
        t.notes,
        TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') as formatted_date,
        b.title as book_title,
        br.branch_name
      FROM inventory_transactions t
      JOIN books b ON t.book_id = b.book_id
      JOIN branches br ON t.branch_id = br.branch_id
      ${whereClause}
      ORDER BY t.created_at DESC
      FETCH NEXT :limit ROWS ONLY
    `;

    const transactions = await query(sql, binds);

    return NextResponse.json({
      success: true,
      data: transactions
    });
  } catch (error) {
    console.error("[API/inventory/transactions] Error:", error);
    return NextResponse.json(
      { success: false, error: "Không thể tải lịch sử kho." },
      { status: 500 }
    );
  }
}
