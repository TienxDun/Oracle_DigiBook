import { NextRequest, NextResponse } from "next/server";
import { withTransaction } from "@/lib/db";
import oracledb from "oracledb";

/**
 * API: Nhập hàng vào kho (Stock In)
 * Xử lý tăng số lượng tồn kho cho một sách tại một chi nhánh cụ thể.
 * Hỗ trợ tạo mới bản ghi tồn kho nếu sách chưa từng được gán cho chi nhánh.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { book_id, branch_id, quantity, notes, staff_id } = body;

    // 1. Validation
    if (!book_id || !branch_id || !quantity || quantity <= 0) {
      return NextResponse.json({ 
        success: false, 
        message: "Thông tin nhập hàng không hợp lệ. Vui lòng kiểm tra ID sách, Chi nhánh và Số lượng (> 0)." 
      }, { status: 400 });
    }

    if (!staff_id) {
      return NextResponse.json({ 
        success: false, 
        message: "Bạn cần có tài khoản nhân viên để thực hiện thao tác này." 
      }, { status: 401 });
    }

    // 2. Thực hiện nghiệp vụ trong một Transaction
    const result = await withTransaction(async (connection: oracledb.Connection) => {
      // A. Cập nhật hoặc Thêm mới tồn kho (MERGE/UPSERT)
      const upsertSql = `
        MERGE INTO branch_inventory target
        USING (SELECT :branch_id as branch_id, :book_id as book_id FROM dual) src
        ON (target.branch_id = src.branch_id AND target.book_id = src.book_id)
        WHEN MATCHED THEN
          UPDATE SET 
            quantity_available = quantity_available + :qty, 
            last_stock_in_at = SYSDATE,
            updated_at = SYSDATE
        WHEN NOT MATCHED THEN
          INSERT (branch_id, book_id, quantity_available, low_stock_threshold, last_stock_in_at, created_at, updated_at)
          VALUES (src.branch_id, src.book_id, :qty, 10, SYSDATE, SYSDATE, SYSDATE)
      `;
      
      await connection.execute(upsertSql, { 
        branch_id: Number(branch_id), 
        book_id: Number(book_id), 
        qty: Number(quantity) 
      });

      // B. Ghi lịch sử giao dịch kho (INVENTORY_TRANSACTIONS)
      const logSql = `
        INSERT INTO inventory_transactions (
          branch_id, 
          book_id, 
          txn_type, 
          reference_type, 
          quantity, 
          notes, 
          created_by,
          created_at
        ) VALUES (
          :branch, 
          :book, 
          'IN', 
          'ADJUSTMENT', 
          :qty, 
          :notes, 
          :staff_id, 
          SYSDATE
        )
      `;
      
      await connection.execute(logSql, { 
        branch: Number(branch_id), 
        book: Number(book_id), 
        qty: Number(quantity), 
        notes: notes || "Nhập hàng định kỳ",
        staff_id: Number(staff_id)
      });

      return { success: true };
    });

    return NextResponse.json({ 
      success: true, 
      message: `Đã nhập thành công ${quantity} cuốn sách vào kho.` 
    });

  } catch (error: any) {
    console.error("[API/inventory/stock-in] Error:", error);
    return NextResponse.json({ 
      success: false, 
      message: error.message || "Lỗi hệ thống khi xử lý nhập hàng." 
    }, { status: 500 });
  }
}
