import { NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";
import oracledb from "oracledb";

export const dynamic = "force-dynamic";

// GET: Lấy danh sách phiếu điều chuyển
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const status = searchParams.get("status");

    let sql = `
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
    `;

    const binds: any = {};
    if (status && status !== "ALL") {
      sql += " WHERE it.status = :status";
      binds.status = status;
    }

    sql += " ORDER BY it.request_date DESC";

    const result = await query(sql, binds);
    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

// POST: Tạo phiếu điều chuyển mới
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { from_branch_id, to_branch_id, notes, items } = body;

    if (!from_branch_id || !to_branch_id || !items || items.length === 0) {
      return NextResponse.json({ success: false, message: "Missing required fields" }, { status: 400 });
    }

    // Generate transfer code: TRF-YYYYMMDD-RAND
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const randStr = Math.random().toString(36).substring(2, 6).toUpperCase();
    const transfer_code = `TRF-${dateStr}-${randStr}`;

    const result = await withTransaction(async (connection) => {
      // 1. Insert into inventory_transfers
      const insertTransferSql = `
        INSERT INTO inventory_transfers (
            transfer_code, from_branch_id, to_branch_id, requested_by, notes, total_items, total_quantity
        ) VALUES (
            :transfer_code, :from_branch_id, :to_branch_id, :requested_by, :notes, :total_items, :total_quantity
        ) RETURNING transfer_id INTO :transfer_id
      `;

      const total_items = items.length;
      const total_quantity = items.reduce((sum: number, item: any) => sum + item.quantity, 0);

      const transferBinds = {
        transfer_code,
        from_branch_id,
        to_branch_id,
        requested_by: 1, // Giả định staff_id = 1 (Admin)
        notes,
        total_items,
        total_quantity,
        transfer_id: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
      };

      const transferRes = await connection.execute(insertTransferSql, transferBinds);
      const transfer_id = (transferRes.outBinds as any).transfer_id[0];

      // 2. Insert Details & Update Source Inventory
      for (const item of items) {
        // Insert Detail
        await connection.execute(`
          INSERT INTO transfer_details (transfer_id, book_id, quantity_requested)
          VALUES (:transfer_id, :book_id, :qty)
        `, { transfer_id, book_id: item.book_id, qty: item.quantity });

        // Trừ quantity_available ở chi nhánh nguồn ngay lập tức (theo yêu cầu user)
        // Lưu ý: Oracle database có check constraint (quantity_available >= quantity_reserved), 
        // nhưng ở đây ta trừ trực tiếp available. 
        // Ta nên kiểm tra đủ hàng trước khi trừ.
        
        const updateInvRes = await connection.execute(`
          UPDATE branch_inventory 
          SET quantity_available = quantity_available - :qty,
              updated_at = SYSDATE
          WHERE branch_id = :branch_id AND book_id = :book_id AND quantity_available >= :qty
        `, { qty: item.quantity, branch_id: from_branch_id, book_id: item.book_id });

        if (updateInvRes.rowsAffected === 0) {
          throw new Error(`Sách ID ${item.book_id} không đủ tồn kho tại chi nhánh nguồn.`);
        }
      }

      return { transfer_id, transfer_code };
    });

    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    console.error("Transfer Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
