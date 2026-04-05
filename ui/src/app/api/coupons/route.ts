import { NextRequest, NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const sql = `
      SELECT 
        coupon_id AS COUPON_ID,
        coupon_code AS COUPON_CODE,
        coupon_name AS COUPON_NAME,
        description AS DESCRIPTION,
        discount_type AS DISCOUNT_TYPE,
        discount_value AS DISCOUNT_VALUE,
        min_order_amount AS MIN_ORDER_AMOUNT,
        max_discount_amount AS MAX_DISCOUNT_AMOUNT,
        usage_limit AS USAGE_LIMIT,
        usage_count AS USAGE_COUNT,
        per_customer_limit AS PER_CUSTOMER_LIMIT,
        start_date AS START_DATE,
        end_date AS END_DATE,
        is_active AS IS_ACTIVE
      FROM coupons
      ORDER BY created_at DESC
    `;
    const rows = await query(sql);
    return NextResponse.json({ success: true, data: rows });
  } catch (error: any) {
    console.error("[API/coupons] GET Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { 
      coupon_code, coupon_name, description, discount_type, discount_value,
      min_order_amount, max_discount_amount, usage_limit, per_customer_limit,
      start_date, end_date, is_active
    } = body;

    await withTransaction(async (conn) => {
      const sql = `
        INSERT INTO coupons (
          coupon_id, coupon_code, coupon_name, description, discount_type, discount_value,
          min_order_amount, max_discount_amount, usage_limit, usage_count, per_customer_limit,
          start_date, end_date, is_active, created_at, updated_at
        )
        VALUES (
          seq_coupons.NEXTVAL, :coupon_code, :coupon_name, :description, :discount_type, :discount_value,
          :min_order_amount, :max_discount_amount, :usage_limit, 0, :per_customer_limit,
          :start_date, :end_date, :is_active, SYSDATE, SYSDATE
        )
      `;

      await conn.execute(sql, {
        coupon_code: String(coupon_code).toUpperCase(),
        coupon_name,
        description: description || null,
        discount_type,
        discount_value: Number(discount_value),
        min_order_amount: Number(min_order_amount) || 0,
        max_discount_amount: max_discount_amount ? Number(max_discount_amount) : null,
        usage_limit: usage_limit ? Number(usage_limit) : null,
        per_customer_limit: per_customer_limit ? Number(per_customer_limit) : 1,
        start_date: new Date(start_date),
        end_date: new Date(end_date),
        is_active: is_active ?? 1
      });
      return true;
    });

    return NextResponse.json({ success: true, message: "Tạo mã giảm giá thành công!" });
  } catch (error: any) {
    console.error("[API/coupons] POST Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
