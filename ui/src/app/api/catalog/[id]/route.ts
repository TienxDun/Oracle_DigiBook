import { NextResponse } from "next/server";
import { query } from "@/lib/db";

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
        b.*,
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
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
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
      language, cover_type, is_active 
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

    const result: any = await query(sql, binds, { autoCommit: true });

    return NextResponse.json({ 
      success: true, 
      message: "Cập nhật thành công",
      affected: result.rowsAffected 
    });
  } catch (error: any) {
    console.error("Update Book Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
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
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
