"use client";

import React, { useState, useEffect } from "react";
import { 
  X, 
  ArrowLeftRight, 
  AlertCircle,
  CheckCircle2,
  Package,
  ArrowRight,
  RefreshCw
} from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { useBranch } from "@/context/branch-context";

interface Book {
  BOOK_ID: number;
  TITLE: string;
  ISBN: string;
  PRICE: number;
}

interface Branch {
  BRANCH_ID: number;
  BRANCH_NAME: string;
}

interface TransferDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialBookId?: number;
}

export function TransferDrawer({ isOpen, onClose, onSuccess, initialBookId }: TransferDrawerProps) {
  const { currentUser } = useBranch();
  const [loading, setLoading] = useState(false);
  const [books, setBooks] = useState<Book[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  
  const [formData, setFormData] = useState({
    book_id: initialBookId?.toString() || "",
    from_branch_id: "",
    to_branch_id: "",
    quantity: 1,
    notes: ""
  });

  const [availableQty, setAvailableQty] = useState<number | null>(null);

  useEffect(() => {
    if (isOpen) {
      fetchData();
      if (initialBookId) setFormData(prev => ({ ...prev, book_id: initialBookId.toString() }));
    }
  }, [isOpen, initialBookId]);

  useEffect(() => {
    if (formData.book_id && formData.from_branch_id) {
      fetchStockLevel();
    } else {
      setAvailableQty(null);
    }
  }, [formData.book_id, formData.from_branch_id]);

  const fetchData = async () => {
    try {
      const [bookRes, branchRes] = await Promise.all([
        fetch("/api/catalog?limit=100"),
        fetch("/api/branches")
      ]);
      const bookData = await bookRes.json();
      const branchData = await branchRes.json();
      
      if (bookData.success) setBooks(bookData.data);
      if (branchData.success) setBranches(branchData.data);
    } catch {
      toast.error("Không thể tải dữ liệu điều chuyển");
    }
  };

  const fetchStockLevel = async () => {
    try {
      const res = await fetch(`/api/inventory?book_id=${formData.book_id}&branch_id=${formData.from_branch_id}`);
      const data = await res.json();
      if (data.success && data.data.length > 0) {
        setAvailableQty(data.data[0].QUANTITY_AVAILABLE);
      } else {
        setAvailableQty(0);
      }
    } catch {
      setAvailableQty(0);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.book_id || !formData.from_branch_id || !formData.to_branch_id) {
      toast.error("Vui lòng điền đầy đủ thông tin.");
      return;
    }

    if (!currentUser?.staffId) {
      toast.error("Bạn cần có tài khoản nhân viên để thực hiện điều chuyển kho.");
      return;
    }

    if (formData.from_branch_id === formData.to_branch_id) {
      toast.error("Chi nhánh nguồn và đích phải khác nhau.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/inventory/transfer", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...formData,
          book_id: parseInt(formData.book_id),
          from_branch_id: parseInt(formData.from_branch_id),
          to_branch_id: parseInt(formData.to_branch_id),
          quantity: parseInt(formData.quantity.toString()),
          staff_id: currentUser?.staffId ? parseInt(currentUser.staffId) : null
        })
      });

      const data = await res.json();
      if (data.success) {
        toast.success(data.message || "Điều chuyển kho thành công!");
        onSuccess();
        onClose();
        // Reset form
        setFormData({ book_id: "", from_branch_id: "", to_branch_id: "", quantity: 1, notes: "" });
      } else {
        toast.error(data.message || "Lỗi điều chuyển kho.");
      }
    } catch {
      toast.error("Lỗi kết nối máy chủ.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div 
        className={cn(
          "fixed inset-0 z-40 bg-black/30 backdrop-blur-sm transition-opacity duration-300",
          isOpen ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
        onClick={onClose}
      />

      <div 
        className={cn(
          "fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto transition-opacity duration-300",
          isOpen ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
      >
        <div className="w-full max-w-2xl bg-white rounded-xl shadow-xl animate-in zoom-in-95 duration-300 my-auto flex flex-col max-h-[85vh]">
          <div className="flex items-center justify-between border-b border-border p-6">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-primary/10 p-2 text-primary">
                <ArrowLeftRight size={24} />
              </div>
              <h2 className="text-xl font-bold text-foreground">Điều chuyển kho</h2>
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

          <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Book Selection */}
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-wider text-secondary-foreground">Sách cần điều chuyển</label>
              <select 
                value={formData.book_id}
                onChange={(e) => setFormData(prev => ({ ...prev, book_id: e.target.value }))}
                className="w-full rounded-xl border border-border bg-white px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                title="Chọn sách cần điều chuyển"
                required
              >
                <option value="">-- Chọn sách --</option>
                {books.map(book => (
                  <option key={book.BOOK_ID} value={book.BOOK_ID}>{book.TITLE} ({book.ISBN})</option>
                ))}
              </select>
            </div>

            {/* Transfer Path */}
            <div className="grid grid-cols-[1fr,auto,1fr] items-center gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold uppercase tracking-wider text-secondary-foreground">Từ chi nhánh</label>
                <select 
                  value={formData.from_branch_id}
                  onChange={(e) => setFormData(prev => ({ ...prev, from_branch_id: e.target.value }))}
                  className="w-full rounded-xl border border-border bg-white px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  title="Chọn chi nhánh nguồn"
                  required
                >
                  <option value="">Nguồn</option>
                  {branches.map(b => (
                    <option key={b.BRANCH_ID} value={b.BRANCH_ID}>{b.BRANCH_NAME}</option>
                  ))}
                </select>
              </div>
              
              <div className="mt-6 flex h-8 w-8 items-center justify-center rounded-full bg-accent/50 text-secondary-foreground">
                <ArrowRight size={16} />
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-bold uppercase tracking-wider text-secondary-foreground">Đến chi nhánh</label>
                <select 
                  value={formData.to_branch_id}
                  onChange={(e) => setFormData(prev => ({ ...prev, to_branch_id: e.target.value }))}
                  className="w-full rounded-xl border border-border bg-white px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  title="Chọn chi nhánh đích"
                  required
                >
                  <option value="">Đích</option>
                  {branches.map(b => (
                    <option key={b.BRANCH_ID} value={b.BRANCH_ID}>{b.BRANCH_NAME}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Stock Availability Indicator */}
            {formData.book_id && formData.from_branch_id && (
              <div className={cn(
                "rounded-xl border p-4 transition-all",
                availableQty === null ? "bg-accent/10 border-border" :
                availableQty === 0 ? "bg-rose-50 border-rose-100 text-rose-700" :
                "bg-emerald-50 border-emerald-100 text-emerald-700"
              )}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Package size={16} />
                    <span className="text-sm font-medium">Tồn tại nguồn:</span>
                  </div>
                  <span className="text-lg font-black italic">
                    {availableQty === null ? "..." : availableQty} cuốn
                  </span>
                </div>
              </div>
            )}

            {/* Quantity Input */}
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-wider text-secondary-foreground">Số lượng chuyển</label>
              <input 
                type="number"
                min="1"
                max={availableQty || 9999}
                value={formData.quantity}
                onChange={(e) => setFormData(prev => ({ ...prev, quantity: parseInt(e.target.value) || 0 }))}
                className="w-full rounded-xl border border-border bg-white px-4 py-3 text-sm font-bold outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                title="Nhập số lượng sách cần chuyển"
                placeholder="Số lượng"
                required
              />
              {availableQty !== null && formData.quantity > availableQty && (
                <div className="mt-1 flex items-center gap-1 text-[11px] font-bold text-rose-600 animate-pulse">
                  <AlertCircle size={12} />
                  Vượt quá tồn kho thực tế!
                </div>
              )}
            </div>

            {/* Notes */}
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-wider text-secondary-foreground">Ghi chú (Tùy chọn)</label>
              <textarea 
                rows={3}
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Nhập lý do điều chuyển hoặc ghi chú..."
                className="w-full rounded-xl border border-border bg-white px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-primary/20 transition-all resize-none"
              />
            </div>
          </form>

          <div className="border-t border-border p-6 bg-accent/20">
            <button 
              onClick={handleSubmit}
              disabled={loading || !availableQty || formData.quantity > availableQty || !currentUser?.staffId}
              className={cn(
                "flex w-full items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm font-semibold text-white transition-all",
                (loading || !availableQty || formData.quantity > availableQty || !currentUser?.staffId) ? "bg-slate-300 cursor-not-allowed" : "bg-primary hover:bg-primary-hover"
              )}
            >
              {loading ? (
                <>
                  <RefreshCw className="animate-spin" size={16} />
                  Đang xử lý...
                </>
              ) : (
                <>
                  <CheckCircle2 size={16} />
                  Xác nhận điều chuyển
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
