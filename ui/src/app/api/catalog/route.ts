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
  const offset = (page - 1) * limit;

  try {
    const conditions: string[] = ["b.is_active = 1"];

    if (search) conditions.push("(UPPER(b.title) LIKE UPPER(:search) OR b.isbn LIKE :search)");
    if (categoryId) conditions.push("b.category_id = :category_id");

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    // Build bind params, only include what's needed
    const binds: Record<string, string | number> = { limit, offset };
    if (search) binds.search = `%${search}%`;
    if (categoryId) binds.category_id = parseInt(categoryId);

    // Separate bind params for count query (no limit/offset)
    const countBinds: Record<string, string | number> = {};
    if (search) countBinds.search = `%${search}%`;
    if (categoryId) countBinds.category_id = parseInt(categoryId);

    const sql = `
      SELECT
        b.book_id,
        b.isbn,
        b.title,
        b.price,
        b.stock_quantity,
        b.page_count,
        b.publication_year,
        b.is_featured,
        b.is_active,
        b.view_count,
        b.sold_count,
        b.created_at,
        c.category_name,
        p.publisher_name,
        (
          SELECT LISTAGG(a.author_name, ', ') WITHIN GROUP (ORDER BY ba.author_order)
          FROM book_authors ba
          JOIN authors a ON ba.author_id = a.author_id
          WHERE ba.book_id = b.book_id AND ba.role = 'AUTHOR'
        ) AS author_names,
        (
          SELECT bi.image_url FROM book_images bi
          WHERE bi.book_id = b.book_id AND bi.is_main = 1
          AND ROWNUM = 1
        ) AS cover_url
      FROM books b
      LEFT JOIN categories c ON b.category_id = c.category_id
      LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
      ${whereClause}
      ORDER BY b.created_at DESC
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
    const { title, isbn, price, category_id, is_active } = body;

    if (!title || !isbn || !price || !category_id) {
      return NextResponse.json({ success: false, message: "Thiếu thông tin bắt buộc" }, { status: 400 });
    }

    const sql = `
      INSERT INTO books (isbn, title, price, category_id, is_active, publisher_id)
      VALUES (:isbn, :title, :price, :category_id, :is_active, 1)
    `;

    const binds = {
      isbn,
      title,
      price,
      category_id,
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
