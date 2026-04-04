import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");

  try {
    const branchCondition = branchId && branchId !== "ALL" ? `WHERE b.branch_id = :branchId` : "";
    const binds: any = {};
    if (branchId && branchId !== "ALL") {
      binds.branchId = Number(branchId);
    }

    const sql = `
      SELECT 
        b.branch_name as name,
        NVL(SUM(o.final_amount), 0) as value
      FROM branches b
      LEFT JOIN orders o ON b.branch_id = o.branch_id AND o.status_code != 'CANCELLED'
      ${branchCondition}
      GROUP BY b.branch_name
      ORDER BY value DESC
    `;

    const result = await query<any>(sql, binds);
    const total = result.reduce((acc, r) => acc + (r.VALUE || r.value || 0), 0);
    
    const data = result.map((r: any) => {
      const val = (r.VALUE || r.value || 0);
      return {
        name: r.NAME || r.name,
        value: val,
        progress: total > 0 ? Math.round((val / total) * 100) : 0
      };
    });

    return NextResponse.json({ success: true, data });
  } catch (error: any) {
    console.error("[API/dashboard/branch-performance] Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
