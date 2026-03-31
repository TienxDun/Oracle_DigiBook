import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { Order } from "@/types/database";

export const dynamic = "force-dynamic";


export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get("page") ?? "1");
  const limit = parseInt(searchParams.get("limit") ?? "20");
  const status = searchParams.get("status");
  const search = searchParams.get("search") ?? "";
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = [];
    const binds: Record<string, string | number> = { limit, offset };
    const countBinds: Record<string, string | number> = {};

    if (status && status !== "ALL") {
      conditions.push("o.status_code = :status");
      binds.status = status;
      countBinds.status = status;
    }
    if (search) {
      conditions.push("(UPPER(o.order_code) LIKE UPPER(:search) OR UPPER(c.full_name) LIKE UPPER(:search))");
      binds.search = `%${search}%`;
      countBinds.search = `%${search}%`;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        o.order_id,
        o.order_code,
        o.customer_id,
        c.full_name AS customer_name,
        c.phone AS customer_phone,
        o.branch_id,
        b.branch_name,
        o.status_code,
        os.status_name_vi,
        os.color_code AS status_color,
        o.total_amount,
        o.discount_amount,
        o.shipping_fee,
        o.final_amount,
        o.ship_address,
        o.ship_district,
        o.ship_province,
        o.ship_phone,
        pt.payment_method,
        pt.status AS payment_status,
        o.customer_note AS note,
        o.order_date,
        o.order_date AS created_at,
        o.updated_at
      FROM orders o
      JOIN customers c ON o.customer_id = c.customer_id
      JOIN branches b ON o.branch_id = b.branch_id
      JOIN order_statuses os ON o.status_code = os.status_code
      LEFT JOIN (
        SELECT order_id, payment_method, status,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY created_at DESC) as rn
        FROM payment_transactions
      ) pt ON o.order_id = pt.order_id AND pt.rn = 1
      ${whereClause}
      ORDER BY o.order_date DESC
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
    `;

    const countSql = `
      SELECT COUNT(*) AS total
      FROM orders o
      JOIN customers c ON o.customer_id = c.customer_id
      ${whereClause}
    `;

    const [orders, countResult] = await Promise.all([
      query<Order>(sql, binds),
      query<{ TOTAL: number }>(countSql, countBinds),
    ]);

    return NextResponse.json({
      success: true,
      data: orders,
      pagination: {
        page,
        limit,
        total: countResult[0]?.TOTAL ?? 0,
        totalPages: Math.ceil((countResult[0]?.TOTAL ?? 0) / limit),
      },
    });
  } catch (error) {
    console.error("[API/orders] Error:", error);
    return NextResponse.json(
      { success: false, error: "Không thể tải danh sách đơn hàng." },
      { status: 500 }
    );
  }
}
