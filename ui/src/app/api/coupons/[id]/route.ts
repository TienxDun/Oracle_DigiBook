import { NextRequest, NextResponse } from "next/server";
import { withTransaction } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { 
      coupon_code, coupon_name, description, discount_type, discount_value,
      min_order_amount, max_discount_amount, usage_limit, per_customer_limit,
      start_date, end_date, is_active
    } = body;

    await withTransaction(async (conn) => {
      const sql = `
        UPDATE coupons 
        SET 
          coupon_code = :coupon_code,
          coupon_name = :coupon_name,
          description = :description,
          discount_type = :discount_type,
          discount_value = :discount_value,
          min_order_amount = :min_order_amount,
          max_discount_amount = :max_discount_amount,
          usage_limit = :usage_limit,
          per_customer_limit = :per_customer_limit,
          start_date = :start_date,
          end_date = :end_date,
          is_active = :is_active,
          updated_at = SYSDATE
        WHERE coupon_id = :id
      `;

      await conn.execute(sql, {
        id: Number(id),
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

    return NextResponse.json({ success: true, message: "Cập nhật mã giảm giá thành công!" });
  } catch (error: any) {
    console.error("[API/coupons] PUT Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await withTransaction(async (conn) => {
      await conn.execute(`DELETE FROM coupons WHERE coupon_id = :id`, { id: Number(id) });
      return true;
    });
    return NextResponse.json({ success: true, message: "Đã xóa mã giảm giá!" });
  } catch (error: any) {
    console.error("[API/coupons] DELETE Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
