import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const actionType = searchParams.get("actionType");
  const username = searchParams.get("username");
  const ipAddress = searchParams.get("ipAddress");

  try {
    const conditions: string[] = [];
    const binds: Record<string, string> = {};

    if (actionType && actionType !== "ALL") {
      conditions.push("action_type = :actionType");
      binds.actionType = actionType;
    }
    if (username) {
      conditions.push("UPPER(action_by) LIKE UPPER(:username)");
      binds.username = `%${username}%`;
    }
    if (ipAddress) {
      conditions.push("UPPER(ip_address) LIKE UPPER(:ipAddress)");
      binds.ipAddress = `%${ipAddress}%`;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";

    const sql = `
      SELECT 
        audit_id AS AUDIT_ID,
        order_id AS ORDER_ID,
        action_type AS ACTION_TYPE,
        old_status_code AS OLD_STATUS_CODE,
        new_status_code AS NEW_STATUS_CODE,
        old_final_amount AS OLD_FINAL_AMOUNT,
        new_final_amount AS NEW_FINAL_AMOUNT,
        action_by AS ACTION_BY,
        action_at AS ACTION_AT,
        module_name AS MODULE_NAME,
        ip_address AS IP_ADDRESS,
        note AS NOTE
      FROM orders_audit_log
      ${whereClause}
      ORDER BY action_at DESC
      FETCH FIRST 200 ROWS ONLY
    `;
    const rows = await query(sql, binds);

    // Get unique IPs and Usernames for Filter Dropdowns
    const filterSql = `
      SELECT DISTINCT 
        action_by AS ACTION_BY, 
        ip_address AS IP_ADDRESS 
      FROM orders_audit_log
      WHERE ip_address IS NOT NULL OR action_by IS NOT NULL
      FETCH FIRST 50 ROWS ONLY
    `;
    const filterRows = await query(filterSql);

    return NextResponse.json({ 
      success: true, 
      data: rows,
      filters: filterRows
    });
  } catch (error: any) {
    console.error("[API/audit-logs] GET Error:", error);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
