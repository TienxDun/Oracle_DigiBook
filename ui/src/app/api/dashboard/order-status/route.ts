import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const branchId = searchParams.get("branchId");

  try {
    const branchCondition = branchId && branchId !== "ALL" ? `WHERE o.branch_id = :branchId` : "";
    const binds: any = {};
    if (branchId && branchId !== "ALL") {
      binds.branchId = branchId;
    }

    const sql = `
      SELECT 
        status_code as "name",
        COUNT(*) as "value"
      FROM orders o
      ${branchCondition}
      GROUP BY status_code
    `;

    const result = await query<{ name: string; value: number }>(sql, binds);

    // Mapped status to Vietnamese and add colors
    const statusMap: Record<string, { label: string; color: string }> = {
      'PENDING': { label: 'Chờ xử lý', color: '#f59e0b' },
      'COMPLETED': { label: 'Hoàn thành', color: '#10b981' },
      'CANCELLED': { label: 'Đã hủy', color: '#ef4444' },
      'SHIPPING': { label: 'Đang giao', color: '#3b82f6' },
      'CONFIRMED': { label: 'Đã xác nhận', color: '#6366f1' }
    };

    const data = result.map(r => ({
      name: statusMap[r.name]?.label || r.name,
      value: Number(r.value),
      color: statusMap[r.name]?.color || '#94a3b8'
    }));

    return NextResponse.json({
      success: true,
      data: data,
    });
  } catch (error: any) {
    console.error("Database Error (Order Status):", error);
    return NextResponse.json(
      { success: false, message: error.message },
      { status: 500 }
    );
  }
}
