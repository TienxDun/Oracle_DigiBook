import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

type CategoryRow = {
  CATEGORY_ID: number;
  CATEGORY_NAME: string;
  PARENT_ID: number | null;
  DESCRIPTION: string | null;
  IMAGE_URL: string | null;
  DISPLAY_ORDER: number;
  IS_ACTIVE: 0 | 1;
};

type CategoryTreeNode = CategoryRow & {
  CHILDREN: CategoryTreeNode[];
};

function buildCategoryTree(rows: CategoryRow[]): CategoryTreeNode[] {
  const map = new Map<number, CategoryTreeNode>();
  const roots: CategoryTreeNode[] = [];

  for (const row of rows) {
    map.set(row.CATEGORY_ID, { ...row, CHILDREN: [] });
  }

  for (const row of rows) {
    const node = map.get(row.CATEGORY_ID);
    if (!node) continue;

    if (row.PARENT_ID && map.has(row.PARENT_ID)) {
      map.get(row.PARENT_ID)?.CHILDREN.push(node);
    } else {
      roots.push(node);
    }
  }

  return roots;
}

export async function GET() {
  try {
    const sql = `
      SELECT
        category_id AS CATEGORY_ID,
        category_name AS CATEGORY_NAME,
        parent_id AS PARENT_ID,
        description AS DESCRIPTION,
        image_url AS IMAGE_URL,
        NVL(display_order, 0) AS DISPLAY_ORDER,
        is_active AS IS_ACTIVE
      FROM categories
      ORDER BY NVL(display_order, 0), category_name
    `;

    const rows = await query<CategoryRow>(sql);
    return NextResponse.json({
      success: true,
      data: rows,
      tree: buildCategoryTree(rows),
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { category_name, parent_id, description, image_url, display_order, is_active } = body;

    if (!category_name || String(category_name).trim().length === 0) {
      return NextResponse.json(
        { success: false, message: "Tên danh mục là bắt buộc" },
        { status: 400 }
      );
    }

    const sql = `
      INSERT INTO categories (
        category_id, category_name, parent_id, description, image_url, display_order, is_active, created_at
      ) VALUES (
        seq_categories.NEXTVAL, :category_name, :parent_id, :description, :image_url, :display_order, :is_active, SYSDATE
      )
    `;

    await query(sql, {
      category_name: String(category_name).trim(),
      parent_id: parent_id ? Number(parent_id) : null,
      description: description ? String(description) : null,
      image_url: image_url ? String(image_url) : null,
      display_order: Number(display_order ?? 0),
      is_active: Number(is_active ?? 1),
    }, { autoCommit: true });

    return NextResponse.json({ success: true, message: "Tạo danh mục thành công" });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json({ success: false, message }, { status: 500 });
  }
}
