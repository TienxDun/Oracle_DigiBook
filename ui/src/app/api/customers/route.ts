import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

type CustomerSecureProfile = {
  CUSTOMER_ID: number;
  FULL_NAME: string;
  MASKED_EMAIL: string | null;
  MASKED_PHONE: string | null;
  MASKED_ADDRESS: string | null;
  PROVINCE: string | null;
  DISTRICT: string | null;
  CREATED_AT: string;
  UPDATED_AT: string | null;
  TOTAL_ORDERS: number;
  TOTAL_SPENT: number;
  CUSTOMER_SEGMENT: "STANDARD" | "LOYAL" | "VIP";
};

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = Math.max(1, Number.parseInt(searchParams.get("page") ?? "1", 10));
  const rawLimit = Number.parseInt(searchParams.get("limit") ?? "20", 10);
  const limit = Math.min(100, Math.max(1, Number.isNaN(rawLimit) ? 20 : rawLimit));
  const search = (searchParams.get("search") ?? "").trim();
  const segment = (searchParams.get("segment") ?? "ALL").toUpperCase();
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = [];
    const binds: Record<string, string | number> = { limit, offset };
    const countBinds: Record<string, string> = {};

    if (search.length > 0) {
      conditions.push("(UPPER(full_name) LIKE UPPER(:search) OR UPPER(NVL(masked_email, '')) LIKE UPPER(:search) OR UPPER(NVL(masked_phone, '')) LIKE UPPER(:search))");
      binds.search = `%${search}%`;
      countBinds.search = `%${search}%`;
    }

    if (segment !== "ALL") {
      conditions.push("customer_segment = :segment");
      binds.segment = segment;
      countBinds.segment = segment;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        customer_id AS CUSTOMER_ID,
        full_name AS FULL_NAME,
        masked_email AS MASKED_EMAIL,
        masked_phone AS MASKED_PHONE,
        masked_address AS MASKED_ADDRESS,
        province AS PROVINCE,
        district AS DISTRICT,
        created_at AS CREATED_AT,
        updated_at AS UPDATED_AT,
        total_orders AS TOTAL_ORDERS,
        total_spent AS TOTAL_SPENT,
        customer_segment AS CUSTOMER_SEGMENT
      FROM vw_customer_secure_profile
      ${whereClause}
      ORDER BY total_spent DESC, customer_id DESC
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
    `;

    const countSql = `
      SELECT COUNT(*) AS TOTAL
      FROM vw_customer_secure_profile
      ${whereClause}
    `;

    const [rows, totalRows] = await Promise.all([
      query<CustomerSecureProfile>(sql, binds),
      query<{ TOTAL: number }>(countSql, countBinds),
    ]);

    const total = totalRows[0]?.TOTAL ?? 0;

    return NextResponse.json({
      success: true,
      data: rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    });
  } catch (error) {
    console.error("[API/customers] Error:", error);
    return NextResponse.json(
      { success: false, message: "Không thể tải dữ liệu khách hàng." },
      { status: 500 }
    );
  }
}
