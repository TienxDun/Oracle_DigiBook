import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: order_id } = await params;
    
    // Lấy chi tiết các sản phẩm trong đơn hàng
    const sql = `
      SELECT 
        oi.book_id,
        b.title as "book_title",
        b.isbn as "isbn",
        oi.quantity as "quantity",
        oi.unit_price as "unit_price",
        (oi.quantity * oi.unit_price) as "total"
      FROM order_details oi
      JOIN books b ON oi.book_id = b.book_id
      WHERE oi.order_id = :order_id
    `;

    const result = await query<any>(sql, { order_id });

    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
