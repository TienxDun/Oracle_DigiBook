"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { CalendarDays, Database, RefreshCcw, TableProperties } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { useBranch } from "@/context/branch-context";

type MonthlySalesRow = {
  MONTH_KEY: string;
  TOTAL_ORDERS: number;
  DELIVERED_ORDERS: number;
  CANCELLED_ORDERS: number;
  GROSS_AMOUNT: number;
  TOTAL_DISCOUNT: number;
  TOTAL_SHIPPING_FEE: number;
  FINAL_AMOUNT_SUM: number;
  DELIVERED_REVENUE: number;
};

type DailyBranchSalesRow = {
  SALE_DATE: string;
  BRANCH_ID: number;
  BRANCH_NAME: string;
  TOTAL_ORDERS: number;
  CANCELLED_ORDERS: number;
  DELIVERED_ORDERS: number;
  TOTAL_UNITS_SOLD: number;
  TOTAL_FINAL_AMOUNT: number;
};

type SalesOverviewRow = {
  ORDER_ID: number;
  ORDER_CODE: string;
  ORDER_DATE: string;
  STATUS_CODE: string;
  BRANCH_NAME: string;
  BOOK_TITLE: string;
  CATEGORY_NAME: string | null;
  QUANTITY: number;
  UNIT_PRICE: number;
  LINE_SUBTOTAL: number;
};

const today = new Date();
const defaultFromDate = `${today.getFullYear()}-01-01`;
const defaultToDate = today.toISOString().slice(0, 10);

export default function ReportsPage() {
  const { currentBranch } = useBranch();
  const [loading, setLoading] = useState(true);
  const [monthlyRows, setMonthlyRows] = useState<MonthlySalesRow[]>([]);
  const [dailyRows, setDailyRows] = useState<DailyBranchSalesRow[]>([]);
  const [overviewRows, setOverviewRows] = useState<SalesOverviewRow[]>([]);
  const [fromDate, setFromDate] = useState(defaultFromDate);
  const [toDate, setToDate] = useState(defaultToDate);

  const branchId = currentBranch?.id || "ALL";

  const fetchReports = useCallback(async () => {
    setLoading(true);
    try {
      const monthlyParams = new URLSearchParams({ fromDate, toDate, branchId });
      const dailyParams = new URLSearchParams({ fromDate, toDate, branchId });
      const overviewParams = new URLSearchParams({ page: "1", limit: "20", branchId });

      const [monthlyRes, dailyRes, overviewRes] = await Promise.all([
        fetch(`/api/reports/monthly-sales?${monthlyParams.toString()}`),
        fetch(`/api/reports/daily-branch-sales?${dailyParams.toString()}`),
        fetch(`/api/reports/sales-overview?${overviewParams.toString()}`),
      ]);

      const monthlyJson = await monthlyRes.json();
      const dailyJson = await dailyRes.json();
      const overviewJson = await overviewRes.json();

      if (monthlyJson.success) setMonthlyRows(monthlyJson.data ?? []);
      if (dailyJson.success) setDailyRows(dailyJson.data ?? []);
      if (overviewJson.success) setOverviewRows(overviewJson.data ?? []);
    } catch (error) {
      console.error("Failed to fetch reports:", error);
    } finally {
      setLoading(false);
    }
  }, [branchId, fromDate, toDate]);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const monthlyRevenue = useMemo(
    () => monthlyRows.reduce((sum, row) => sum + (row.DELIVERED_REVENUE || 0), 0),
    [monthlyRows]
  );

  const dailyRevenue = useMemo(
    () => dailyRows.reduce((sum, row) => sum + (row.TOTAL_FINAL_AMOUNT || 0), 0),
    [dailyRows]
  );

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Báo cáo SQL</h1>
          <p className="text-sm text-secondary-foreground">
            Kiểm thử SP và view: sp_report_monthly_sales, vw_order_sales_report, mv_daily_branch_sales.
          </p>
        </div>
        <button
          onClick={fetchReports}
          className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-semibold hover:bg-accent"
        >
          <RefreshCcw size={16} />
          Tải lại
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Doanh thu giao thành công (Procedure)</div>
          <div className="mt-2 text-2xl font-black text-foreground">{monthlyRevenue.toLocaleString("vi-VN")}đ</div>
        </div>
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Doanh thu tổng hợp (MV)</div>
          <div className="mt-2 text-2xl font-black text-foreground">{dailyRevenue.toLocaleString("vi-VN")}đ</div>
        </div>
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Dòng dữ liệu bán hàng (View)</div>
          <div className="mt-2 text-2xl font-black text-foreground">{overviewRows.length}</div>
        </div>
      </div>

      <div className="rounded-xl border border-border bg-white p-4">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-2 text-sm font-semibold text-secondary-foreground">
            <CalendarDays size={16} />
            Khoảng thời gian
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <input
              type="date"
              value={fromDate}
              onChange={(event) => setFromDate(event.target.value)}
              title="Ngày bắt đầu"
              aria-label="Ngày bắt đầu"
              className="rounded-lg border border-border px-3 py-2 text-sm"
            />
            <input
              type="date"
              value={toDate}
              onChange={(event) => setToDate(event.target.value)}
              title="Ngày kết thúc"
              aria-label="Ngày kết thúc"
              className="rounded-lg border border-border px-3 py-2 text-sm"
            />
            <button
              onClick={fetchReports}
              className="rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white hover:bg-primary-hover"
            >
              Áp dụng
            </button>
          </div>
        </div>
      </div>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-bold text-foreground">
          <Database size={18} />
          Kết quả SP: sp_report_monthly_sales
        </h2>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-accent/40 text-xs font-semibold uppercase tracking-wider text-secondary-foreground">
                <tr>
                  <th className="px-5 py-3">Tháng</th>
                  <th className="px-5 py-3 text-right">Tổng đơn</th>
                  <th className="px-5 py-3 text-right">Đã giao</th>
                  <th className="px-5 py-3 text-right">Hủy</th>
                  <th className="px-5 py-3 text-right">Doanh thu giao</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  Array(4).fill(0).map((_, index) => (
                    <tr key={index}>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-20" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-12" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-12" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-12" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-24" /></td>
                    </tr>
                  ))
                ) : monthlyRows.length > 0 ? (
                  monthlyRows.map((row) => (
                    <tr key={row.MONTH_KEY}>
                      <td className="px-5 py-4 font-semibold">{row.MONTH_KEY}</td>
                      <td className="px-5 py-4 text-right">{row.TOTAL_ORDERS}</td>
                      <td className="px-5 py-4 text-right">{row.DELIVERED_ORDERS}</td>
                      <td className="px-5 py-4 text-right">{row.CANCELLED_ORDERS}</td>
                      <td className="px-5 py-4 text-right font-semibold">{row.DELIVERED_REVENUE.toLocaleString("vi-VN")}đ</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-5 py-8 text-center text-secondary-foreground">Không có dữ liệu theo khoảng ngày đã chọn.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-bold text-foreground">
          <TableProperties size={18} />
          Kết quả MV: mv_daily_branch_sales (20 dòng gần nhất)
        </h2>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-accent/40 text-xs font-semibold uppercase tracking-wider text-secondary-foreground">
                <tr>
                  <th className="px-5 py-3">Ngày</th>
                  <th className="px-5 py-3">Chi nhánh</th>
                  <th className="px-5 py-3 text-right">Đơn hàng</th>
                  <th className="px-5 py-3 text-right">Đã giao</th>
                  <th className="px-5 py-3 text-right">Doanh thu</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {(loading ? [] : dailyRows.slice(0, 20)).map((row, index) => (
                  <tr key={`${row.BRANCH_ID}-${row.SALE_DATE}-${index}`}>
                    <td className="px-5 py-4">{new Date(row.SALE_DATE).toLocaleDateString("vi-VN")}</td>
                    <td className="px-5 py-4">{row.BRANCH_NAME}</td>
                    <td className="px-5 py-4 text-right">{row.TOTAL_ORDERS}</td>
                    <td className="px-5 py-4 text-right">{row.DELIVERED_ORDERS}</td>
                    <td className="px-5 py-4 text-right font-semibold">{row.TOTAL_FINAL_AMOUNT.toLocaleString("vi-VN")}đ</td>
                  </tr>
                ))}
                {!loading && dailyRows.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-5 py-8 text-center text-secondary-foreground">Không có dữ liệu MV cho bộ lọc hiện tại.</td>
                  </tr>
                ) : null}
                {loading ? (
                  Array(5).fill(0).map((_, index) => (
                    <tr key={index}>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-20" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-36" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-10" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-10" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-24" /></td>
                    </tr>
                  ))
                ) : null}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-bold text-foreground">Kết quả View: vw_order_sales_report (20 dòng gần nhất)</h2>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-accent/40 text-xs font-semibold uppercase tracking-wider text-secondary-foreground">
                <tr>
                  <th className="px-5 py-3">Đơn hàng</th>
                  <th className="px-5 py-3">Ngày</th>
                  <th className="px-5 py-3">Chi nhánh</th>
                  <th className="px-5 py-3">Sách</th>
                  <th className="px-5 py-3 text-right">SL</th>
                  <th className="px-5 py-3 text-right">Thành tiền dòng</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {(loading ? [] : overviewRows.slice(0, 20)).map((row) => (
                  <tr key={`${row.ORDER_ID}-${row.BOOK_TITLE}-${row.ORDER_DATE}`}>
                    <td className="px-5 py-4 font-semibold">#{row.ORDER_CODE}</td>
                    <td className="px-5 py-4">{new Date(row.ORDER_DATE).toLocaleDateString("vi-VN")}</td>
                    <td className="px-5 py-4">{row.BRANCH_NAME}</td>
                    <td className="px-5 py-4">{row.BOOK_TITLE}</td>
                    <td className="px-5 py-4 text-right">{row.QUANTITY}</td>
                    <td className="px-5 py-4 text-right font-semibold">{row.LINE_SUBTOTAL.toLocaleString("vi-VN")}đ</td>
                  </tr>
                ))}
                {!loading && overviewRows.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-5 py-8 text-center text-secondary-foreground">Không có dữ liệu view bán hàng.</td>
                  </tr>
                ) : null}
                {loading ? (
                  Array(5).fill(0).map((_, index) => (
                    <tr key={index}>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-20" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-20" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-24" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-36" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-10" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-20" /></td>
                    </tr>
                  ))
                ) : null}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  );
}
