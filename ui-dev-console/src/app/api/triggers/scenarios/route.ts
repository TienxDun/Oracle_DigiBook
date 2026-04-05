import { NextRequest, NextResponse } from "next/server";
import oracledb from "oracledb";
import { requireSession } from "@/lib/auth";
import { isAllowedTriggerScenario } from "@/lib/contracts";
import { getConnection, normalizeOracleError } from "@/lib/oracle";

export const dynamic = "force-dynamic";

async function runOrdersValidationScenario(connection: oracledb.Connection) {
  const sample = await connection.execute<{ ORDER_ID: number; TOTAL_AMOUNT: number; DISCOUNT_AMOUNT: number; SHIPPING_FEE: number }>(
    `
    SELECT order_id, total_amount, discount_amount, shipping_fee
    FROM orders
    FETCH FIRST 1 ROWS ONLY
    `,
    [],
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const row = sample.rows?.[0];
  if (!row) {
    return { success: false, message: "Khong tim thay order de test trigger validation." };
  }

  const invalidFinal = Number(row.TOTAL_AMOUNT) - Number(row.DISCOUNT_AMOUNT) + Number(row.SHIPPING_FEE) + 1;

  await connection.execute("SAVEPOINT s1");
  try {
    await connection.execute(
      `UPDATE orders SET final_amount = :invalid_final WHERE order_id = :order_id`,
      { invalid_final: invalidFinal, order_id: row.ORDER_ID }
    );

    return {
      success: false,
      message: "Scenario khong fail nhu ky vong.",
      orderId: row.ORDER_ID,
    };
  } catch (error) {
    const detail = normalizeOracleError(error);
    return {
      success: true,
      expectedError: detail,
      orderId: row.ORDER_ID,
      note: "Trigger trg_biu_orders_validation da chan du lieu sai.",
    };
  } finally {
    await connection.execute("ROLLBACK TO s1");
  }
}

async function runOrdersAuditScenario(connection: oracledb.Connection) {
  const before = await connection.execute<{ CNT: number }>(
    `SELECT COUNT(*) AS cnt FROM orders_audit_log`,
    [],
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const beforeCount = before.rows?.[0]?.CNT ?? 0;

  const sample = await connection.execute<{ ORDER_ID: number; ADMIN_NOTE: string | null }>(
    `SELECT order_id, admin_note FROM orders FETCH FIRST 1 ROWS ONLY`,
    [],
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const row = sample.rows?.[0];
  if (!row) {
    return { success: false, message: "Khong tim thay order de test audit trigger." };
  }

  await connection.execute("SAVEPOINT s2");
  await connection.execute(
    `UPDATE orders SET admin_note = :note WHERE order_id = :order_id`,
    { note: `DEV_CONSOLE_${Date.now()}`, order_id: row.ORDER_ID }
  );

  const after = await connection.execute<{ CNT: number }>(
    `SELECT COUNT(*) AS cnt FROM orders_audit_log`,
    [],
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );
  const afterCount = after.rows?.[0]?.CNT ?? beforeCount;

  await connection.execute("ROLLBACK TO s2");

  return {
    success: true,
    orderId: row.ORDER_ID,
    auditDeltaBeforeRollback: afterCount - beforeCount,
    note: "Neu delta > 0, trigger trg_aiud_orders_audit da duoc kich hoat.",
  };
}

async function runInventorySyncScenario(connection: oracledb.Connection) {
  const sample = await connection.execute<{ INVENTORY_ID: number; BOOK_ID: number; QUANTITY_AVAILABLE: number }>(
    `
    SELECT inventory_id, book_id, quantity_available
    FROM branch_inventory
    FETCH FIRST 1 ROWS ONLY
    `,
    [],
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const row = sample.rows?.[0];
  if (!row) {
    return { success: false, message: "Khong tim thay branch_inventory de test." };
  }

  const beforeBook = await connection.execute<{ STOCK_QUANTITY: number }>(
    `SELECT stock_quantity FROM books WHERE book_id = :book_id`,
    { book_id: row.BOOK_ID },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const stockBefore = beforeBook.rows?.[0]?.STOCK_QUANTITY ?? 0;

  await connection.execute("SAVEPOINT s3");

  await connection.execute(
    `UPDATE branch_inventory SET quantity_available = quantity_available + 1 WHERE inventory_id = :inventory_id`,
    { inventory_id: row.INVENTORY_ID }
  );

  const afterBook = await connection.execute<{ STOCK_QUANTITY: number }>(
    `SELECT stock_quantity FROM books WHERE book_id = :book_id`,
    { book_id: row.BOOK_ID },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  const stockAfter = afterBook.rows?.[0]?.STOCK_QUANTITY ?? stockBefore;

  await connection.execute("ROLLBACK TO s3");

  return {
    success: true,
    bookId: row.BOOK_ID,
    stockBefore,
    stockAfterBeforeRollback: stockAfter,
    detectedDelta: stockAfter - stockBefore,
    note: "Neu delta khac 0, trigger trg_aiud_branch_inventory_sync_book_stock da dong bo stock.",
  };
}

export async function POST(request: NextRequest) {
  const auth = requireSession(request);
  if (!auth.ok) return auth.response;

  let connection: oracledb.Connection | undefined;
  try {
    const body = (await request.json()) as { scenario?: string };
    const scenario = body.scenario ?? "";

    if (!isAllowedTriggerScenario(scenario)) {
      return NextResponse.json(
        { success: false, message: "Scenario trigger khong hop le." },
        { status: 400 }
      );
    }

    connection = await getConnection({
      oracleUser: auth.session.oracleUser,
      oraclePassword: auth.session.oraclePassword,
    });

    if (scenario === "orders_validation_formula_error") {
      return NextResponse.json(await runOrdersValidationScenario(connection));
    }

    if (scenario === "orders_audit_probe") {
      return NextResponse.json(await runOrdersAuditScenario(connection));
    }

    return NextResponse.json(await runInventorySyncScenario(connection));
  } catch (error) {
    const detail = normalizeOracleError(error);
    return NextResponse.json(
      { success: false, message: detail.message, code: detail.code },
      { status: 500 }
    );
  } finally {
    if (connection) await connection.close();
  }
}
