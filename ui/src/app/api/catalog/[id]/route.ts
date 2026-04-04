import { NextResponse } from "next/server";
import { query, withTransaction } from "@/lib/db";
import oracledb from "oracledb";

export const dynamic = "force-dynamic";

// GET: Lấy chi tiết 1 cuốn sách
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: book_id } = await params;
    const sql = `
      SELECT 
        b.book_id,
        b.isbn,
        b.title,
        DBMS_LOB.SUBSTR(b.description, 4000, 1) AS description,
        b.category_id,
        b.publisher_id,
        b.price,
        b.page_count,
        b.publication_year,
        b.language,
        b.cover_type,
        b.is_featured,
        b.is_active,
        b.view_count,
        b.sold_count,
        b.created_at,
        b.updated_at,
        (
          SELECT bi.image_url
          FROM book_images bi
          WHERE bi.book_id = b.book_id AND bi.is_main = 1
          AND ROWNUM = 1
        ) AS cover_url,
        c.category_name,
        p.publisher_name
      FROM books b
      LEFT JOIN categories c ON b.category_id = c.category_id
      LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
      WHERE b.book_id = :book_id
    `;
    const result = await query(sql, { book_id });
    
    if (result.length === 0) {
      return NextResponse.json({ success: false, message: "Book not found" }, { status: 404 });
    }

    return NextResponse.json({ success: true, data: result[0] });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}

// PUT: Cập nhật thông tin sách
export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: book_id } = await params;
    const body = await request.json();
    const { 
      title, isbn, price, category_id, publisher_id,
      description, page_count, publication_year, 
      language, cover_type, is_active, cover_url
    } = body;

    const sql = `
      UPDATE books SET
        title = :title,
        isbn = :isbn,
        price = :price,
        category_id = :category_id,
        publisher_id = :publisher_id,
        description = :description,
        page_count = :page_count,
        publication_year = :publication_year,
        language = :language,
        cover_type = :cover_type,
        is_active = :is_active,
        updated_at = SYSDATE
      WHERE book_id = :book_id
    `;

    const binds = {
      book_id,
      title,
      isbn,
      price: Number(price),
      category_id: Number(category_id),
      publisher_id: Number(publisher_id || 1),
      description: description || null,
      page_count: page_count ? Number(page_count) : null,
      publication_year: publication_year ? Number(publication_year) : null,
      language: language || "vi",
      cover_type: cover_type || "Bìa mềm",
      is_active: is_active ?? 1
    };

    const result = await withTransaction(async (connection: oracledb.Connection) => {
      await connection.execute(sql, binds);

      if (cover_url && String(cover_url).trim().length > 0) {
        const updateCoverResult = await connection.execute(
          `
            UPDATE book_images
            SET image_url = :image_url, is_main = 1, sort_order = 0
            WHERE book_id = :book_id AND is_main = 1
          `,
          {
            book_id: Number(book_id),
            image_url: String(cover_url).trim(),
          }
        );

        if ((updateCoverResult.rowsAffected ?? 0) === 0) {
          await connection.execute(
            `
              INSERT INTO book_images (image_id, book_id, image_url, is_main, sort_order, created_at)
              VALUES (seq_book_images.NEXTVAL, :book_id, :image_url, 1, 0, SYSDATE)
            `,
            {
              book_id: Number(book_id),
              image_url: String(cover_url).trim(),
            }
          );
        }
      }

      return { book_id: Number(book_id) };
    });

    return NextResponse.json({ 
      success: true, 
      message: "Cập nhật thành công",
      data: result,
    });
  } catch (error: unknown) {
    console.error("Update Book Error:", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}

// DELETE: Xóa mềm (Ngừng kinh doanh)
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: book_id } = await params;
    const sql = "UPDATE books SET is_active = 0, updated_at = SYSDATE WHERE book_id = :book_id";
    await query(sql, { book_id }, { autoCommit: true });

    return NextResponse.json({ success: true, message: "Đã ngừng kinh doanh sách này" });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
