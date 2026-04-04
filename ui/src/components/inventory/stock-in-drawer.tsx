"use client";

import React, { useState, useEffect } from "react";
import { 
  X, 
  PackagePlus, 
  CheckCircle2, 
  BookOpen, 
  MapPin, 
  RefreshCw,
  Plus,
  Minus
} from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { useBranch } from "@/context/branch-context";

interface Book {
  BOOK_ID: number;
  TITLE: string;
  ISBN: string;
}

interface Branch {
  BRANCH_ID: number;
  BRANCH_NAME: string;
}

interface StockInDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialBookId?: number;
  initialBranchId?: number;
}

export function StockInDrawer({ 
  isOpen, 
  onClose, 
  onSuccess, 
  initialBookId,
  initialBranchId 
}: StockInDrawerProps) {
  const { currentUser } = useBranch();
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);
  const [books, setBooks] = useState<Book[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  
  const [formData, setFormData] = useState({
    book_id: "",
    branch_id: "",
    quantity: 1,
    notes: ""
  });

  useEffect(() => {
    if (isOpen) {
      fetchBaseData();
      setFormData(prev => ({
        ...prev,
        book_id: initialBookId?.toString() || "",
        branch_id: initialBranchId?.toString() || "",
        quantity: 1,
        notes: ""
      }));
    }
  }, [isOpen, initialBookId, initialBranchId]);

  const fetchBaseData = async () => {
    setFetching(true);
    try {
      const [bookRes, branchRes] = await Promise.all([
        fetch("/api/catalog?limit=100"),
        fetch("/api/branches")
      ]);
      const bookData = await bookRes.json();
      const branchData = await branchRes.json();
      
      if (bookData.success) setBooks(bookData.data);
      if (branchData.success) setBranches(branchData.data);
    } catch (e) {
      toast.error("Không thể tải danh mục dữ liệu.");
    } finally {
      setFetching(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.book_id || !formData.branch_id || formData.quantity <= 0) {
      toast.error("Vui lòng nhập đầy đủ thông tin hợp lệ.");
      return;
    }

    if (!currentUser?.staffId) {
      toast.error("Bạn cần có tài khoản nhân viên để thực hiện thao tác này.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/inventory/stock-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          book_id: parseInt(formData.book_id),
          branch_id: parseInt(formData.branch_id),
          quantity: parseInt(formData.quantity.toString()),
          notes: formData.notes,
          staff_id: currentUser?.staffId ? parseInt(currentUser.staffId) : null
        })
      });

      const data = await res.json();
      if (data.success) {
        toast.success(data.message || "Nhập hàng thành công!");
        onSuccess();
        onClose();
      } else {
        toast.error(data.message || "Lỗi khi nhập hàng.");
      }
    } catch {
      toast.error("Lỗi kết nối máy chủ.");
    } finally {
      setLoading(false);
    }
  };

  const adjustQty = (amount: number) => {
    setFormData(prev => ({
      ...prev,
      quantity: Math.max(1, prev.quantity + amount)
    }));
  };

  return (
    <>
      {/* Overlay */}
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
        <div className="w-full max-w-2xl bg-white rounded-xl shadow-xl animate-in zoom-in-95 duration-300 my-auto flex flex-col max-h-[85vh]">
          {/* Header */}
          <div className="flex items-center justify-between border-b border-border p-6">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-emerald-500/10 p-2 text-emerald-600 ring-1 ring-emerald-500/20">
                <PackagePlus size={24} />
              </div>
              <div>
                <h2 className="text-xl font-bold text-foreground">Nhập kho DigiBook</h2>
                <p className="text-xs text-secondary-foreground">Procurement & Distribution</p>
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

          {/* Form Content */}
          <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
            
            {/* Book Selection */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-secondary-foreground">
                <BookOpen size={14} />
                <label className="text-[11px] font-black uppercase tracking-tighter">Sách cần nhập</label>
              </div>
              <select 
                value={formData.book_id}
                onChange={(e) => setFormData(prev => ({ ...prev, book_id: e.target.value }))}
                className="w-full rounded-2xl border border-border bg-accent/10 px-5 py-4 text-sm font-semibold outline-none focus:ring-2 focus:ring-emerald-500/20 focus:bg-white transition-all shadow-sm"
                required
                disabled={fetching}
              >
                <option value="">-- Chọn đầu sách trong danh mục --</option>
                {books.map(book => (
                  <option key={book.BOOK_ID} value={book.BOOK_ID}>{book.TITLE} ({book.ISBN})</option>
                ))}
              </select>
            </div>

            {/* Branch Selection */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-secondary-foreground">
                <MapPin size={14} />
                <label className="text-[11px] font-black uppercase tracking-tighter">Chi nhánh tiếp nhận</label>
              </div>
              <select 
                value={formData.branch_id}
                onChange={(e) => setFormData(prev => ({ ...prev, branch_id: e.target.value }))}
                className="w-full rounded-2xl border border-border bg-accent/10 px-5 py-4 text-sm font-semibold outline-none focus:ring-2 focus:ring-emerald-500/20 focus:bg-white transition-all shadow-sm"
                required
                disabled={fetching}
              >
                <option value="">-- Điểm đến của hàng hóa --</option>
                {branches.map(b => (
                  <option key={b.BRANCH_ID} value={b.BRANCH_ID}>{b.BRANCH_NAME}</option>
                ))}
              </select>
            </div>

            {/* Quantity Control */}
            <div className="space-y-3">
              <label className="text-[11px] font-black uppercase tracking-tighter text-secondary-foreground">Số lượng nhập kho</label>
              <div className="flex items-center gap-4">
                <button 
                  type="button"
                  onClick={() => adjustQty(-10)}
                  className="h-12 w-12 flex items-center justify-center rounded-xl bg-accent/20 hover:bg-rose-50 hover:text-rose-600 transition-colors border border-border shadow-sm"
                >
                  <Minus size={18} strokeWidth={3} />
                </button>
                <input 
                  type="number" 
                  min="1"
                  value={formData.quantity}
                  onChange={(e) => setFormData(prev => ({ ...prev, quantity: parseInt(e.target.value) || 1 }))}
                  className="flex-1 rounded-2xl border-2 border-border bg-white px-4 py-4 text-center text-2xl font-black text-foreground outline-none focus:border-emerald-500 transition-all"
                  required
                />
                <button 
                  type="button"
                  onClick={() => adjustQty(10)}
                  className="h-12 w-12 flex items-center justify-center rounded-xl bg-accent/20 hover:bg-emerald-50 hover:text-emerald-600 transition-colors border border-border shadow-sm"
                >
                  <Plus size={18} strokeWidth={3} />
                </button>
              </div>
              <p className="text-[10px] text-center text-secondary-foreground font-medium italic italic">Vui lòng kiểm tra kỹ số lượng thực tế khi bàn giao.</p>
            </div>

            {/* Notes */}
            <div className="space-y-3">
              <label className="text-[11px] font-black uppercase tracking-tighter text-secondary-foreground">Ghi chú nghiệp vụ</label>
              <textarea 
                rows={4}
                value={formData.notes}
                onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Ví dụ: Nhập hàng đợt 1 tháng 4, bổ sung sách mới..."
                className="w-full rounded-2xl border border-border bg-accent/10 px-5 py-4 text-sm font-medium outline-none focus:ring-2 focus:ring-emerald-500/20 focus:bg-white transition-all resize-none shadow-sm"
              />
            </div>
          </form>

          {/* Footer Action */}
          <div className="border-t border-border p-6 bg-accent/20">
            <button 
              onClick={handleSubmit}
              disabled={loading || fetching || !formData.book_id || !formData.branch_id || !currentUser?.staffId}
              className={cn(
                "flex w-full items-center justify-center gap-2 items-center rounded-lg px-4 py-2.5 text-sm font-semibold text-white transition-all",
                (loading || fetching || !formData.book_id || !formData.branch_id || !currentUser?.staffId) 
                  ? "bg-slate-300 cursor-not-allowed" 
                  : "bg-emerald-600 hover:bg-emerald-700"
              )}
            >
              {loading ? (
                <>
                  <RefreshCw className="animate-spin" size={16} />
                  <span>Đang xử lý...</span>
                </>
              ) : (
                <>
                  <CheckCircle2 size={16} />
                  <span>Xác nhận nhập kho</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
