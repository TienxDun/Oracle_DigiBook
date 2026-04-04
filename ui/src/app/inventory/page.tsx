"use client";

import React, { useState, useEffect } from "react";
import { 
  History, 
  ArrowLeftRight, 
  AlertTriangle, 
  Package,
  PackagePlus,
  TrendingDown,
  ChevronRight,
  Search,
  Filter,
  RefreshCw,
  MapPin
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { BranchInventory, DashboardStats } from "@/types/database";
import { HistoryDrawer } from "@/components/inventory/history-drawer";
import { TransferDrawer } from "@/components/inventory/transfer-drawer";
import { StockInDrawer } from "@/components/inventory/stock-in-drawer";
import { useBranch } from "@/context/branch-context";

export default function InventoryPage() {
  const { currentBranch, currentUser } = useBranch();
  const [inventory, setInventory] = useState<BranchInventory[]>([]);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [branchFilter, setBranchFilter] = useState("ALL");
  const [showLowStockOnly, setShowLowStockOnly] = useState(false);
  
  // Drawer states
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isTransferOpen, setIsTransferOpen] = useState(false);
  const [isStockInOpen, setIsStockInOpen] = useState(false);
  const [selectedBookId, setSelectedBookId] = useState<number | undefined>(undefined);

  useEffect(() => {
    if (currentBranch) {
      setBranchFilter(currentBranch.name);
    } else {
      setBranchFilter("ALL");
    }
    fetchInventoryData();
  }, [currentBranch]);

  // Validate branchFilter whenever inventory data changes
  useEffect(() => {
    const branchNames = Array.from(new Set(inventory.map(i => i.BRANCH_NAME).filter(Boolean))).sort() as string[];
    
    // If current branchFilter is not valid (not "ALL" and not in available branches), reset to "ALL"
    if (branchFilter !== "ALL" && !branchNames.includes(branchFilter)) {
      setBranchFilter("ALL");
    }
  }, [inventory]);

  const fetchInventoryData = async () => {
    setLoading(true);
    try {
      const branchIdForStats = currentBranch?.id || "ALL";
      // Always fetch all inventory data for pivot table display
      // Branch filtering is done on frontend via branchFilter
      
      const [invRes, statsRes] = await Promise.all([
        fetch("/api/inventory"),
        fetch(`/api/dashboard/stats?branchId=${branchIdForStats}`)
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
        IS_LOW_STOCK: false,
        BRANCHES: {}
      };
    }
    
    const qty = Number(item.QUANTITY_AVAILABLE || 0);
    const threshold = Number(item.LOW_STOCK_THRESHOLD || 10);
    
    if (item.BRANCH_NAME) {
      acc[item.BOOK_ID].BRANCHES[item.BRANCH_NAME] = qty;
    }
    acc[item.BOOK_ID].TOTAL += qty;
    
    if (qty <= threshold) {
      acc[item.BOOK_ID].IS_LOW_STOCK = true;
    }
    
    return acc;
  }, {});

  // Get unique branch names for columns (filter out nulls)
  const branchNames = Array.from(new Set(inventory.map(i => i.BRANCH_NAME).filter(Boolean))).sort() as string[];

  const displayData = Object.values(groupedData).filter((item: any) => {
    const matchesSearch = item.TITLE.toLowerCase().includes(search.toLowerCase()) || 
                         item.ISBN.includes(search);
    
    const matchesBranch = branchFilter === "ALL" || (item.BRANCHES[branchFilter] !== undefined);
    
    const matchesLowStock = !showLowStockOnly || item.IS_LOW_STOCK;

    return matchesSearch && matchesBranch && matchesLowStock;
  });

  const handleTransferClick = (bookId?: number) => {
    setSelectedBookId(bookId);
    setIsTransferOpen(true);
  };

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Tồn kho Chi nhánh</h1>
          <p className="text-sm text-secondary-foreground">Theo dõi và điều phối hàng hóa toàn hệ thống DigiBook (Oracle 19c).</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setIsHistoryOpen(true)}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <History size={16} />
            Lịch sử giao dịch
          </button>
          <button 
            onClick={() => {
              setSelectedBookId(undefined);
              setIsStockInOpen(true);
            }}
            className="flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-emerald-500/20 hover:bg-emerald-700 transition-all active:scale-95"
          >
            <Package size={16} />
            Nhập hàng
          </button>
          <button 
            onClick={() => handleTransferClick()}
            className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary/20 hover:bg-primary-hover transition-all active:scale-95"
          >
            <ArrowLeftRight size={16} />
            Điều chuyển kho
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
         <div 
          onClick={() => setShowLowStockOnly(false)}
          className={cn(
            "card-shadow flex flex-col rounded-xl border p-6 cursor-pointer transition-all",
            !showLowStockOnly ? "bg-white border-primary ring-1 ring-primary/20" : "bg-white border-border grayscale opacity-70 hover:grayscale-0 hover:opacity-100"
          )}
         >
            <div className="mb-4 flex items-center gap-3 text-primary">
              <div className="rounded-lg bg-primary/10 p-2"><Package size={20} /></div>
              <span className="text-sm font-semibold">Tổng tồn kho</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{stats?.TOTAL_STOCK.toLocaleString() || 0} <span className="text-xs font-normal text-secondary-foreground">cuốn</span></span>
            )}
         </div>

         <div 
          onClick={() => setShowLowStockOnly(true)}
          className={cn(
            "card-shadow flex flex-col rounded-xl border p-6 cursor-pointer transition-all",
            showLowStockOnly ? "bg-rose-50/30 border-rose-500 ring-1 ring-rose-500/20" : "bg-white border-border grayscale opacity-70 hover:grayscale-0 hover:opacity-100 border-l-4 border-l-rose-500"
          )}
         >
            <div className="mb-4 flex items-center gap-3 text-rose-600">
              <div className="rounded-lg bg-rose-500/10 p-2"><AlertTriangle size={20} /></div>
              <span className="text-sm font-semibold">Cảnh báo tồn kho</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <div className="flex items-end gap-2">
                <span className="text-2xl font-bold text-rose-600">{stats?.LOW_STOCK_COUNT || 0}</span>
                <span className="mb-1 text-xs font-normal text-secondary-foreground text-rose-600/70">mục sắp hết</span>
              </div>
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
              <span className="text-sm font-semibold">Đầu sách (Titles)</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{Object.keys(groupedData).length} <span className="text-xs font-normal text-secondary-foreground">loại</span></span>
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
                  placeholder="Tìm sách bằng Tên hoặc ISBN..." 
                  className="w-full rounded-lg border border-border bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div className="flex gap-2">
                <div className="relative">
                  <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={16} />
                  <select 
                    value={branchFilter}
                    onChange={(e) => setBranchFilter(e.target.value)}
                    className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
                  >
                    <option value="ALL">Tất cả chi nhánh</option>
                    {branchNames.map(name => <option key={name} value={name}>{name}</option>)}
                  </select>
                </div>
                <button 
                  onClick={fetchInventoryData}
                  className="p-2.5 rounded-lg border border-border bg-white text-secondary-foreground hover:bg-accent transition-all"
                  title="Tải lại dữ liệu"
                >
                  <RefreshCw size={18} className={loading ? "animate-spin" : ""} />
                </button>
              </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Sách / ISBN</th>
                {branchNames.map(name => (
                  <th key={name} className={cn(
                    "px-6 py-4 text-center transition-all",
                    branchFilter !== "ALL" && branchFilter !== name && "opacity-20 blur-[1px]"
                  )}>
                    {name}
                  </th>
                ))}
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
                        <span className="text-[11px] text-secondary-foreground uppercase font-mono tracking-tighter">ISBN: {item.ISBN}</span>
                      </div>
                    </td>
                    {branchNames.map(name => {
                      const qty = item.BRANCHES[name] || 0;
                      return (
                        <td key={name} className={cn(
                          "px-6 py-4 text-center transition-all",
                          branchFilter !== "ALL" && branchFilter !== name && "opacity-20"
                        )}>
                          <span className={cn(
                            "inline-block min-w-[2.5rem] rounded-md px-2 py-1 font-bold transition-all", 
                            qty === 0 ? "bg-rose-50 text-rose-600 scale-95" : qty < 10 ? "bg-amber-50 text-amber-600 shadow-sm shadow-amber-200/50" : "bg-accent/50 text-foreground"
                          )}>
                            {qty}
                          </span>
                        </td>
                      );
                    })}
                    <td className="px-6 py-4 text-right">
                      <span className="text-base font-black text-foreground">{item.TOTAL.toLocaleString()}</span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-all">
                        <button 
                          onClick={() => {
                            setSelectedBookId(item.ID);
                            setIsStockInOpen(true);
                          }}
                          className="rounded-md p-2 text-emerald-600 hover:bg-emerald-50 transition-all"
                          title="Nhập thêm sách này"
                        >
                          <PackagePlus size={18} />
                        </button>
                        <button 
                          onClick={() => handleTransferClick(item.ID)}
                          className="rounded-md p-2 text-primary hover:bg-primary/10 transition-all"
                          title="Điều chuyển sách này"
                        >
                          <ArrowLeftRight size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={branchNames.length + 3} className="px-6 py-24 text-center">
                    <div className="flex flex-col items-center gap-3 text-secondary-foreground">
                      <Search size={48} className="opacity-10" />
                      <p className="font-medium">Không tìm thấy dữ liệu tồn kho nào.</p>
                      <button 
                        onClick={() => {setSearch(""); setBranchFilter("ALL"); setShowLowStockOnly(false);}}
                        className="text-xs font-bold text-primary underline underline-offset-4"
                      >
                        Xóa tất cả bộ lọc
                      </button>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Drawers */}
      <HistoryDrawer 
        isOpen={isHistoryOpen} 
        onClose={() => setIsHistoryOpen(false)} 
        branchId={inventory.find(i => i.BRANCH_NAME === branchFilter)?.BRANCH_ID.toString()}
      />

      <TransferDrawer 
        isOpen={isTransferOpen} 
        onClose={() => setIsTransferOpen(false)} 
        onSuccess={fetchInventoryData}
        initialBookId={selectedBookId}
      />

      <StockInDrawer
        isOpen={isStockInOpen}
        onClose={() => setIsStockInOpen(false)}
        onSuccess={fetchInventoryData}
        initialBookId={selectedBookId}
      />
    </div>
  );
}
