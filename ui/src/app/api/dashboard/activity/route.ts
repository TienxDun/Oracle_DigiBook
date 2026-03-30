import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = `
      SELECT 
        it.txn_id as "id",
        it.txn_type as "type",
        it.quantity as "quantity",
        it.notes as "title",
        TO_CHAR(it.created_at, 'HH24:MI') as "time",
        b.title as "book_title"
      FROM inventory_transactions it
      JOIN books b ON it.book_id = b.book_id
      ORDER BY it.created_at DESC
      FETCH FIRST 10 ROWS ONLY
    `;

    const result = await query<any>(sql);

    // Chuẩn hóa dữ liệu hiển thị dựa trên txn_type
    const data = result.map((r: any) => ({
      id: r.id,
      title: `${r.type === 'IN' ? 'Nhập kho' : r.type === 'OUT' ? 'Xuất bán' : 'Điều chuyển'} : ${r.book_title}`,
      description: r.title || `Giao dịch ${r.quantity} cuốn`,
      time: r.time,
      status: r.type === 'OUT' ? 'success' : r.type === 'IN' ? 'info' : 'warning'
    }));

    return NextResponse.json({ success: true, data });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
