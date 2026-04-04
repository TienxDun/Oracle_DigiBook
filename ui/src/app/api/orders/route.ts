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
  const branchId = searchParams.get("branchId");
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = [];
    const binds: any = { limit, offset };
    const countBinds: any = {};

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
    if (branchId && branchId !== "ALL") {
      conditions.push("o.branch_id = :branchId");
      binds.branchId = branchId;
      countBinds.branchId = branchId;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        o.order_id AS ORDER_ID,
        o.order_code AS ORDER_CODE,
        o.customer_id AS CUSTOMER_ID,
        c.full_name AS CUSTOMER_NAME,
        c.phone AS CUSTOMER_PHONE,
        o.branch_id AS BRANCH_ID,
        b.branch_name AS BRANCH_NAME,
        o.status_code AS STATUS_CODE,
        os.status_name_vi AS STATUS_NAME_VI,
        os.color_code AS STATUS_COLOR,
        o.total_amount AS TOTAL_AMOUNT,
        o.discount_amount AS DISCOUNT_AMOUNT,
        o.shipping_fee AS SHIPPING_FEE,
        o.final_amount AS FINAL_AMOUNT,
        o.ship_address AS SHIP_ADDRESS,
        o.ship_district AS SHIP_DISTRICT,
        o.ship_province AS SHIP_PROVINCE,
        o.ship_phone AS SHIP_PHONE,
        pt.payment_method AS PAYMENT_METHOD,
        pt.status AS PAYMENT_STATUS,
        o.customer_note AS NOTE,
        o.order_date AS ORDER_DATE,
        o.order_date AS CREATED_AT,
        o.updated_at AS UPDATED_AT
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
      SELECT COUNT(*) AS TOTAL
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
