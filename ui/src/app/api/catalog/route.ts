import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";
import type { Book } from "@/types/database";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get("page") ?? "1");
  const limit = parseInt(searchParams.get("limit") ?? "20");
  const search = searchParams.get("search") ?? "";
  const categoryId = searchParams.get("category_id");
  const sort = searchParams.get("sort") || "newest";
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = ["b.is_active = 1"];

    if (search) conditions.push("(UPPER(b.title) LIKE UPPER(:search) OR b.isbn LIKE :search)");
    if (categoryId) conditions.push("b.category_id = :category_id");

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
        b.price AS PRICE,
        (SELECT NVL(SUM(quantity_available), 0) FROM branch_inventory WHERE book_id = b.book_id) AS STOCK_QUANTITY,
        b.page_count AS PAGE_COUNT,
        b.publication_year AS PUBLICATION_YEAR,
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
      language, cover_type, is_active 
    } = body;

    if (!title || !isbn || !price || !category_id) {
      return NextResponse.json({ success: false, message: "Thiếu thông tin bắt buộc (Tiêu đề, ISBN, Giá, Danh mục)" }, { status: 400 });
    }

    const sql = `
      INSERT INTO books (
        isbn, title, description, category_id, publisher_id, 
        price, page_count, publication_year, language, 
        cover_type, is_active
      )
      VALUES (
        :isbn, :title, :description, :category_id, :publisher_id, 
        :price, :page_count, :publication_year, :language, 
        :cover_type, :is_active
      )
    `;

    const binds = {
      isbn,
      title,
      description: description || null,
      category_id: Number(category_id),
      publisher_id: Number(publisher_id || 1), // Default to 1 if not provided
      price: Number(price),
      page_count: page_count ? Number(page_count) : null,
      publication_year: publication_year ? Number(publication_year) : null,
      language: language || "vi",
      cover_type: cover_type || "Bìa mềm",
      is_active: is_active ?? 1
    };

    const result: any = await query(sql, binds, { autoCommit: true });

    return NextResponse.json({ 
      success: true, 
      message: "Thêm sách thành công",
      affected: result.rowsAffected 
    });
  } catch (error: any) {
    console.error("Create Book Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
