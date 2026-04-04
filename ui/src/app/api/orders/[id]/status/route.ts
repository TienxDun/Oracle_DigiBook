import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

const ALLOWED_STATUS = new Set([
  "PENDING",
  "CONFIRMED",
  "SHIPPING",
  "DELIVERED",
  "CANCELLED",
  "RETURNED",
]);

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

    if (!ALLOWED_STATUS.has(status_code)) {
      return NextResponse.json({ success: false, message: "Invalid status_code" }, { status: 400 });
    }

    const existingOrder = await query<{ ORDER_ID: number; STATUS_CODE: string }>(
      `
      SELECT order_id AS ORDER_ID, status_code AS STATUS_CODE
      FROM orders
      WHERE order_id = :order_id
      `,
      { order_id }
    );

    if (existingOrder.length === 0) {
      return NextResponse.json({ success: false, message: "Order not found" }, { status: 404 });
    }

    const oldStatus = existingOrder[0].STATUS_CODE;

    await query(
      `
      UPDATE orders 
      SET status_code = :status_code, 
          updated_at = SYSDATE 
      WHERE order_id = :order_id
      `,
      { status_code, order_id },
      { autoCommit: true }
    );

    const actor = await query<{ STAFF_ID: number }>(
      `SELECT staff_id AS STAFF_ID FROM staff ORDER BY staff_id FETCH FIRST 1 ROWS ONLY`
    );

    if (actor.length > 0) {
      await query(
        `
        INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, reason)
        VALUES (:order_id, :old_status, :status_code, :changed_by, :reason)
        `,
        {
          order_id,
          old_status: oldStatus,
          status_code,
          changed_by: actor[0].STAFF_ID,
          reason: "Updated via Admin Dashboard",
        },
        { autoCommit: true }
      );
    }

    return NextResponse.json({ success: true, message: "Cập nhật trạng thái thành công" });
  } catch (error: unknown) {
    console.error("[API/orders/:id/status] Error:", error);
    const message = error instanceof Error ? error.message : "Internal server error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
