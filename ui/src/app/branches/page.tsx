"use client";

import React, { useState, useEffect } from "react";
import { 
  Building2, 
  Search,
  MapPin,
  Phone,
  Settings,
  Plus,
  RefreshCw
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

type Branch = {
  BRANCH_ID: number;
  BRANCH_CODE: string;
  BRANCH_NAME: string;
  BRANCH_TYPE: string;
  ADDRESS: string;
  PHONE?: string;
  STATUS?: string;
};

export default function BranchesPage() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetchBranches();
  }, []);

  const fetchBranches = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/branches");
      const data = await res.json();
      if (data.success) {
        setBranches(data.data);
      } else {
        toast.error("Không thể tải danh sách chi nhánh");
      }
    } catch (error) {
      console.error("Failed to fetch branches:", error);
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  const filteredBranches = branches.filter(b => 
    b.BRANCH_NAME.toLowerCase().includes(search.toLowerCase()) ||
    b.BRANCH_CODE.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Hệ thống Chi nhánh</h1>
          <p className="text-sm text-secondary-foreground">Xem và quản lý các cửa hàng, kho bãi trong hệ thống DigiBook.</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={fetchBranches}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <RefreshCw size={16} className={cn(loading && "animate-spin")} />
            Làm mới
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all">
            <Plus size={16} />
            Thêm chi nhánh
          </button>
        </div>
      </div>

      {/* Search & Stats Summary */}
      <div className="grid gap-4 md:grid-cols-4">
        <div className="card-shadow flex flex-col justify-center rounded-xl border border-border bg-white p-4 md:col-span-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
            <input 
              type="text" 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm theo tên hoặc mã chi nhánh..." 
              className="w-full rounded-lg border border-border bg-accent/30 py-2.5 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
            />
          </div>
        </div>
        <div className="card-shadow flex items-center justify-between rounded-xl border border-border bg-primary/5 p-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-primary">Tổng cộng</p>
            <p className="text-2xl font-bold text-primary">{branches.length}</p>
          </div>
          <Building2 size={32} className="text-primary/20" />
        </div>
      </div>

      {/* Branches List */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {loading ? (
          Array(6).fill(0).map((_, i) => (
            <div key={i} className="card-shadow rounded-xl border border-border bg-white p-5 space-y-4">
              <div className="flex items-center gap-3">
                <Skeleton className="h-10 w-10 rounded-lg" />
                <div className="space-y-2">
                  <Skeleton className="h-4 w-32" />
                  <Skeleton className="h-3 w-20" />
                </div>
              </div>
              <Skeleton className="h-4 w-full" />
              <div className="flex justify-between pt-2">
                <Skeleton className="h-8 w-20" />
                <Skeleton className="h-8 w-8" />
              </div>
            </div>
          ))
        ) : filteredBranches.length > 0 ? (
          filteredBranches.map((branch) => (
            <div key={branch.BRANCH_ID} className="card-shadow group relative overflow-hidden rounded-xl border border-border bg-white p-5 transition-all hover:border-primary/50 hover:shadow-lg">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={cn(
                    "flex h-12 w-12 items-center justify-center rounded-xl transition-colors",
                    branch.BRANCH_TYPE === 'STORE' ? "bg-primary/10 text-primary" : "bg-warning/10 text-warning"
                  )}>
                    <Building2 size={24} />
                  </div>
                  <div>
                    <h3 className="font-bold text-foreground leading-tight">{branch.BRANCH_NAME}</h3>
                    <p className="text-xs font-mono text-secondary-foreground">{branch.BRANCH_CODE}</p>
                  </div>
                </div>
                <div className={cn(
                  "rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider",
                  branch.BRANCH_TYPE === 'STORE' ? "bg-primary/10 text-primary" : "bg-warning/10 text-warning"
                )}>
                  {branch.BRANCH_TYPE}
                </div>
              </div>

              <div className="mt-6 space-y-3 border-t border-border/50 pt-4">
                <div className="flex items-start gap-2.5 text-sm text-secondary-foreground">
                  <MapPin size={16} className="mt-0.5 shrink-0 text-primary" />
                  <span className="line-clamp-2">{branch.ADDRESS}</span>
                </div>
                {branch.PHONE && (
                  <div className="flex items-center gap-2.5 text-sm text-secondary-foreground">
                    <Phone size={16} className="shrink-0 text-primary" />
                    <span>{branch.PHONE}</span>
                  </div>
                )}
              </div>

              <div className="mt-5 flex items-center justify-between gap-2 pt-2">
                <button className="flex-1 rounded-lg border border-border py-2 text-xs font-semibold hover:bg-accent transition-colors">
                  Xem chi tiết
                </button>
                <button className="rounded-lg border border-border p-2 hover:bg-accent transition-colors">
                  <Settings size={14} className="text-secondary-foreground" />
                </button>
              </div>
            </div>
          ))
        ) : (
          <div className="col-span-full flex flex-col items-center justify-center py-20 text-secondary-foreground">
            <Building2 size={48} className="mb-4 opacity-20" />
            <p>Không tìm thấy chi nhánh nào phù hợp.</p>
          </div>
        )}
      </div>
    </div>
  );
}
