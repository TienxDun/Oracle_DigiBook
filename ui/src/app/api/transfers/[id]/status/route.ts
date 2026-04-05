import { NextResponse } from "next/server";
import { withTransaction } from "@/lib/db";
import oracledb from "oracledb";

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

    const transferId = Number(id);

    const transition = await withTransaction(async (connection: oracledb.Connection) => {
      const transferRes = await connection.execute<{
        TRANSFER_ID: number;
        STATUS: string;
        FROM_BRANCH_ID: number;
        TO_BRANCH_ID: number;
      }>(
        `
        SELECT transfer_id AS TRANSFER_ID,
               status AS STATUS,
               from_branch_id AS FROM_BRANCH_ID,
               to_branch_id AS TO_BRANCH_ID
        FROM inventory_transfers
        WHERE transfer_id = :transfer_id
        FOR UPDATE
        `,
        { transfer_id: transferId },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      const transferRows = (transferRes.rows ?? []) as Array<{
        TRANSFER_ID: number;
        STATUS: string;
        FROM_BRANCH_ID: number;
        TO_BRANCH_ID: number;
      }>;

      if (transferRows.length === 0) {
        return { ok: false as const, code: 404, message: "Không tìm thấy phiếu điều chuyển." };
      }

      const transfer = transferRows[0];

      if (NEXT_STATUS[transfer.STATUS] !== status) {
        return {
          ok: false as const,
          code: 400,
          message: `Chuyển trạng thái không hợp lệ: ${transfer.STATUS} -> ${status}`,
        };
      }

      const staffRes = await connection.execute<{ STAFF_ID: number }>(
        `SELECT staff_id AS STAFF_ID FROM staff ORDER BY staff_id FETCH FIRST 1 ROWS ONLY`,
        {},
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      const staffRows = (staffRes.rows ?? []) as Array<{ STAFF_ID: number }>;
      const actor = staffRows[0]?.STAFF_ID ?? null;

      if (status === "SHIPPING") {
        await connection.execute(
          `
          UPDATE transfer_details
          SET quantity_shipped = quantity_requested,
              updated_at = SYSDATE
          WHERE transfer_id = :transfer_id
          `,
          { transfer_id: transferId }
        );
      }

      if (status === "COMPLETED") {
        const detailRes = await connection.execute<{ BOOK_ID: number; QUANTITY_REQUESTED: number }>(
          `
          SELECT book_id AS BOOK_ID,
                 quantity_requested AS QUANTITY_REQUESTED
          FROM transfer_details
          WHERE transfer_id = :transfer_id
          `,
          { transfer_id: transferId },
          { outFormat: oracledb.OUT_FORMAT_OBJECT }
        );

        const details = (detailRes.rows ?? []) as Array<{ BOOK_ID: number; QUANTITY_REQUESTED: number }>;

        for (const item of details) {
          await connection.execute(
            `
            MERGE INTO branch_inventory target
            USING (SELECT :branch_id AS branch_id, :book_id AS book_id FROM dual) src
            ON (target.branch_id = src.branch_id AND target.book_id = src.book_id)
            WHEN MATCHED THEN
              UPDATE SET quantity_available = quantity_available + :qty,
                         updated_at = SYSDATE
            WHEN NOT MATCHED THEN
              INSERT (branch_id, book_id, quantity_available, created_at)
              VALUES (src.branch_id, src.book_id, :qty, SYSDATE)
            `,
            {
              branch_id: transfer.TO_BRANCH_ID,
              book_id: item.BOOK_ID,
              qty: item.QUANTITY_REQUESTED,
            }
          );
        }

        await connection.execute(
          `
          UPDATE transfer_details
          SET quantity_received = quantity_requested,
              updated_at = SYSDATE
          WHERE transfer_id = :transfer_id
          `,
          { transfer_id: transferId }
        );
      }

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

      let updateSql = `
        UPDATE inventory_transfers
        SET status = :status,
            updated_at = SYSDATE
      `;

      if (dateColumn) {
        updateSql += `, ${dateColumn} = SYSDATE`;
      }

      if (byColumn && actor) {
        updateSql += `, ${byColumn} = :actor`;
      }

      updateSql += ` WHERE transfer_id = :transfer_id`;

      await connection.execute(updateSql, {
        status,
        actor,
        transfer_id: transferId,
      });

      return { ok: true as const };
    });

    if (!transition.ok) {
      return NextResponse.json(
        { success: false, message: transition.message },
        { status: transition.code }
      );
    }

    return NextResponse.json({ success: true, message: "Cập nhật trạng thái thành công." });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
