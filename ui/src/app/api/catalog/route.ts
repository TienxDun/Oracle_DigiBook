import { NextRequest, NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";
import oracledb from "oracledb";
import type { Book } from "@/types/database";

type InsertBookOutBinds = {
  book_id: number[];
};

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get("page") ?? "1");
  const limit = parseInt(searchParams.get("limit") ?? "20");
  const search = searchParams.get("search") ?? "";
  const categoryId = searchParams.get("category_id");
  const sort = searchParams.get("sort") || "newest";
  const status = searchParams.get("status"); // "1" | "0" | null (all)
  const stockStatus = searchParams.get("stock_status"); // "in_stock" | "out_of_stock" | "low_stock" | null
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = [];

    // Lọc theo trạng thái kinh doanh (is_active)
    if (status === "1") {
      conditions.push("b.is_active = 1");
    } else if (status === "0") {
      conditions.push("b.is_active = 0");
    }
    // Nếu status là null/undefined → hiện tất cả

    if (search) conditions.push("(UPPER(b.title) LIKE UPPER(:search) OR b.isbn LIKE :search)");
    if (categoryId) conditions.push("b.category_id = :category_id");

    // Lọc theo tình trạng tồn kho (qua subquery)
    if (stockStatus === "out_of_stock") {
      conditions.push("(SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory WHERE book_id = b.book_id) = 0");
    } else if (stockStatus === "in_stock") {
      conditions.push("(SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory WHERE book_id = b.book_id) > 0");
    } else if (stockStatus === "low_stock") {
      // Sách có tổng tồn kho dương nhưng dưới ngưỡng thấp nhất của bất kỳ chi nhánh nào
      conditions.push(`EXISTS (
        SELECT 1 FROM branch_inventory bi2
        WHERE bi2.book_id = b.book_id
          AND bi2.quantity_available > 0
          AND bi2.quantity_available <= bi2.low_stock_threshold
      )`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    // Build bind params
    const binds: Record<string, string | number> = { limit, offset };
    if (search) binds.search = `%${search}%`;
    if (categoryId) binds.category_id = parseInt(categoryId);

    const countBinds: Record<string, string | number> = {};
    if (search) countBinds.search = `%${search}%`;
    if (categoryId) countBinds.category_id = parseInt(categoryId);

    // Sorting logic
    let orderBy = "b.created_at DESC";
    switch (sort) {
      case "oldest": orderBy = "b.created_at ASC"; break;
      case "price_asc": orderBy = "b.price ASC"; break;
      case "price_desc": orderBy = "b.price DESC"; break;
      case "alphabetical": orderBy = "b.title ASC"; break;
    }

    const sql = `
      SELECT
        b.book_id AS BOOK_ID,
        b.isbn AS ISBN,
        b.title AS TITLE,
        DBMS_LOB.SUBSTR(b.description, 4000, 1) AS DESCRIPTION,
        b.category_id AS CATEGORY_ID,
        b.publisher_id AS PUBLISHER_ID,
        b.price AS PRICE,
        (SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory WHERE book_id = b.book_id) AS STOCK_QUANTITY,
        b.page_count AS PAGE_COUNT,
        b.publication_year AS PUBLICATION_YEAR,
        b.language AS LANGUAGE,
        b.cover_type AS COVER_TYPE,
        b.is_featured AS IS_FEATURED,
        b.is_active AS IS_ACTIVE,
        b.view_count AS VIEW_COUNT,
        b.sold_count AS SOLD_COUNT,
        b.created_at AS CREATED_AT,
        c.category_name AS CATEGORY_NAME,
        p.publisher_name AS PUBLISHER_NAME,
        (
          SELECT LISTAGG(a.author_name, ', ') WITHIN GROUP (ORDER BY ba.author_order)
          FROM book_authors ba
          JOIN authors a ON ba.author_id = a.author_id
          WHERE ba.book_id = b.book_id AND ba.role = 'AUTHOR'
        ) AS AUTHOR_NAMES,
        (
          SELECT bi.image_url FROM book_images bi
          WHERE bi.book_id = b.book_id AND bi.is_main = 1
          AND ROWNUM = 1
        ) AS COVER_URL
      FROM books b
      LEFT JOIN categories c ON b.category_id = c.category_id
      LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
      ${whereClause}
      ORDER BY ${orderBy}
      OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
    `;

    const countSql = `
      SELECT COUNT(*) AS total
      FROM books b
      ${whereClause}
    `;

    const [books, countResult] = await Promise.all([
      query<Book>(sql, binds),
      query<{ TOTAL: number }>(countSql, countBinds),
    ]);

    return NextResponse.json({
      success: true,
      data: books,
      pagination: {
        page,
        limit,
        total: countResult[0]?.TOTAL ?? 0,
        totalPages: Math.ceil((countResult[0]?.TOTAL ?? 0) / limit),
      },
    });
  } catch (error) {
    console.error("[API/catalog] Error:", error);
    return NextResponse.json(
      { success: false, error: "Không thể tải danh mục sách." },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { 
      title, isbn, price, category_id, publisher_id,
      description, page_count, publication_year, 
      language, cover_type, is_active, cover_url
    } = body;

    if (!title || !isbn || !price || !category_id) {
      return NextResponse.json({ success: false, message: "Thiếu thông tin bắt buộc (Tiêu đề, ISBN, Giá, Danh mục)" }, { status: 400 });
    }

    const result = await withTransaction(async (connection: oracledb.Connection) => {
      const seqResult = await connection.execute<{ NEXTVAL: number }>(`SELECT seq_books.NEXTVAL AS NEXTVAL FROM DUAL`);
      const newBookId = seqResult.rows?.[0]?.NEXTVAL;

      if (!newBookId) {
        throw new Error("Không thể tạo ID sách mới.");
      }

      const insertBookSql = `
        BEGIN
          sp_manage_book(
            p_action => 'ADD',
            p_book_id => :book_id,
            p_isbn => :isbn,
            p_title => :title,
            p_description => :description,
            p_category_id => :category_id,
            p_publisher_id => :publisher_id,
            p_price => :price,
            p_stock_quantity => 0,
            p_publication_year => :publication_year,
            p_page_count => :page_count,
            p_language => :language,
            p_cover_type => :cover_type,
            p_updated_by => 1
          );
        END;
      `;

      await connection.execute(insertBookSql, {
        book_id: { type: oracledb.NUMBER, dir: oracledb.BIND_INOUT, val: newBookId },
        isbn,
        title,
        description: description || null,
        category_id: Number(category_id),
        publisher_id: Number(publisher_id || 1),
        price: Number(price),
        page_count: page_count ? Number(page_count) : null,
        publication_year: publication_year ? Number(publication_year) : null,
        language: language || "vi",
        cover_type: cover_type || "Bìa mềm"
      });

      const book_id = newBookId;

      if (cover_url && String(cover_url).trim().length > 0) {
        await connection.execute(
          `
            INSERT INTO book_images (image_id, book_id, image_url, is_main, sort_order, created_at)
            VALUES (seq_book_images.NEXTVAL, :book_id, :image_url, 1, 0, SYSDATE)
          `,
          {
            book_id,
            image_url: String(cover_url).trim(),
          }
        );
      }

      return { book_id };
    });

    return NextResponse.json({ 
      success: true, 
      message: "Thêm sách thành công",
      data: result,
    });
  } catch (error: unknown) {
    console.error("Create Book Error:", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
