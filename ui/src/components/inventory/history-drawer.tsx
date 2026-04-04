"use client";

import React, { useState, useEffect } from "react";
import { 
  X, 
  Clock, 
  ArrowUpRight, 
  ArrowDownLeft, 
  RefreshCw,
  BookOpen,
  MapPin
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";

const HISTORY_PAGE_SIZE = 100;

interface Transaction {
  TXN_ID: number;
  TXN_TYPE: string;
  QUANTITY: number;
  REFERENCE_TYPE: string;
  NOTES: string;
  FORMATTED_DATE: string;
  BOOK_TITLE: string;
  BRANCH_NAME: string;
}

interface HistoryDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  branchId?: string;
}

export function HistoryDrawer({ isOpen, onClose, branchId }: HistoryDrawerProps) {
  const [loading, setLoading] = useState(true);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    if (isOpen) {
      setPage(1);
      // Call fetch directly with page number instead of relying on state
      const fetchInitial = async () => {
        setLoading(true);
        try {
          const url = branchId 
            ? `/api/inventory/transactions?branch_id=${branchId}&limit=${HISTORY_PAGE_SIZE}&offset=0` 
            : `/api/inventory/transactions?limit=${HISTORY_PAGE_SIZE}&offset=0`;
          const res = await fetch(url);
          const data = await res.json();
          if (data.success) {
            setTransactions(data.data);
            setHasMore(data.data.length === HISTORY_PAGE_SIZE);
          }
        } catch {
          console.error("Failed to fetch history");
        } finally {
          setLoading(false);
        }
      };
      fetchInitial();
    }
  }, [isOpen, branchId]);

  const loadMore = async () => {
    if (loading || !hasMore) return;
    
    const nextPageNum = page + 1;
    setPage(nextPageNum);
    
    // Calculate offset directly without relying on state update
    const offset = (nextPageNum - 1) * HISTORY_PAGE_SIZE;
    setLoading(true);
    try {
      const url = branchId 
        ? `/api/inventory/transactions?branch_id=${branchId}&limit=${HISTORY_PAGE_SIZE}&offset=${offset}` 
        : `/api/inventory/transactions?limit=${HISTORY_PAGE_SIZE}&offset=${offset}`;
      const res = await fetch(url);
      const data = await res.json();
      if (data.success) {
        setTransactions(prev => [...prev, ...data.data]);
        setHasMore(data.data.length === HISTORY_PAGE_SIZE);
      }
    } catch {
      console.error("Failed to load more history");
    } finally {
      setLoading(false);
    }
  };

  const getTypeStyle = (type: string) => {
    switch (type) {
      case "IN": case "TRANSFER_IN": return "bg-emerald-50 text-emerald-600 border-emerald-100";
      case "OUT": case "TRANSFER_OUT": return "bg-rose-50 text-rose-600 border-rose-100";
      case "ADJUST": return "bg-amber-50 text-amber-600 border-amber-100";
      default: return "bg-slate-50 text-slate-600 border-slate-100";
    }
  };

  const getTypeIcon = (type: string) => {
    if (type.includes("IN")) return <ArrowDownLeft size={14} />;
    if (type.includes("OUT")) return <ArrowUpRight size={14} />;
    return <RefreshCw size={14} />;
  };

  return (
    <>
      {/* Backdrop */}
      <div 
        className={cn(
          "fixed inset-0 z-40 bg-black/30 backdrop-blur-sm transition-opacity duration-300",
          isOpen ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
        onClick={onClose}
      />

      {/* Modal */}
      <div 
        className={cn(
          "fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto transition-opacity duration-300",
          isOpen ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
      >
        <div className="w-full max-w-3xl bg-white rounded-xl shadow-xl animate-in zoom-in-95 duration-300 my-auto flex flex-col max-h-[90vh]">
          {/* Header */}
          <div className="flex items-center justify-between border-b border-border p-6">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-primary/10 p-2 text-primary">
                <Clock size={24} />
              </div>
              <div>
                <h2 className="text-xl font-bold text-foreground">Lịch sử giao dịch</h2>
                <p className="text-sm text-secondary-foreground">
                  {transactions.length > 0 ? `${transactions.length} giao dịch được tải` : "Đang tải..."}
                </p>
              </div>
            </div>
            <button 
              onClick={onClose}
              title="Đóng"
              aria-label="Đóng"
              className="rounded-full p-2 text-secondary-foreground hover:bg-accent hover:text-foreground"
            >
              <X size={20} />
            </button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-6">
            {loading ? (
              <div className="space-y-6">
                {[1, 2, 3, 4, 5].map(i => (
                  <div key={i} className="flex gap-4">
                    <Skeleton className="h-10 w-10 shrink-0 rounded-lg" />
                    <div className="flex-1 space-y-2">
                      <Skeleton className="h-4 w-3/4" />
                      <Skeleton className="h-3 w-1/2" />
                    </div>
                  </div>
                ))}
              </div>
            ) : transactions.length > 0 ? (
              <div className="space-y-6">
                {transactions.map((txn) => (
                  <div key={txn.TXN_ID} className="group relative flex gap-4 transition-all">
                    {/* Time track */}
                    <div className="absolute left-[19px] top-10 bottom-[-24px] w-[2px] bg-border last:hidden" />
                    
                    <div className={cn(
                      "z-10 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border transition-all",
                      getTypeStyle(txn.TXN_TYPE)
                    )}>
                      {getTypeIcon(txn.TXN_TYPE)}
                    </div>

                    <div className="flex-1 space-y-1 pb-6">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-semibold text-secondary-foreground tracking-wider uppercase">
                          {txn.FORMATTED_DATE}
                        </span>
                        <span className={cn(
                          "text-sm font-bold",
                          txn.QUANTITY > 0 ? "text-emerald-600" : "text-rose-600"
                        )}>
                          {txn.QUANTITY > 0 ? "+" : ""}{txn.QUANTITY}
                        </span>
                      </div>
                      
                      <div className="flex flex-col gap-0.5">
                        <div className="flex items-center gap-2 text-sm font-bold text-foreground group-hover:text-primary transition-colors">
                          <BookOpen size={14} className="text-secondary-foreground" />
                          {txn.BOOK_TITLE}
                        </div>
                        <div className="flex items-center gap-2 text-xs font-medium text-secondary-foreground">
                          <MapPin size={12} />
                          {txn.BRANCH_NAME}
                        </div>
                      </div>

                      {txn.NOTES && (
                        <p className="mt-2 text-xs italic text-secondary-foreground bg-accent/30 p-2 rounded-md border border-border/50">
                          &quot;{txn.NOTES}&quot;
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex h-full flex-col items-center justify-center text-center py-20">
                <div className="mb-4 rounded-full bg-accent p-6 text-secondary-foreground opacity-20">
                  <Clock size={48} />
                </div>
                <h3 className="text-lg font-bold text-foreground opacity-40">Chưa có giao dịch</h3>
                <p className="text-sm text-secondary-foreground opacity-40">Các hoạt động nhập, xuất, điều chuyển sẽ hiển thị tại đây.</p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="border-t border-border p-6 bg-accent/20 flex gap-3">
            <button 
              onClick={async () => {
                setPage(1);
                setLoading(true);
                try {
                  const url = branchId 
                    ? `/api/inventory/transactions?branch_id=${branchId}&limit=${HISTORY_PAGE_SIZE}&offset=0` 
                    : `/api/inventory/transactions?limit=${HISTORY_PAGE_SIZE}&offset=0`;
                  const res = await fetch(url);
                  const data = await res.json();
                  if (data.success) {
                    setTransactions(data.data);
                    setHasMore(data.data.length === HISTORY_PAGE_SIZE);
                  }
                } catch {
                  console.error("Failed to refresh history");
                } finally {
                  setLoading(false);
                }
              }}
              disabled={loading}
              className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-border bg-white px-4 py-2.5 text-sm font-semibold text-foreground hover:bg-accent transition-all disabled:opacity-50"
            >
              <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
              Làm mới
            </button>
            {transactions.length > 0 && (
              <button 
                onClick={loadMore}
                disabled={loading || !hasMore}
                className="flex-1 flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-hover transition-all disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <RefreshCw size={16} className="animate-spin" />
                    Đang tải...
                  </>
                ) : hasMore ? (
                  <>
                    Xem thêm ({HISTORY_PAGE_SIZE} mục)
                  </>
                ) : (
                  "Đã hết dữ liệu"
                )}
              </button>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
