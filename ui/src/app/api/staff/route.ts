import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = `
      SELECT 
        s.staff_id, s.staff_code, s.job_title, s.department, s.status, s.hire_date,
        u.full_name, u.role, u.email, u.phone,
        b.branch_name, b.branch_code
      FROM staff s
      JOIN users u ON s.user_id = u.user_id
      JOIN branches b ON s.branch_id = b.branch_id
      ORDER BY s.staff_id ASC
    `;
    const result = await query(sql);
    return NextResponse.json({ success: true, data: result });
  } catch (error: any) {
    console.error("Fetch Staff Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
