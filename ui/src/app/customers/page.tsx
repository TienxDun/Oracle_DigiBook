"use client";

import React, { useEffect, useState } from "react";
import { Search, ShieldCheck, Users, TrendingUp } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

type CustomerSecureProfile = {
  CUSTOMER_ID: number;
  FULL_NAME: string;
  MASKED_EMAIL: string | null;
  MASKED_PHONE: string | null;
  MASKED_ADDRESS: string | null;
  PROVINCE: string | null;
  DISTRICT: string | null;
  TOTAL_ORDERS: number;
  TOTAL_SPENT: number;
  CUSTOMER_SEGMENT: "STANDARD" | "LOYAL" | "VIP";
};

const segmentStyle: Record<CustomerSecureProfile["CUSTOMER_SEGMENT"], string> = {
  STANDARD: "bg-slate-100 text-slate-700",
  LOYAL: "bg-indigo-100 text-indigo-700",
  VIP: "bg-amber-100 text-amber-700",
};

export default function CustomersPage() {
  const [rows, setRows] = useState<CustomerSecureProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [segment, setSegment] = useState("ALL");
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total: 0, totalPages: 1 });
  const limit = 20;

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const params = new URLSearchParams({
          page: String(page),
          limit: String(limit),
          search,
          segment,
        });

        const response = await fetch(`/api/customers?${params.toString()}`);
        const json = await response.json();

        if (json.success) {
          setRows(json.data ?? []);
          setPagination(json.pagination ?? { total: 0, totalPages: 1 });
        }
      } catch (error) {
        console.error("Failed to fetch customers:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [page, search, segment]);

  const totalSpent = rows.reduce((sum, row) => sum + (row.TOTAL_SPENT || 0), 0);

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Khách hàng bảo mật</h1>
          <p className="text-sm text-secondary-foreground">
            Kiểm thử view vw_customer_secure_profile với dữ liệu đã được masking.
          </p>
        </div>
        <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2">
          <ShieldCheck size={16} className="text-emerald-600" />
          <span className="text-xs font-bold uppercase tracking-wider text-emerald-700">
            Read-only secure view
          </span>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Khách hàng trong trang</div>
          <div className="mt-2 flex items-center gap-2 text-2xl font-black text-foreground">
            <Users size={22} />
            {rows.length}
          </div>
        </div>
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Tổng bản ghi</div>
          <div className="mt-2 text-2xl font-black text-foreground">{pagination.total}</div>
        </div>
        <div className="rounded-xl border border-border bg-white p-4">
          <div className="text-xs font-bold uppercase tracking-widest text-secondary-foreground">Tổng chi tiêu (trang hiện tại)</div>
          <div className="mt-2 flex items-center gap-2 text-2xl font-black text-foreground">
            <TrendingUp size={22} />
            {totalSpent.toLocaleString("vi-VN")}đ
          </div>
        </div>
      </div>

      <div className="rounded-xl border border-border bg-white p-4">
        <div className="flex flex-col gap-3 md:flex-row md:items-center">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
            <input
              value={search}
              onChange={(event) => {
                setSearch(event.target.value);
                setPage(1);
              }}
              placeholder="Tìm theo tên, email đã mask, số điện thoại đã mask"
              className="w-full rounded-lg border border-border bg-accent/20 py-2 pl-10 pr-3 text-sm outline-none focus:ring-1 focus:ring-primary"
            />
          </div>
          <select
            value={segment}
            onChange={(event) => {
              setSegment(event.target.value);
              setPage(1);
            }}
            aria-label="Lọc phân khúc khách hàng"
            className="rounded-lg border border-border bg-white px-3 py-2 text-sm font-medium outline-none"
          >
            <option value="ALL">Tất cả phân khúc</option>
            <option value="STANDARD">STANDARD</option>
            <option value="LOYAL">LOYAL</option>
            <option value="VIP">VIP</option>
          </select>
        </div>
      </div>

      <div className="overflow-hidden rounded-xl border border-border bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-accent/40 text-xs font-semibold uppercase tracking-wider text-secondary-foreground">
              <tr>
                <th className="px-5 py-3">Khách hàng</th>
                <th className="px-5 py-3">Email (masked)</th>
                <th className="px-5 py-3">SĐT (masked)</th>
                <th className="px-5 py-3">Địa chỉ (masked)</th>
                <th className="px-5 py-3 text-right">Đơn hàng</th>
                <th className="px-5 py-3 text-right">Chi tiêu</th>
                <th className="px-5 py-3 text-center">Segment</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(8)
                  .fill(0)
                  .map((_, index) => (
                    <tr key={index}>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-36" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-40" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-28" /></td>
                      <td className="px-5 py-4"><Skeleton className="h-4 w-44" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-12" /></td>
                      <td className="px-5 py-4"><Skeleton className="ml-auto h-4 w-20" /></td>
                      <td className="px-5 py-4"><Skeleton className="mx-auto h-6 w-16 rounded-full" /></td>
                    </tr>
                  ))
              ) : rows.length > 0 ? (
                rows.map((row) => (
                  <tr key={row.CUSTOMER_ID} className="hover:bg-accent/10">
                    <td className="px-5 py-4 font-semibold text-foreground">{row.FULL_NAME}</td>
                    <td className="px-5 py-4 font-mono text-xs text-secondary-foreground">{row.MASKED_EMAIL || "-"}</td>
                    <td className="px-5 py-4 font-mono text-xs text-secondary-foreground">{row.MASKED_PHONE || "-"}</td>
                    <td className="px-5 py-4 text-secondary-foreground">{row.MASKED_ADDRESS || "-"}</td>
                    <td className="px-5 py-4 text-right font-semibold">{row.TOTAL_ORDERS}</td>
                    <td className="px-5 py-4 text-right font-semibold">{row.TOTAL_SPENT.toLocaleString("vi-VN")}đ</td>
                    <td className="px-5 py-4 text-center">
                      <span className={cn("rounded-full px-2.5 py-1 text-xs font-bold", segmentStyle[row.CUSTOMER_SEGMENT])}>
                        {row.CUSTOMER_SEGMENT}
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-5 py-10 text-center text-secondary-foreground">
                    Không có dữ liệu phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex items-center justify-between">
        <p className="text-sm text-secondary-foreground">
          Trang {page}/{pagination.totalPages}
        </p>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            disabled={page <= 1}
            className="rounded-lg border border-border px-3 py-1.5 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50"
          >
            Trước
          </button>
          <button
            onClick={() => setPage((prev) => Math.min(pagination.totalPages, prev + 1))}
            disabled={page >= pagination.totalPages}
            className="rounded-lg border border-border px-3 py-1.5 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50"
          >
            Sau
          </button>
        </div>
      </div>
    </div>
  );
}
