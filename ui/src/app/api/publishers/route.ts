import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = "SELECT publisher_id, publisher_name FROM publishers ORDER BY publisher_name ASC";
    const result = await query(sql);
    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
