import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { requireSession } from "@/lib/auth";
import { isAllowedProcedure } from "@/lib/contracts";
import { getConnection, normalizeOracleError } from "@/lib/oracle";

export const dynamic = "force-dynamic";

function parseDate(value: unknown): Date | null {
  if (typeof value !== "string" || !value.trim()) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

export async function POST(request: NextRequest) {
  const auth = requireSession(request);
  if (!auth.ok) return auth.response;

  let connection: oracledb.Connection | undefined;

  try {
    const body = (await request.json()) as {
      procedureName?: string;
      payload?: Record<string, unknown>;
    };
    const procedureName = (body.procedureName ?? "").toUpperCase().trim();
    const payload = body.payload ?? {};

    if (!isAllowedProcedure(procedureName)) {
      return NextResponse.json(
        { success: false, message: "Procedure khong nam trong danh sach cho phep." },
        { status: 400 }
      );
    }

    connection = await getConnection({
      oracleUser: auth.session.oracleUser,
      oraclePassword: auth.session.oraclePassword,
    });

    if (procedureName === "SP_REPORT_MONTHLY_SALES") {
      const fromDate = parseDate(payload.fromDate);
      const toDate = parseDate(payload.toDate);
      const branchId = payload.branchId == null || payload.branchId === "" ? null : Number(payload.branchId);

      const result = await connection.execute(
        `BEGIN sp_report_monthly_sales(:p_from_date, :p_to_date, :p_branch_id, :p_result); END;`,
        {
          p_from_date: fromDate,
          p_to_date: toDate,
          p_branch_id: branchId,
          p_result: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
        },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      const outBinds = result.outBinds as { p_result: oracledb.ResultSet<Record<string, unknown>> };
      const cursor = outBinds.p_result;
      try {
        const rows = await cursor.getRows(1000);
        return NextResponse.json({ success: true, procedureName, rows, rowCount: rows.length });
      } finally {
        await cursor.close();
      }
    }

    if (procedureName === "SP_CALCULATE_COUPON_DISCOUNT") {
      const orderAmount = Number(payload.orderAmount ?? 0);
      const couponCode = String(payload.couponCode ?? "");

      const result = await connection.execute(
        `BEGIN sp_calculate_coupon_discount(:p_coupon_code, :p_order_amount, :p_discount_amount, :p_message); END;`,
        {
          p_coupon_code: couponCode,
          p_order_amount: orderAmount,
          p_discount_amount: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          p_message: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 200 },
        },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      return NextResponse.json({
        success: true,
        procedureName,
        outBinds: result.outBinds,
      });
    }

    if (procedureName === "SP_PRINT_LOW_STOCK_INVENTORY") {
      const branchId = payload.branchId == null || payload.branchId === "" ? null : Number(payload.branchId);

      await connection.execute(
        `BEGIN sp_print_low_stock_inventory(:p_branch_id); END;`,
        { p_branch_id: branchId },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      const rowsResult = await connection.execute<Record<string, unknown>>(
        `
        SELECT bi.branch_id, br.branch_name, bi.book_id, b.title, bi.quantity_available, bi.low_stock_threshold
        FROM branch_inventory bi
        JOIN branches br ON br.branch_id = bi.branch_id
        JOIN books b ON b.book_id = bi.book_id
        WHERE bi.quantity_available <= bi.low_stock_threshold
          AND (:branch_id IS NULL OR bi.branch_id = :branch_id)
        ORDER BY bi.branch_id, bi.quantity_available, bi.book_id
        FETCH FIRST 100 ROWS ONLY
        `,
        { branch_id: branchId },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );

      return NextResponse.json({
        success: true,
        procedureName,
        rows: rowsResult.rows ?? [],
        rowCount: (rowsResult.rows ?? []).length,
      });
    }

    const action = String(payload.action ?? "ADD").toUpperCase();
    const sql = `
      BEGIN
        sp_manage_book(
          :p_action,
          :p_book_id,
          :p_isbn,
          :p_title,
          :p_description,
          :p_category_id,
          :p_publisher_id,
          :p_price,
          :p_stock_quantity,
          :p_publication_year,
          :p_page_count,
          :p_language,
          :p_cover_type,
          :p_updated_by
        );
      END;
    `;

    const result = await connection.execute(sql, {
      p_action: action,
      p_book_id: {
        dir: oracledb.BIND_INOUT,
        val: payload.bookId == null ? null : Number(payload.bookId),
        type: oracledb.NUMBER,
      },
      p_isbn: payload.isbn == null ? null : String(payload.isbn),
      p_title: payload.title == null ? null : String(payload.title),
      p_description: payload.description == null ? null : String(payload.description),
      p_category_id: payload.categoryId == null ? null : Number(payload.categoryId),
      p_publisher_id: payload.publisherId == null ? null : Number(payload.publisherId),
      p_price: payload.price == null ? null : Number(payload.price),
      p_stock_quantity: payload.stockQuantity == null ? null : Number(payload.stockQuantity),
      p_publication_year: payload.publicationYear == null ? null : Number(payload.publicationYear),
      p_page_count: payload.pageCount == null ? null : Number(payload.pageCount),
      p_language: payload.language == null ? null : String(payload.language),
      p_cover_type: payload.coverType == null ? null : String(payload.coverType),
      p_updated_by: payload.updatedBy == null ? null : Number(payload.updatedBy),
    });

    return NextResponse.json({
      success: true,
      procedureName,
      outBinds: result.outBinds,
      message: "Procedure sp_manage_book executed.",
    });
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      { success: false, message: detail.message, code: detail.code },
      { status: 500 }
    );
  } finally {
    if (connection) await connection.close();
  }
}
