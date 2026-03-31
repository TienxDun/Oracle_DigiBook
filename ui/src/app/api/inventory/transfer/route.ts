import { NextRequest, NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";
import oracledb from "oracledb";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { book_id, from_branch_id, to_branch_id, quantity, notes } = body;

    if (!book_id || !from_branch_id || !to_branch_id || !quantity) {
      return NextResponse.json({ success: false, message: "Thiếu thông tin điều chuyển." }, { status: 400 });
    }

    if (from_branch_id === to_branch_id) {
      return NextResponse.json({ success: false, message: "Chi nhánh nguồn và đích phải khác nhau." }, { status: 400 });
    }

    // 1. Check source inventory
    const checkSql = `
      SELECT quantity_available 
      FROM branch_inventory 
      WHERE branch_id = :from_branch_id AND book_id = :book_id
    `;
    const checkResult = await query<{ QUANTITY_AVAILABLE: number }>(checkSql, { from_branch_id, book_id });

    if (checkResult.length === 0 || checkResult[0].QUANTITY_AVAILABLE < quantity) {
      return NextResponse.json({ 
        success: false, 
        message: `Không đủ tồn kho tại chi nhánh nguồn (Hiện có: ${checkResult[0]?.QUANTITY_AVAILABLE || 0})` 
      }, { status: 400 });
    }

    // 2. Perform transfer in a transaction
    const transferCode = `TRF${Date.now().toString().slice(-8)}`;
    
    await withTransaction(async (connection: oracledb.Connection) => {
      // A. Create transfer record (as completed)
      const xferSql = `
        INSERT INTO inventory_transfers (
          transfer_code, from_branch_id, to_branch_id, transfer_type, status, 
          requested_by, total_items, total_quantity, notes, request_date, received_date
        ) VALUES (
          :code, :from, :to, 'TRANSFER', 'COMPLETED', 1, 1, :qty, :notes, SYSDATE, SYSDATE
        )
      `;
      await connection.execute(xferSql, { 
        code: transferCode, from: from_branch_id, to: to_branch_id, qty: quantity, notes: notes || "Điều chuyển trực tiếp"
      });

      // B. Update source inventory
      const sourceUpdateSql = `
        UPDATE branch_inventory 
        SET quantity_available = quantity_available - :qty, updated_at = SYSDATE 
        WHERE branch_id = :from AND book_id = :book
      `;
      await connection.execute(sourceUpdateSql, { qty: quantity, from: from_branch_id, book: book_id });

      // C. Update/Insert target inventory
      const targetUpsertSql = `
        MERGE INTO branch_inventory target
        USING (SELECT :to as branch_id, :book as book_id FROM dual) src
        ON (target.branch_id = src.branch_id AND target.book_id = src.book_id)
        WHEN MATCHED THEN
          UPDATE SET quantity_available = quantity_available + :qty, updated_at = SYSDATE
        WHEN NOT MATCHED THEN
          INSERT (branch_id, book_id, quantity_available, created_at)
          VALUES (src.branch_id, src.book_id, :qty, SYSDATE)
      `;
      await connection.execute(targetUpsertSql, { qty: quantity, to: to_branch_id, book: book_id });

      // D. Log transactions (Source Side - OUT)
      const logOutSql = `
        INSERT INTO inventory_transactions (
          branch_id, book_id, txn_type, reference_type, quantity, notes, created_by
        ) VALUES (
          :branch, :book, 'TRANSFER_OUT', 'TRANSFER', :qty, :notes, 1
        )
      `;
      await connection.execute(logOutSql, { branch: from_branch_id, book: book_id, qty: -quantity, notes: `📤 Chuyển đến chi nhánh ${to_branch_id}` });

      // E. Log transactions (Target Side - IN)
      const logInSql = `
        INSERT INTO inventory_transactions (
          branch_id, book_id, txn_type, reference_type, quantity, notes, created_by
        ) VALUES (
          :branch, :book, 'TRANSFER_IN', 'TRANSFER', :qty, :notes, 1
        )
      `;
      await connection.execute(logInSql, { branch: to_branch_id, book: book_id, qty: quantity, notes: `📥 Nhận từ chi nhánh ${from_branch_id}` });
    });

    return NextResponse.json({ 
      success: true, 
      message: "Điều chuyển kho thành công",
      code: transferCode
    });

  } catch (error: any) {
    console.error("Transfer Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
