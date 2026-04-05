import React, { useState, useEffect } from "react";
import { X, AlertTriangle, RefreshCw } from "lucide-react";
import { cn } from "@/lib/utils";

interface LowStockDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  branchId?: string | number;
}

interface LowStockItem {
  BRANCH_ID: number;
  BRANCH_NAME: string;
  BOOK_ID: number;
  TITLE: string;
  QUANTITY_AVAILABLE: number;
  LOW_STOCK_THRESHOLD: number;
}

export function LowStockDrawer({ isOpen, onClose, branchId }: LowStockDrawerProps) {
  const [data, setData] = useState<LowStockItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      fetchLowStock();
    }
  }, [isOpen, branchId]);

  const fetchLowStock = async () => {
    setLoading(true);
    setError(null);
    try {
      const bId = branchId === "ALL" ? "" : branchId || "";
      const res = await fetch(`/api/inventory/low-stock?branchId=${bId}`);
      const json = await res.json();
      if (json.success) {
        setData(json.data);
      } else {
        setError(json.error || "Không thể lấy dữ liệu từ Procedure");
      }
    } catch (err) {
      setError("Lỗi kết nối đến server");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <div 
        className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm transition-opacity"
        onClick={onClose}
      />
      
      <div className="fixed inset-y-0 right-0 z-50 w-full max-w-2xl bg-white shadow-2xl transition-transform flex flex-col">
        <div className="flex items-center justify-between border-b border-border p-6 bg-rose-50/50">
          <div className="flex items-center gap-3 text-rose-600">
            <AlertTriangle size={24} className="animate-pulse" />
            <div>
              <h2 className="text-lg font-bold">Mô phỏng Procedure Cảnh báo kho</h2>
              <p className="text-sm font-medium text-rose-600/70">Kết quả trực tiếp từ sp_print_low_stock_inventory</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="rounded-full p-2 text-rose-600 hover:bg-rose-100 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 bg-slate-50">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold text-foreground">
              {branchId && branchId !== "ALL" ? `Chi nhánh ID: ${branchId}` : "Toàn bộ hệ thống"}
            </h3>
            <button 
              onClick={fetchLowStock}
              disabled={loading}
              className="flex items-center gap-2 rounded-md bg-white px-3 py-1.5 text-sm font-medium border border-border hover:bg-accent transition-colors disabled:opacity-50"
            >
              <RefreshCw size={14} className={cn(loading && "animate-spin")} />
              Tải lại
            </button>
          </div>

          {error ? (
            <div className="rounded-lg bg-rose-50 p-4 text-sm text-rose-600 border border-rose-200">
              {error}
            </div>
          ) : loading ? (
            <div className="flex flex-col gap-3">
              {[1, 2, 3, 4].map(i => (
                <div key={i} className="h-20 w-full rounded-lg bg-border/50 animate-pulse"></div>
              ))}
            </div>
          ) : data.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-secondary-foreground">
              <AlertTriangle size={48} className="mb-4 opacity-20" />
              <p>Không có sách nào đang sắp hết hàng (Dưới ngưỡng an toàn)</p>
            </div>
          ) : (
            <div className="space-y-3">
              {data.map((item, idx) => (
                <div key={idx} className="flex flex-col sm:flex-row gap-4 p-4 bg-white rounded-lg border border-border shadow-sm hover:border-rose-300 hover:shadow-md transition-all">
                  <div className="flex-1">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-rose-500 bg-rose-50 px-2 py-0.5 rounded-full mb-2 inline-block">
                      {item.BRANCH_NAME}
                    </span>
                    <h4 className="font-bold text-foreground line-clamp-2">{item.TITLE}</h4>
                    <p className="text-xs text-secondary-foreground mt-1 font-mono">Book ID: {item.BOOK_ID}</p>
                  </div>
                  <div className="flex gap-4 sm:flex-col sm:gap-2 justify-center sm:justify-start items-center sm:items-end min-w-[100px] border-l border-border pl-4">
                    <div className="text-center sm:text-right">
                      <span className="block text-xs font-semibold text-secondary-foreground">Hiện có</span>
                      <span className="text-lg font-black text-rose-600">{item.QUANTITY_AVAILABLE}</span>
                    </div>
                    <div className="h-8 w-px bg-border sm:hidden"></div>
                    <div className="text-center sm:text-right">
                      <span className="block text-xs font-semibold text-secondary-foreground">Ngưỡng</span>
                      <span className="text-sm font-bold text-amber-600">{item.LOW_STOCK_THRESHOLD}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
        
        <div className="border-t border-border p-4 bg-white flex justify-end">
          <button 
            onClick={onClose}
            className="rounded-lg bg-secondary px-6 py-2 text-sm font-medium text-secondary-foreground hover:bg-secondary/80 transition-colors"
          >
            Đóng
          </button>
        </div>
      </div>
    </>
  );
}
