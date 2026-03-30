import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json();

    if (!username || !password) {
      return NextResponse.json(
        { success: false, message: "Vui lòng nhập đầy đủ thông tin" },
        { status: 400 }
      );
    }

    // Truy vấn thông tin user và staff (chi nhánh)
    // Thực hiện so sánh chuỗi đơn giản theo yêu cầu demo
    const sql = `
      SELECT 
        u.user_id, u.username, u.full_name, u.role, 
        s.branch_id, s.staff_id,
        b.branch_name, b.branch_code
      FROM users u
      LEFT JOIN staff s ON u.user_id = s.user_id
      LEFT JOIN branches b ON s.branch_id = b.branch_id
      WHERE u.username = :username 
        AND u.password_hash = :password
        AND u.is_active = 1
    `;

    const result = await query<any>(sql, { username, password });

    if (result.length === 0) {
      return NextResponse.json(
        { success: false, message: "Tên đăng nhập hoặc mật khẩu không chính xác" },
        { status: 401 }
      );
    }

    const user = result[0];

    // Cập nhật last_login_at
    await query("UPDATE users SET last_login_at = SYSDATE WHERE user_id = :id", { id: user.USER_ID }, { autoCommit: true });

    return NextResponse.json({
      success: true,
      message: "Đăng nhập thành công",
      user: {
        id: user.USER_ID,
        username: user.USERNAME,
        fullName: user.FULL_NAME,
        role: user.ROLE,
        staffId: user.STAFF_ID,
        branchId: user.BRANCH_ID,
        branchName: user.BRANCH_NAME,
        branchCode: user.BRANCH_CODE
      }
    });
  } catch (error: any) {
    console.error("Login Error:", error);
    return NextResponse.json(
      { success: false, message: "Lỗi hệ thống khi đăng nhập" },
      { status: 500 }
    );
  }
}
