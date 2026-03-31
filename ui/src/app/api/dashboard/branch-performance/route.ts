import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = `
      SELECT 
        b.branch_name as "name",
        NVL(SUM(o.final_amount), 0) as "value"
      FROM branches b
      LEFT JOIN orders o ON b.branch_id = o.branch_id AND o.status_code != 'CANCELLED'
      GROUP BY b.branch_name
      ORDER BY "value" DESC
    `;

    const result = await query<any>(sql);
    
    // Tính toán progress dựa trên chi nhánh cao nhất hoặc một target tĩnh (vd: 500.000)
    const maxVal = Math.max(...result.map((r: any) => r.value), 500000);
    const data = result.map((r: any) => ({
      ...r,
      progress: Math.round((r.value / maxVal) * 100)
    }));

    return NextResponse.json({ success: true, data });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
