import { NextRequest, NextResponse } from "next/server";
import { getPool } from "@/lib/db";
import oracledb from "oracledb";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let connection: oracledb.Connection | null = null;
  try {
    const body = await request.json();
    const { coupon_code, order_amount } = body;

    const pool = await getPool();
    connection = await pool.getConnection();

    const sql = `
      BEGIN
        sp_calculate_coupon_discount(
          p_coupon_code => :coupon_code,
          p_order_amount => :order_amount,
          p_discount_amount => :discount_amount,
          p_message => :message
        );
      END;
    `;

    const result = await connection.execute(sql, {
      coupon_code: coupon_code,
      order_amount: Number(order_amount),
      discount_amount: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
      message: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 500 }
    });

    const outBinds = result.outBinds as any;

    return NextResponse.json({ 
      success: true, 
      discount_amount: outBinds.discount_amount,
      message: outBinds.message
    });
  } catch (error: any) {
    console.error("[API/coupons/test] Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
}
