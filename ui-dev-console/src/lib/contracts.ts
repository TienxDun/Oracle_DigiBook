export const SESSION_COOKIE_NAME = "oracle_dev_console_session";

export const VIEW_ALLOWLIST = [
  "VW_ORDER_SALES_REPORT",
  "VW_CUSTOMER_SECURE_PROFILE",
  "MV_DAILY_BRANCH_SALES",
] as const;

export const PROCEDURE_ALLOWLIST = [
  "SP_MANAGE_BOOK",
  "SP_REPORT_MONTHLY_SALES",
  "SP_PRINT_LOW_STOCK_INVENTORY",
  "SP_CALCULATE_COUPON_DISCOUNT",
] as const;

export const TRIGGER_SCENARIOS = [
  "orders_validation_formula_error",
  "orders_audit_probe",
  "inventory_sync_probe",
] as const;

export type AllowedView = (typeof VIEW_ALLOWLIST)[number];
export type AllowedProcedure = (typeof PROCEDURE_ALLOWLIST)[number];
export type TriggerScenario = (typeof TRIGGER_SCENARIOS)[number];

export function isAllowedView(name: string): name is AllowedView {
  return VIEW_ALLOWLIST.includes(name.toUpperCase() as AllowedView);
}

export function isAllowedProcedure(name: string): name is AllowedProcedure {
  return PROCEDURE_ALLOWLIST.includes(name.toUpperCase() as AllowedProcedure);
}

export function isAllowedTriggerScenario(name: string): name is TriggerScenario {
  return TRIGGER_SCENARIOS.includes(name as TriggerScenario);
}
