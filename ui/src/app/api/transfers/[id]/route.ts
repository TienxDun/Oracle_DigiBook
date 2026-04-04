import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const transferId = Number(id);

    if (!transferId) {
      return NextResponse.json(
        { success: false, message: "Transfer ID is required" },
        { status: 400 }
      );
    }

    // Get transfer header
    const transferSql = `
      SELECT 
        it.*,
        b1.branch_name as from_branch_name,
        b2.branch_name as to_branch_name,
        u.full_name as requester_name
      FROM inventory_transfers it
      JOIN branches b1 ON it.from_branch_id = b1.branch_id
      JOIN branches b2 ON it.to_branch_id = b2.branch_id
      JOIN staff s ON it.requested_by = s.staff_id
      JOIN users u ON s.user_id = u.user_id
      WHERE it.transfer_id = :transfer_id
    `;

    const transferResult = await query(transferSql, { transfer_id: transferId });

    if (transferResult.length === 0) {
      return NextResponse.json(
        { success: false, message: "Transfer not found" },
        { status: 404 }
      );
    }

    // Get transfer details
    const detailsSql = `
      SELECT 
        td.*,
        b.title as book_title,
        b.isbn
      FROM transfer_details td
      JOIN books b ON td.book_id = b.book_id
      WHERE td.transfer_id = :transfer_id
      ORDER BY td.detail_id
    `;

    const details = await query(detailsSql, { transfer_id: transferId });

    return NextResponse.json({
      success: true,
      data: {
        transfer: transferResult[0],
        items: details
      }
    });
  } catch (error: any) {
    console.error("[API/transfers/:id] Error:", error);
    return NextResponse.json(
      { success: false, message: error.message || "Failed to fetch transfer details" },
      { status: 500 }
    );
  }
}
