import { query } from "@/lib/db";

export async function resolveStaffId(params: {
  staffId?: unknown;
  userId?: unknown;
}): Promise<number | null> {
  const directStaffId = Number(params.staffId);
  if (Number.isFinite(directStaffId) && directStaffId > 0) {
    return directStaffId;
  }

  const userId = Number(params.userId);
  if (!Number.isFinite(userId) || userId <= 0) {
    return null;
  }

  const rows = await query<{ STAFF_ID: number }>(
    `SELECT staff_id AS STAFF_ID FROM staff WHERE user_id = :user_id FETCH FIRST 1 ROWS ONLY`,
    { user_id: userId }
  );

  return rows[0]?.STAFF_ID ?? null;
}
