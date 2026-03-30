import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = "SELECT branch_id, branch_name, branch_code, branch_type FROM branches WHERE status = 'ACTIVE' ORDER BY branch_id ASC";
    const result = await query(sql);
    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
