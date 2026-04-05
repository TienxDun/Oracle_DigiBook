import { NextRequest, NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";
import oracledb from "oracledb";

export const dynamic = "force-dynamic";

/**
 * PATCH /api/transfers/:id/cancel
 * Cancel a transfer and reverse inventory changes if it was already shipped
 */
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { reason } = await request.json();
    const transferId = Number(id);

    if (!transferId) {
      return NextResponse.json(
        { success: false, message: "Transfer ID is required" },
        { status: 400 }
      );
    }

    // Fetch transfer details
    const transferRes = await query<any>(
      `SELECT * FROM inventory_transfers WHERE transfer_id = :id`,
      { id: transferId }
    );

    if (transferRes.length === 0) {
      return NextResponse.json(
        { success: false, message: "Transfer not found" },
        { status: 404 }
      );
    }

    const transfer = transferRes[0];

    // Cannot cancel if already completed or cancelled
    if (transfer.STATUS === "COMPLETED" || transfer.STATUS === "CANCELLED") {
      return NextResponse.json(
        { success: false, message: `Cannot cancel a ${transfer.STATUS} transfer` },
        { status: 400 }
      );
    }

    // Perform cancellation in transaction
    await withTransaction(async (connection: oracledb.Connection) => {
      // Update transfer status to CANCELLED
      await connection.execute(
        `UPDATE inventory_transfers SET status = 'CANCELLED', updated_at = SYSDATE WHERE transfer_id = :id`,
        { id: transferId }
      );

      // Source inventory is reduced at transfer creation, so cancelling before COMPLETED must restore source stock.
      const items = await connection.execute<{ BOOK_ID: number; QUANTITY_REQUESTED: number }>(
        `
        SELECT book_id AS BOOK_ID,
               quantity_requested AS QUANTITY_REQUESTED
        FROM transfer_details
        WHERE transfer_id = :id
        `,
        { id: transferId },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      const rows = (items.rows ?? []) as Array<{ BOOK_ID: number; QUANTITY_REQUESTED: number }>;
      for (const item of rows) {
        await connection.execute(
          `
          UPDATE branch_inventory
          SET quantity_available = quantity_available + :qty,
              updated_at = SYSDATE
          WHERE branch_id = :from_branch AND book_id = :book_id
          `,
          {
            qty: item.QUANTITY_REQUESTED,
            from_branch: transfer.FROM_BRANCH_ID,
            book_id: item.BOOK_ID,
          }
        );

        await connection.execute(
          `
          INSERT INTO inventory_transactions
            (branch_id, book_id, txn_type, reference_id, reference_type, quantity, notes, created_by)
          VALUES
            (:branch_id, :book_id, 'ADJUST', :reference_id, 'TRANSFER', :qty, :notes, :staff_id)
          `,
          {
            branch_id: transfer.FROM_BRANCH_ID,
            book_id: item.BOOK_ID,
            reference_id: transferId,
            qty: item.QUANTITY_REQUESTED,
            notes: `Hoan kho do huy phieu #${transferId}${reason ? `: ${reason}` : ""}`,
            staff_id: transfer.REQUESTED_BY,
          }
        );
      }
    });

    return NextResponse.json({
      success: true,
      message: "Transfer cancelled successfully"
    });
  } catch (error: any) {
    console.error("[API/transfers/:id/cancel] Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Failed to cancel transfer" },
      { status: 500 }
    );
  }
}
