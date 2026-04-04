import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { category_name, parent_id, description, image_url, display_order, is_active } = body;

    if (!category_name || String(category_name).trim().length === 0) {
      return NextResponse.json(
        { success: false, message: "Tên danh mục là bắt buộc" },
        { status: 400 }
      );
    }

    if (Number(parent_id) === Number(id)) {
      return NextResponse.json(
        { success: false, message: "Danh mục không thể là cha của chính nó" },
        { status: 400 }
      );
    }

    const sql = `
      UPDATE categories
      SET
        category_name = :category_name,
        parent_id = :parent_id,
        description = :description,
        image_url = :image_url,
        display_order = :display_order,
        is_active = :is_active,
        updated_at = SYSDATE
      WHERE category_id = :category_id
    `;

    await query(
      sql,
      {
        category_id: Number(id),
        category_name: String(category_name).trim(),
        parent_id: parent_id ? Number(parent_id) : null,
        description: description ? String(description) : null,
        image_url: image_url ? String(image_url) : null,
        display_order: Number(display_order ?? 0),
        is_active: Number(is_active ?? 1),
      },
      { autoCommit: true }
    );

    return NextResponse.json({ success: true, message: "Cập nhật danh mục thành công" });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const categoryId = Number(id);

    const childRows = await query<{ TOTAL: number }>(
      "SELECT COUNT(*) AS TOTAL FROM categories WHERE parent_id = :category_id",
      { category_id: categoryId }
    );

    if ((childRows[0]?.TOTAL ?? 0) > 0) {
      return NextResponse.json(
        { success: false, message: "Không thể xóa danh mục đang có danh mục con" },
        { status: 400 }
      );
    }

    const bookRows = await query<{ TOTAL: number }>(
      "SELECT COUNT(*) AS TOTAL FROM books WHERE category_id = :category_id",
      { category_id: categoryId }
    );

    if ((bookRows[0]?.TOTAL ?? 0) > 0) {
      return NextResponse.json(
        { success: false, message: "Không thể xóa danh mục đang có sách" },
        { status: 400 }
      );
    }

    await query(
      "DELETE FROM categories WHERE category_id = :category_id",
      { category_id: categoryId },
      { autoCommit: true }
    );

    return NextResponse.json({ success: true, message: "Đã xóa danh mục" });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
