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

      // If transfer was already SHIPPING or COMPLETED, reverse inventory bookings
      if (transfer.STATUS === "SHIPPING") {
        // Get transfer items
        const items = await connection.execute(
          `SELECT * FROM transfer_details WHERE transfer_id = :id`,
          { id: transferId }
        );

        const rows = items.rows as any[];
        for (const item of rows) {
          const [, , , quantityRequested] = item; // Adjust based on column order

          // Restore source branch inventory (items were removed when transfer was created)
          await connection.execute(
            `UPDATE branch_inventory 
             SET quantity_available = quantity_available + :qty, updated_at = SYSDATE 
             WHERE branch_id = :from_branch AND book_id = :book_id`,
            {
              qty: quantityRequested,
              from_branch: transfer.FROM_BRANCH_ID,
              book_id: item[2] // book_id
            }
          );

          // Remove target branch inventory if it was added
          await connection.execute(
            `UPDATE branch_inventory 
             SET quantity_available = quantity_available - :qty, updated_at = SYSDATE 
             WHERE branch_id = :to_branch AND book_id = :book_id
               AND quantity_available >= :qty`,
            {
              qty: quantityRequested,
              to_branch: transfer.TO_BRANCH_ID,
              book_id: item[2]
            }
          );

          // Log reversal transaction
          await connection.execute(
            `INSERT INTO inventory_transactions 
             (branch_id, book_id, txn_type, reference_type, quantity, notes, created_by)
             VALUES (:branch_id, :book_id, 'TRANSFER_CANCELLED', 'TRANSFER', :qty, :notes, :staff_id)`,
            {
              branch_id: transfer.FROM_BRANCH_ID,
              book_id: item[2],
              qty: quantityRequested,
              notes: `Cancelled transfer #${transferId}: ${reason || "No reason provided"}`,
              staff_id: transfer.REQUESTED_BY
            }
          );
        }
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
