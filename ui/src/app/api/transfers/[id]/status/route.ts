import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

const VALID_STATUS = new Set(["PENDING", "APPROVED", "SHIPPING", "COMPLETED", "CANCELLED"]);
const NEXT_STATUS: Record<string, string | null> = {
  PENDING: "APPROVED",
  APPROVED: "SHIPPING",
  SHIPPING: "COMPLETED",
  COMPLETED: null,
  CANCELLED: null,
};

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { status } = await request.json();

    if (!status || !VALID_STATUS.has(status)) {
      return NextResponse.json(
        { success: false, message: "Trạng thái không hợp lệ." },
        { status: 400 }
      );
    }

    const rows = await query<{ TRANSFER_ID: number; STATUS: string }>(
      `
      SELECT transfer_id AS TRANSFER_ID, status AS STATUS
      FROM inventory_transfers
      WHERE transfer_id = :transfer_id
      `,
      { transfer_id: Number(id) }
    );

    if (rows.length === 0) {
      return NextResponse.json(
        { success: false, message: "Không tìm thấy phiếu điều chuyển." },
        { status: 404 }
      );
    }

    const currentStatus = rows[0].STATUS;
    if (NEXT_STATUS[currentStatus] !== status) {
      return NextResponse.json(
        { success: false, message: `Chuyển trạng thái không hợp lệ: ${currentStatus} -> ${status}` },
        { status: 400 }
      );
    }

    const staff = await query<{ STAFF_ID: number }>(
      `SELECT staff_id AS STAFF_ID FROM staff ORDER BY staff_id FETCH FIRST 1 ROWS ONLY`
    );
    const actor = staff[0]?.STAFF_ID ?? null;

    const dateColumnMap: Record<string, string> = {
      APPROVED: "approved_date",
      SHIPPING: "shipped_date",
      COMPLETED: "received_date",
    };

    const byColumnMap: Record<string, string> = {
      APPROVED: "approved_by",
      SHIPPING: "shipped_by",
      COMPLETED: "received_by",
    };

    const dateColumn = dateColumnMap[status];
    const byColumn = byColumnMap[status];

    let sql = `
      UPDATE inventory_transfers
      SET status = :status,
          updated_at = SYSDATE
    `;

    if (dateColumn) {
      sql += `, ${dateColumn} = SYSDATE`;
    }

    if (byColumn && actor) {
      sql += `, ${byColumn} = :actor`;
    }

    sql += ` WHERE transfer_id = :transfer_id`;

    await query(
      sql,
      {
        status,
        transfer_id: Number(id),
        actor,
      },
      { autoCommit: true }
    );

    return NextResponse.json({ success: true, message: "Cập nhật trạng thái thành công." });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
