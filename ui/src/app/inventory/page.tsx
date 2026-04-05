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
  MapPin,
  Lightbulb,
  Building2,
  Tags,
  CheckCircle2,
  XCircle,
  AlertCircle
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { BranchInventory, DashboardStats } from "@/types/database";
import { HistoryDrawer } from "@/components/inventory/history-drawer";
import { TransferDrawer } from "@/components/inventory/transfer-drawer";
import { StockInDrawer } from "@/components/inventory/stock-in-drawer";
import { LowStockDrawer } from "@/components/inventory/low-stock-drawer";
import { ThresholdDrawer } from "@/components/inventory/threshold-drawer";
import { useBranch } from "@/context/branch-context";


export default function InventoryPage() {
  const { currentBranch, currentUser } = useBranch();
  const [inventory, setInventory] = useState<BranchInventory[]>([]);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [branchFilterId, setBranchFilterId] = useState("ALL");
  const [selectedCategory, setSelectedCategory] = useState("ALL");
  const [selectedPublisher, setSelectedPublisher] = useState("ALL");
  const [selectedStockStatus, setSelectedStockStatus] = useState("all");
  const [showLowStockOnly, setShowLowStockOnly] = useState(false);
  
  const [categories, setCategories] = useState<any[]>([]);
  const [publishers, setPublishers] = useState<any[]>([]);
  
  // Drawer states
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isTransferOpen, setIsTransferOpen] = useState(false);
  const [isStockInOpen, setIsStockInOpen] = useState(false);
  const [isLowStockOpen, setIsLowStockOpen] = useState(false);
  const [isThresholdOpen, setIsThresholdOpen] = useState(false);
  const [selectedBookId, setSelectedBookId] = useState<number | undefined>(undefined);
  const [selectedBookForThreshold, setSelectedBookForThreshold] = useState<any>(null);


  useEffect(() => {
    fetchFilters();
  }, []);

  useEffect(() => {
    fetchInventoryData();
  }, [currentBranch, selectedCategory, selectedPublisher, selectedStockStatus]);

  const fetchFilters = async () => {
    try {
      const [catRes, pubRes] = await Promise.all([
        fetch("/api/categories"),
        fetch("/api/publishers")
      ]);
      const cats = await catRes.json();
      const pubs = await pubRes.json();
      if (cats.success) setCategories(cats.data);
      if (pubs.success) setPublishers(pubs.data);
    } catch (error) {
      console.error("Failed to fetch filters:", error);
    }
  };

  // Validate branchFilter whenever inventory data changes
  useEffect(() => {
    const branchIds = new Set(
      inventory
        .map((i) => i.BRANCH_ID)
        .filter((id): id is number => typeof id === "number")
        .map((id) => id.toString())
    );
    
    // If current branchFilter is not valid (not "ALL" and not in available branches), reset to "ALL"
    if (branchFilterId !== "ALL" && !branchIds.has(branchFilterId)) {
      setBranchFilterId("ALL");
    }
  }, [inventory, branchFilterId]);

  const fetchInventoryData = async () => {
    setLoading(true);
    try {
      const branchIdForStats = currentBranch?.id || "ALL";
      
      const params = new URLSearchParams();
      // Luôn lấy toàn bộ sách để hiển thị bảng Pivot, không lọc ở API theo branchId
      if (selectedCategory !== "ALL") params.append("categoryId", selectedCategory);
      if (selectedPublisher !== "ALL") params.append("publisherId", selectedPublisher);
      if (selectedStockStatus !== "all") params.append("stockStatus", selectedStockStatus);

      const [invRes, statsRes] = await Promise.all([
        fetch(`/api/inventory?${params.toString()}`),
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
    
    if (item.BRANCH_NAME && typeof item.BRANCH_ID === "number") {
      acc[item.BOOK_ID].BRANCHES[item.BRANCH_ID.toString()] = {
        name: item.BRANCH_NAME,
        quantity: qty,
        threshold: threshold,
        isLow: qty <= threshold,
      };
    }

    acc[item.BOOK_ID].TOTAL += qty;
    
    // Thu thập tất cả các ngưỡng để hiển thị Min - Max
    if (!acc[item.BOOK_ID].ALL_THRESHOLDS) {
      acc[item.BOOK_ID].ALL_THRESHOLDS = [];
    }
    acc[item.BOOK_ID].ALL_THRESHOLDS.push(threshold);

    // Vẫn giữ lại một ngưỡng đại diện (giá trị đầu tiên)
    if (!acc[item.BOOK_ID].LOW_STOCK_THRESHOLD) {
      acc[item.BOOK_ID].LOW_STOCK_THRESHOLD = threshold;
    }

    if (qty <= threshold || !item.INVENTORY_ID) {
      acc[item.BOOK_ID].IS_LOW_STOCK = true;
    }

    
    return acc;
  }, {});

  // Post-processing for suggestions and percentages
  Object.values(groupedData).forEach((book: any) => {
    // 1. Calculate suggestions using dynamic thresholds
    const branches = Object.entries(book.BRANCHES).map(([id, data]: [string, any]) => ({ id, ...data }));
    const lowStockBranches = branches.filter(b => b.quantity <= b.threshold);
    // Healthy: More than 2x threshold and at least 20 units
    const healthyBranches = branches.filter(b => b.quantity > (b.threshold * 2) && b.quantity > 20)
                                    .sort((a, b) => b.quantity - a.quantity);

    if (lowStockBranches.length > 0 && healthyBranches.length > 0) {
      const source = healthyBranches[0];
      const target = lowStockBranches[0];
      book.SUGGESTION = {
        from: source.name,
        fromId: source.id,
        to: target.name,
        toId: target.id,
        // Amount: transfer half of the surplus over threshold
        amount: Math.max(1, Math.floor((source.quantity - source.threshold) / 2))
      };
    }


    // 2. Percentages for distribution bar
    branches.forEach((b: any) => {
      if (book.BRANCHES[b.id]) {
        book.BRANCHES[b.id].percentage = book.TOTAL > 0 ? (b.quantity / book.TOTAL) * 100 : 0;
      }
    });
  });

  // Get unique branch names for columns (filter out nulls)
  const branchOptions = Array.from(
    new Map(
      inventory
        .filter((i) => i.BRANCH_NAME && typeof i.BRANCH_ID === "number")
        .map((i) => [i.BRANCH_ID.toString(), i.BRANCH_NAME])
    ).entries()
  )
    .map(([id, name]) => ({ id, name }))
    .sort((a, b) => a.name.localeCompare(b.name, "vi"));

  const displayData = Object.values(groupedData).filter((item: any) => {
    const matchesSearch = item.TITLE.toLowerCase().includes(search.toLowerCase()) || 
                         item.ISBN.includes(search);
    
    const matchesBranch = branchFilterId === "ALL" || item.BRANCHES[branchFilterId] !== undefined;

    let matchesLowStock = true;
    if (showLowStockOnly) {
      if (branchFilterId === "ALL") {
        matchesLowStock = item.IS_LOW_STOCK;
      } else {
        matchesLowStock = Boolean(item.BRANCHES[branchFilterId]?.isLow);
      }
    }

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
          onClick={() => setIsLowStockOpen(true)}
          className="card-shadow flex flex-col rounded-xl border p-6 cursor-pointer transition-all bg-rose-50/30 border-rose-500 ring-1 ring-rose-500/20 hover:bg-rose-50"
         >
            <div className="mb-4 flex items-center justify-between text-rose-600">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-rose-500/10 p-2"><AlertTriangle size={20} /></div>
                <span className="text-sm font-semibold">Cảnh báo tồn kho</span>
              </div>
              <span className="text-xs font-semibold bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full animate-pulse border border-rose-200">Test SP</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <div className="flex items-end gap-2">
                <span className="text-2xl font-bold text-rose-600">{stats?.LOW_STOCK_COUNT || 0}</span>
                <span className="mb-1 text-xs font-normal text-secondary-foreground text-rose-600/70">mục sắp hết</span>
              </div>
            )}
         </div>

         <div className="card-shadow flex flex-col rounded-xl border border-border bg-white p-6">
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
              <div className="rounded-lg bg-warning/10 p-2"><Tags size={20} /></div>
              <span className="text-sm font-semibold">Đầu sách (Titles)</span>
            </div>
            {loading ? <Skeleton className="h-8 w-24" /> : (
              <span className="text-2xl font-bold">{Object.keys(groupedData).length} <span className="text-xs font-normal text-secondary-foreground">loại</span></span>
            )}
         </div>
      </div>

      {/* Advanced Filters */}
      <div className="grid gap-4 md:grid-cols-4">
        <div className="space-y-2">
          <label className="text-xs font-bold uppercase text-secondary-foreground flex items-center gap-2">
            <Tags size={14} /> Danh mục
          </label>
          <select 
            value={selectedCategory}
            onChange={(e) => {setSelectedCategory(e.target.value); setLoading(true);}}
            className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm focus:ring-1 focus:ring-primary outline-none"
          >
            <option value="ALL">Tất cả danh mục</option>
            {categories.map(c => <option key={c.CATEGORY_ID} value={c.CATEGORY_ID}>{c.CATEGORY_NAME}</option>)}
          </select>
        </div>
        <div className="space-y-2">
          <label className="text-xs font-bold uppercase text-secondary-foreground flex items-center gap-2">
            <Building2 size={14} /> Nhà xuất bản
          </label>
          <select 
            value={selectedPublisher}
            onChange={(e) => {setSelectedPublisher(e.target.value); setLoading(true);}}
            className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm focus:ring-1 focus:ring-primary outline-none"
          >
            <option value="ALL">Tất cả NXB</option>
            {publishers.map(p => <option key={p.PUBLISHER_ID} value={p.PUBLISHER_ID}>{p.PUBLISHER_NAME}</option>)}
          </select>
        </div>
        <div className="md:col-span-2 space-y-2">
          <label className="text-xs font-bold uppercase text-secondary-foreground">Tình trạng kho nhanh</label>
          <div className="flex bg-accent/20 p-1 rounded-lg gap-1">
            {[
              { id: "all", label: "Tất cả", icon: Package },
              { id: "in", label: "Còn hàng", icon: CheckCircle2, color: "text-emerald-600" },
              { id: "low", label: "Sắp hết", icon: AlertCircle, color: "text-amber-600" },
              { id: "out", label: "Hết hàng", icon: XCircle, color: "text-rose-600" }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => {setSelectedStockStatus(tab.id); setLoading(true);}}
                className={cn(
                  "flex-1 flex items-center justify-center gap-2 px-3 py-1.5 rounded-md text-xs font-bold transition-all",
                  selectedStockStatus === tab.id ? "bg-white shadow-sm text-primary" : "text-secondary-foreground hover:bg-white/50"
                )}
              >
                <tab.icon size={14} className={tab.color} />
                {tab.label}
              </button>
            ))}
          </div>
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
                    value={branchFilterId}
                    onChange={(e) => setBranchFilterId(e.target.value)}
                    title="Lọc theo chi nhánh"
                    className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
                  >
                    <option value="ALL">Tất cả chi nhánh</option>
                    {branchOptions.map((branch) => (
                      <option key={branch.id} value={branch.id}>{branch.name}</option>
                    ))}
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
                <th className="px-6 py-4 text-center">Phân bổ (%)</th>
                {branchOptions.map((branch) => (
                  <th key={branch.id} className={cn(
                    "px-6 py-4 text-center transition-all",
                    branchFilterId !== "ALL" && branchFilterId !== branch.id && "opacity-20 blur-[1px]"
                  )}>
                    {branch.name}
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
                    <td className="px-6 py-4"><Skeleton className="h-2 w-24 mx-auto rounded" /></td>
                    {branchOptions.length > 0 ? branchOptions.map((branch) => (
                      <td key={branch.id} className="px-6 py-4"><Skeleton className="h-6 w-12 mx-auto rounded" /></td>
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
                      <div className="flex flex-col relative group">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-foreground group-hover:text-primary transition-colors cursor-pointer">{item.TITLE}</span>
                          {item.SUGGESTION && (
                            <div className="relative group/sug">
                              <Lightbulb size={16} className="text-amber-500 animate-bounce cursor-help" />
                              <div className="invisible group-hover/sug:visible absolute left-1/2 -translate-x-1/2 bottom-full mb-2 w-64 p-3 bg-slate-800 text-white text-[11px] rounded-lg shadow-xl z-50">
                                <p className="font-bold mb-1 text-amber-400">💡 Gợi ý điều chuyển</p>
                                <p>Sắp hết hàng tại <span className="font-bold">{item.SUGGESTION.to}</span>.</p>
                                <p>Có thể nhập từ <span className="font-bold text-emerald-400">{item.SUGGESTION.from}</span> ({item.BRANCHES[item.SUGGESTION.fromId]?.quantity} cuốn).</p>
                                <button 
                                  onClick={() => handleTransferClick(item.ID)}
                                  className="mt-2 w-full bg-primary py-1 rounded font-bold hover:bg-primary-hover"
                                >
                                  Thực hiện ngay
                                </button>
                                <div className="absolute top-full left-1/2 -translate-x-1/2 border-8 border-transparent border-t-slate-800"></div>
                              </div>
                            </div>
                          )}
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-[11px] text-secondary-foreground uppercase font-mono tracking-tighter">ISBN: {item.ISBN}</span>
                          <button 
                            onClick={() => {
                              setSelectedBookForThreshold(item);
                              setIsThresholdOpen(true);
                            }}
                            className="text-[10px] bg-indigo-50 text-indigo-600 px-1.5 py-0.5 rounded border border-indigo-100 font-bold hover:bg-indigo-600 hover:text-white transition-all cursor-pointer shadow-sm active:scale-95"
                            title="Nhấn để cấu hình ngưỡng báo động"
                          >
                            Ngưỡng: {(() => {
                              const unique = Array.from(new Set(item.ALL_THRESHOLDS || [])) as number[];
                              if (unique.length <= 1) return unique[0] || 10;
                              const min = Math.min(...unique);
                              const max = Math.max(...unique);
                              return `${min} - ${max}`;
                            })()}
                          </button>

                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex h-2 w-24 overflow-hidden rounded-full bg-slate-100 mx-auto">
                        {branchOptions.map((branch, idx) => {
                          const percentage = item.BRANCHES[branch.id]?.percentage || 0;
                          if (percentage === 0) return null;
                          const colors = ['bg-blue-500', 'bg-emerald-500', 'bg-amber-500', 'bg-rose-500', 'bg-violet-500'];
                          return (
                            <div 
                              key={branch.id}
                              title={`${branch.name}: ${Math.round(percentage)}%`}
                              className={cn(colors[idx % colors.length], "h-full")}
                              style={{ width: `${percentage}%` }}
                            />
                          );
                        })}
                      </div>
                    </td>
                    {branchOptions.map((branch) => {
                      const branchData = item.BRANCHES[branch.id];
                      const qty = branchData?.quantity || 0;
                      return (
                        <td key={branch.id} className={cn(
                          "px-6 py-4 text-center transition-all",
                          branchFilterId !== "ALL" && branchFilterId !== branch.id && "opacity-20"
                        )}>
                          <span className={cn(
                            "inline-block min-w-[2.5rem] rounded-md px-2 py-1 font-bold transition-all", 
                            qty === 0 ? "bg-rose-50 text-rose-600 scale-95" : branchData?.isLow ? "bg-amber-50 text-amber-600 shadow-sm shadow-amber-200/50" : "bg-accent/50 text-foreground"
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
                  <td colSpan={branchOptions.length + 3} className="px-6 py-24 text-center">
                    <div className="flex flex-col items-center gap-3 text-secondary-foreground">
                      <Search size={48} className="opacity-10" />
                      <p className="font-medium">Không tìm thấy dữ liệu tồn kho nào.</p>
                      <button 
                        onClick={() => {setSearch(""); setBranchFilterId("ALL"); setShowLowStockOnly(false);}}
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
        branchId={branchFilterId !== "ALL" ? branchFilterId : undefined}
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

      <LowStockDrawer
        isOpen={isLowStockOpen}
        onClose={() => setIsLowStockOpen(false)}
        branchId={branchFilterId !== "ALL" ? branchFilterId : undefined}
      />

      <ThresholdDrawer
        isOpen={isThresholdOpen}
        onClose={() => setIsThresholdOpen(false)}
        bookData={selectedBookForThreshold}
        onSuccess={fetchInventoryData}
      />
    </div>
  );
}
