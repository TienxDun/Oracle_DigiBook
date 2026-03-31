import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: order_id } = await params;
    const { status_code } = await request.json();

    if (!status_code) {
      return NextResponse.json({ success: false, message: "Missing status_code" }, { status: 400 });
    }

    // Cập nhật trạng thái trong bảng orders
    const sql = `
      UPDATE orders 
      SET status_code = :status_code, 
          updated_at = SYSDATE 
      WHERE order_id = :order_id
    `;

    const result: any = await query(sql, { status_code, order_id }, { autoCommit: true });

    if (result.rowsAffected === 0) {
      return NextResponse.json({ success: false, message: "Order not found" }, { status: 404 });
    }

    // Ghi log vào bảng order_status_history (Tùy chọn)
    await query(`
      INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, reason)
      VALUES (:order_id, 'UNKNOWN', :status_code, 1, 'Updated via Admin Dashboard')
    `, { order_id, status_code }, { autoCommit: true });

    return NextResponse.json({ success: true, message: "Cập nhật trạng thái thành công" });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
