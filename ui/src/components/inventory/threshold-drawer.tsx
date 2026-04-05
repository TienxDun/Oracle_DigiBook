import React, { useState } from "react";
import { X, Settings, Database, Save, CheckCircle2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

interface ThresholdDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  bookData: any;
  onSuccess: () => void;
}

export function ThresholdDrawer({ isOpen, onClose, bookData, onSuccess }: ThresholdDrawerProps) {
  const [loading, setLoading] = useState(false);
  const [thresholds, setThresholds] = useState<Record<string, number>>({});
  const [isInitialized, setIsInitialized] = useState(false);

  // Khởi tạo các giá trị ngưỡng từ dữ liệu của sách
  if (isOpen && !isInitialized && bookData?.BRANCHES) {
    const initialValues: Record<string, number> = {};
    Object.entries(bookData.BRANCHES).forEach(([id, data]: [string, any]) => {
      initialValues[id] = data.threshold || 10;
    });
    setThresholds(initialValues);
    setIsInitialized(true);
  }

  const handleClose = () => {
    setIsInitialized(false);
    onClose();
  };

  const handleUpdate = async (branchId: string | "ALL") => {
    setLoading(true);
    try {
      const val = branchId === "ALL" 
        ? Object.values(thresholds)[0] || 10 // Dùng giá trị đầu tiên làm chuẩn cho "Tất cả"
        : thresholds[branchId];

      const res = await fetch("/api/inventory/threshold", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          branchId,
          bookId: bookData.ID,
          threshold: val
        })
      });

      const json = await res.json();
      if (json.success) {
        toast.success(json.message || "Đã cập nhật ngưỡng tồn kho.");
        onSuccess();
        if (branchId === "ALL") handleClose();
      } else {
        toast.error(json.error || "Lỗi cập nhật");
      }
    } catch (err) {
      toast.error("Lỗi kết nối server");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <div 
        className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm transition-opacity"
        onClick={handleClose}
      />
      
      <div className="fixed inset-y-0 right-0 z-[60] w-full max-w-lg bg-white shadow-2xl transition-transform flex flex-col animate-in slide-in-from-right duration-300">
        <div className="flex items-center justify-between border-b border-border p-6 bg-slate-50/80">
          <div className="flex items-center gap-3 text-indigo-600">
            <div className="p-2 bg-indigo-100 rounded-lg">
              <Settings size={20} />
            </div>
            <div>
              <h2 className="text-lg font-bold">Cấu hình Ngưỡng cảnh báo</h2>
              <p className="text-[11px] font-bold text-slate-500 uppercase tracking-tight line-clamp-1">{bookData.TITLE}</p>
            </div>
          </div>
          <button 
            onClick={handleClose}
            className="rounded-full p-2 text-slate-400 hover:bg-slate-100 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-8 bg-slate-50/30">
          {/* Section: Bulk Update */}
          <div className="p-5 bg-indigo-600 text-white rounded-2xl shadow-lg shadow-indigo-200">
            <h3 className="text-sm font-bold mb-2 flex items-center gap-2">
              <CheckCircle2 size={16} />
              Cập nhật nhanh Toàn hệ thống
            </h3>
            <p className="text-[11px] text-indigo-100 mb-4 opacity-80 font-medium">Áp dụng một ngưỡng duy nhất cho tất cả chi nhánh đang quản lý đầu sách này.</p>
            <div className="flex gap-2">
              <input 
                type="number"
                min="0"
                className="flex-1 rounded-xl border-none bg-indigo-700/50 px-4 py-2.5 text-sm text-white placeholder:text-indigo-300 focus:ring-2 focus:ring-white outline-none font-bold"
                placeholder="Nhập ngưỡng chung..."
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleUpdate("ALL");
                }}
                onChange={(e) => {
                  const val = parseInt(e.target.value);
                  if (!isNaN(val)) {
                    const newThresholds = { ...thresholds };
                    Object.keys(newThresholds).forEach(k => newThresholds[k] = val);
                    setThresholds(newThresholds);
                  }
                }}
              />
              <button 
                onClick={() => handleUpdate("ALL")}
                disabled={loading}
                className="bg-white text-indigo-600 px-5 py-2.5 rounded-xl text-sm font-black hover:bg-indigo-50 transition-all disabled:opacity-50 flex items-center gap-2"
              >
                <Save size={16} />
                Lưu
              </button>
            </div>
          </div>

          {/* Section: Individual Branch Update */}
          <div className="space-y-4">
            <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest flex items-center gap-2 pl-1">
              <Database size={14} />
              Chi tiết theo chi nhánh ({Object.keys(bookData.BRANCHES || {}).length})
            </h3>
            
            <div className="grid gap-3">
              {bookData.BRANCHES && Object.entries(bookData.BRANCHES).map(([id, data]: [string, any]) => (
                <div key={id} className="flex items-center justify-between p-4 bg-white border border-slate-100 rounded-2xl shadow-sm hover:border-indigo-200 hover:shadow-md transition-all group">
                  <div className="flex-1 pr-4">
                    <h4 className="text-sm font-bold text-slate-800 group-hover:text-indigo-600 transition-colors uppercase text-[12px]">{data.name}</h4>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[10px] font-bold text-slate-400">HIỆN CÓ:</span>
                      <span className={cn(
                        "text-xs font-black",
                        data.quantity === 0 ? "text-rose-500" : data.isLow ? "text-amber-500" : "text-emerald-500"
                      )}>
                        {data.quantity} cuốn
                      </span>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-4 border-l border-slate-50 pl-4">
                    <div className="flex flex-col items-end">
                      <span className="text-[9px] uppercase font-black text-slate-400 mb-0.5 tracking-tighter">Ngưỡng báo động</span>
                      <input 
                        type="number"
                        min="0"
                        value={thresholds[id] || 0}
                        onChange={(e) => setThresholds({ ...thresholds, [id]: parseInt(e.target.value) || 0 })}
                        className="w-16 text-right font-black text-slate-700 bg-transparent border-none focus:ring-0 focus:text-indigo-600 outline-none p-0 text-base"
                      />
                    </div>
                    <button 
                      onClick={() => handleUpdate(id)}
                      disabled={loading}
                      className="p-2.5 text-slate-300 hover:text-indigo-600 hover:bg-indigo-50 rounded-xl transition-all disabled:opacity-50"
                      title="Lưu chi nhánh này"
                    >
                      <Save size={20} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="p-6 border-t border-border bg-white flex justify-between items-center">
          <p className="text-[10px] font-medium text-slate-400 max-w-[200px]">
            * Nhấn <span className="font-bold">Lưu</span> (biểu tượng đĩa mềm) để áp dụng cho từng chi nhánh cụ thể.
          </p>
          <button 
            onClick={handleClose}
            className="px-6 py-2 rounded-xl text-sm font-black text-slate-500 hover:bg-slate-100 transition-all border border-slate-100"
          >
            Đóng bảng
          </button>
        </div>
      </div>
    </>
  );
}
