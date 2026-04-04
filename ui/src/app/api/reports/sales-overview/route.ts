import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

type SalesOverviewRow = {
  ORDER_ID: number;
  ORDER_CODE: string;
  ORDER_DATE: string;
  STATUS_CODE: string;
  BRANCH_ID: number;
  BRANCH_NAME: string;
  BOOK_ID: number;
  BOOK_TITLE: string;
  CATEGORY_NAME: string | null;
  QUANTITY: number;
  UNIT_PRICE: number;
  LINE_SUBTOTAL: number;
};

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = Math.max(1, Number.parseInt(searchParams.get("page") ?? "1", 10));
  const rawLimit = Number.parseInt(searchParams.get("limit") ?? "25", 10);
  const limit = Math.min(100, Math.max(1, Number.isNaN(rawLimit) ? 25 : rawLimit));
  const offset = (page - 1) * limit;
  const branchId = searchParams.get("branchId");

  try {
    const conditions: string[] = [];
    const binds: Record<string, number> = { limit, offset };
    const countBinds: Record<string, number> = {};

    if (branchId && branchId !== "ALL") {
      const parsedBranchId = Number.parseInt(branchId, 10);
      if (!Number.isNaN(parsedBranchId)) {
        conditions.push("branch_id = :branchId");
        binds.branchId = parsedBranchId;
        countBinds.branchId = parsedBranchId;
      }
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT
        order_id AS ORDER_ID,
        order_code AS ORDER_CODE,
        order_date AS ORDER_DATE,
        status_code AS STATUS_CODE,
        branch_id AS BRANCH_ID,
        branch_name AS BRANCH_NAME,
        book_id AS BOOK_ID,
        book_title AS BOOK_TITLE,
        category_name AS CATEGORY_NAME,
        quantity AS QUANTITY,
        unit_price AS UNIT_PRICE,
        line_subtotal AS LINE_SUBTOTAL
      FROM vw_order_sales_report
      ${whereClause}
      ORDER BY order_date DESC, order_id DESC
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
    `;

    const totalSql = `
      SELECT COUNT(*) AS TOTAL
      FROM vw_order_sales_report
      ${whereClause}
    `;

    const [rows, totalRows] = await Promise.all([
      query<SalesOverviewRow>(sql, binds),
      query<{ TOTAL: number }>(totalSql, countBinds),
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
    console.error("[API/reports/sales-overview] Error:", error);
    return NextResponse.json(
      { success: false, message: "Không thể tải dữ liệu báo cáo bán hàng." },
      { status: 500 }
    );
  }
}
