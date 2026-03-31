"use client";

import React, { useState, useEffect } from "react";
import { 
  History, 
  ArrowLeftRight, 
  AlertTriangle, 
  Package,
  TrendingDown,
  ChevronRight,
  Search,
  Filter
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { BranchInventory, DashboardStats } from "@/types/database";

export default function InventoryPage() {
  const [inventory, setInventory] = useState<BranchInventory[]>([]);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [branchFilter, setBranchFilter] = useState("ALL");

  useEffect(() => {
    fetchInventoryData();
  }, []);

  const fetchInventoryData = async () => {
    setLoading(true);
    try {
      const [invRes, statsRes] = await Promise.all([
        fetch("/api/inventory"),
        fetch("/api/dashboard/stats")
      ]);
      const invData = await invRes.json();
      const statsData = await statsRes.json();

      if (invData.success) setInventory(invData.data);
      if (statsData.success) setStats(statsData.data);
    } catch (error) {
      console.error("Failed to fetch inventory data:", error);
    } finally {
      setLoading(false);
    }
  };

  // Group inventory by Book (Pivot table logic)
  const groupedData = inventory.reduce((acc: any, item) => {
    if (!acc[item.BOOK_ID]) {
      acc[item.BOOK_ID] = {
        ID: item.BOOK_ID,
        TITLE: item.BOOK_TITLE,
        ISBN: item.ISBN,
        TOTAL: 0,
        BRANCHES: {}
      };
    }
    acc[item.BOOK_ID].BRANCHES[item.BRANCH_NAME] = item.QUANTITY;
    acc[item.BOOK_ID].TOTAL += item.QUANTITY;
    return acc;
  }, {});

  const displayData = Object.values(groupedData).filter((item: any) => 
    item.TITLE.toLowerCase().includes(search.toLowerCase()) || 
    item.ISBN.includes(search)
  );

  // Get unique branch names for columns
  const branchNames = Array.from(new Set(inventory.map(i => i.BRANCH_NAME))).sort();

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Tồn kho Chi nhánh</h1>
          <p className="text-sm text-secondary-foreground">Theo dõi và điều phối hàng hóa toàn hệ thống DigiBook (Oracle 19c).</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors">
            <History size={16} />
            Lịch sử giao dịch
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all">
            <ArrowLeftRight size={16} />
            Điều chuyển kho
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
         <div className="card-shadow flex flex-col rounded-xl border border-border bg-white p-6">
            <div className="mb-4 flex items-center gap-3 text-primary">
              <div className="rounded-lg bg-primary/10 p-2"><Package size={20} /></div>
              <span className="text-sm font-semibold">Tổng tồn kho</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{stats?.TOTAL_STOCK.toLocaleString() || 0} <span className="text-xs font-normal text-secondary-foreground">cuốn</span></span>
            )}
         </div>
         <div className="card-shadow flex flex-col rounded-xl border border-border bg-white p-6 border-l-4 border-l-error">
            <div className="mb-4 flex items-center gap-3 text-error">
              <div className="rounded-lg bg-error/10 p-2"><AlertTriangle size={20} /></div>
              <span className="text-sm font-semibold">Cảnh báo tồn kho</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{stats?.LOW_STOCK_COUNT || 0} <span className="text-xs font-normal text-secondary-foreground">mục</span></span>
            )}
         </div>
         <div className="card-shadow flex flex-col rounded-xl border border-border bg-white p-6 border-l-4 border-l-info">
            <div className="mb-4 flex items-center gap-3 text-info">
              <div className="rounded-lg bg-info/10 p-2"><ArrowLeftRight size={20} /></div>
              <span className="text-sm font-semibold">Lệnh chờ xử lý</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{stats?.PENDING_ORDERS || 0} <span className="text-xs font-normal text-secondary-foreground">đơn</span></span>
            )}
         </div>
         <div className="card-shadow flex flex-col rounded-xl border border-border bg-white p-6">
            <div className="mb-4 flex items-center gap-3 text-warning">
              <div className="rounded-lg bg-warning/10 p-2"><TrendingDown size={20} /></div>
              <span className="text-sm font-semibold">Vật phẩm (Titles)</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{Object.keys(groupedData).length} <span className="text-xs font-normal text-secondary-foreground">đầu sách</span></span>
            )}
         </div>
      </div>

      {/* Inventory Table */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="border-b border-border p-4 bg-accent/10">
          <div className="flex flex-col gap-4 md:flex-row md:items-center">
             <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
                <input 
                  type="text" 
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Tìm sách để kiểm tra tồn kho..." 
                  className="w-full rounded-lg border border-border bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div className="flex gap-2">
                <select className="rounded-lg border border-border bg-white px-3 py-2 text-sm font-medium outline-none transition-colors">
                  <option>Tất cả chi nhánh</option>
                  {branchNames.map(name => <option key={name}>{name}</option>)}
                </select>
                <button className="flex items-center gap-2 rounded-lg border border-border bg-white px-3 py-2 text-sm font-medium hover:bg-accent transition-colors">
                  <Filter size={16} />
                </button>
              </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Sách / Tác giả</th>
                {branchNames.map(name => <th key={name} className="px-6 py-4 text-center">{name}</th>)}
                <th className="px-6 py-4 text-right">Tổng cộng</th>
                <th className="px-6 py-4"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4 space-y-2">
                      <Skeleton className="h-4 w-48" />
                      <Skeleton className="h-3 w-32" />
                    </td>
                    {branchNames.length > 0 ? branchNames.map(n => (
                      <td key={n} className="px-6 py-4"><Skeleton className="h-6 w-12 mx-auto rounded" /></td>
                    )) : Array(3).fill(0).map((_, j) => (
                      <td key={j} className="px-6 py-4"><Skeleton className="h-6 w-12 mx-auto rounded" /></td>
                    ))}
                    <td className="px-6 py-4 text-right"><Skeleton className="h-6 w-16 ml-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-8 w-8 ml-auto rounded-full" /></td>
                  </tr>
                ))
              ) : displayData.length > 0 ? (
                displayData.map((item: any) => (
                  <tr key={item.ID} className="group transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4">
                      <div className="flex flex-col">
                        <span className="font-semibold text-foreground group-hover:text-primary transition-colors cursor-pointer">{item.TITLE}</span>
                        <span className="text-[11px] text-secondary-foreground uppercase">ISBN: {item.ISBN}</span>
                      </div>
                    </td>
                    {branchNames.map(name => {
                      const qty = item.BRANCHES[name] || 0;
                      return (
                        <td key={name} className="px-6 py-4 text-center">
                          <span className={cn(
                            "inline-block min-w-[2.5rem] rounded-md px-2 py-1 font-bold", 
                            qty === 0 ? "bg-rose-50 text-rose-600" : qty < 10 ? "bg-amber-50 text-amber-600" : "bg-accent text-foreground"
                          )}>
                            {qty}
                          </span>
                        </td>
                      );
                    })}
                    <td className="px-6 py-4 text-right">
                      <span className="text-lg font-black text-foreground">{item.TOTAL.toLocaleString()}</span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button className="rounded-md p-1.5 text-secondary-foreground hover:bg-primary/10 hover:text-primary transition-all">
                        <ChevronRight size={18} />
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={branchNames.length + 3} className="px-6 py-20 text-center text-secondary-foreground">
                    Không tìm thấy dữ liệu tồn kho phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
