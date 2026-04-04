"use client";

import React, { useState, useEffect } from "react";
import { X, Send, Trash2, Search, Loader2 } from "lucide-react";
import { toast } from "sonner";

interface Branch {
  BRANCH_ID: number;
  BRANCH_NAME: string;
}

interface Book {
  BOOK_ID: number;
  TITLE: string;
  ISBN: string;
}

interface SelectedItem {
  book_id: number;
  title: string;
  quantity: number;
}

interface TransferModalProps {
  isOpen: boolean;
  onClose: () => void;
  onRefresh?: () => void;
}

export function TransferModal({ isOpen, onClose, onRefresh }: TransferModalProps) {
  const [loading, setLoading] = useState(false);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [books, setBooks] = useState<Book[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  
  // Form State
  const [fromBranchId, setFromBranchId] = useState<number>(0);
  const [toBranchId, setToBranchId] = useState<number>(0);
  const [notes, setNotes] = useState("");
  const [selectedItems, setSelectedItems] = useState<SelectedItem[]>([]);

  useEffect(() => {
    if (isOpen) {
      fetchInitialData();
    }
  }, [isOpen]);

  const fetchInitialData = async () => {
    try {
      const [bRes, cRes] = await Promise.all([
        fetch("/api/branches"),
        fetch("/api/catalog?limit=100")
      ]);
      const bData = await bRes.json();
      const cData = await cRes.json();
      if (bData.success) setBranches(bData.data);
      if (cData.success) setBooks(cData.data);
    } catch {
      toast.error("Không thể tải dữ liệu ban đầu");
    }
  };

  const addItem = (book: Book) => {
    if (selectedItems.find(i => i.book_id === book.BOOK_ID)) return;
    setSelectedItems([...selectedItems, { book_id: book.BOOK_ID, title: book.TITLE, quantity: 1 }]);
  };

  const removeItem = (bookId: number) => {
    setSelectedItems(selectedItems.filter(i => i.book_id !== bookId));
  };

  const updateQty = (bookId: number, qty: number) => {
    setSelectedItems(selectedItems.map(i => i.book_id === bookId ? { ...i, quantity: Math.max(1, qty) } : i));
  };

  const handleSubmit = async () => {
    if (!fromBranchId || !toBranchId || selectedItems.length === 0) {
      toast.error("Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (fromBranchId === toBranchId) {
      toast.error("Chi nhánh nguồn và đích không được trùng nhau");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/transfers", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          from_branch_id: fromBranchId,
          to_branch_id: toBranchId,
          notes,
          items: selectedItems
        })
      });
      const data = await res.json();
      if (data.success) {
        toast.success("Tạo lệnh điều chuyển thành công!");
        if (onRefresh) onRefresh();
        onClose();
      } else {
        toast.error(data.message);
      }
    } catch (e) {
      toast.error("Lỗi kết nối");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 z-50 w-full max-w-3xl bg-white shadow-2xl animate-in slide-in-from-right duration-300">
        <div className="flex h-full flex-col">
          <div className="flex items-center justify-between border-b border-border bg-accent/10 px-6 py-4">
             <h2 className="text-xl font-bold text-foreground">Tạo lệnh điều chuyển mới</h2>
             <button 
               onClick={onClose} 
               className="rounded-full p-2 text-secondary-foreground hover:bg-accent"
               title="Đóng"
               aria-label="Đóng"
             ><X size={20} /></button>
          </div>

          <div className="flex-1 overflow-y-auto px-6 py-6 space-y-8">
             {/* Branch Selection */}
             <div className="grid grid-cols-2 gap-6">
                <div className="space-y-2">
                   <label className="text-sm font-bold uppercase tracking-wider text-secondary-foreground">Từ Chi nhánh</label>
                   <select 
                    value={fromBranchId}
                    onChange={(e) => setFromBranchId(Number(e.target.value))}
                    className="w-full rounded-lg border border-border bg-white px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                    title="Chọn chi nhánh nguồn"
                   >
                     <option value={0}>Chọn nguồn...</option>
                     {branches.map(b => <option key={b.BRANCH_ID} value={b.BRANCH_ID}>{b.BRANCH_NAME}</option>)}
                   </select>
                </div>
                <div className="space-y-2">
                   <label className="text-sm font-bold uppercase tracking-wider text-secondary-foreground">Đến Chi nhánh</label>
                   <select 
                    value={toBranchId}
                    onChange={(e) => setToBranchId(Number(e.target.value))}
                    className="w-full rounded-lg border border-border bg-white px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                    title="Chọn chi nhánh đích"
                   >
                     <option value={0}>Chọn đích...</option>
                     {branches.map(b => <option key={b.BRANCH_ID} value={b.BRANCH_ID}>{b.BRANCH_NAME}</option>)}
                   </select>
                </div>
             </div>

             {/* Item Search & Add */}
             <div className="space-y-4">
                <label className="text-sm font-bold uppercase tracking-wider text-secondary-foreground">Thêm Sản phẩm</label>
                <div className="relative">
                   <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={16} />
                   <input 
                    type="text"
                    placeholder="Tìm sách..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full rounded-lg border border-border bg-accent/20 py-2 pl-10 pr-4 text-sm"
                   />
                </div>
                <div className="max-h-40 overflow-y-auto rounded-lg border border-border divide-y divide-border">
                   {books.filter(b => b.TITLE.toLowerCase().includes(searchTerm.toLowerCase())).map(b => (
                     <div key={b.BOOK_ID} className="flex items-center justify-between p-2 hover:bg-accent/30 text-sm">
                        <span className="font-medium truncate mr-4">{b.TITLE}</span>
                        <button onClick={() => addItem(b)} className="px-3 py-1 rounded bg-primary text-white text-xs font-bold">Thêm</button>
                     </div>
                   ))}
                </div>
             </div>

             {/* Selected Items */}
             <div className="space-y-4">
                <label className="text-sm font-bold uppercase tracking-wider text-secondary-foreground">Danh sách chuyển ({selectedItems.length})</label>
                <div className="rounded-xl border border-border overflow-hidden">
                   <table className="w-full text-sm">
                      <thead className="bg-accent/50 text-xs font-bold uppercase">
                         <tr>
                            <th className="px-4 py-2 text-left">Sản phẩm</th>
                            <th className="px-4 py-2 text-center w-24">Số lượng</th>
                            <th className="px-4 py-2 text-right"></th>
                         </tr>
                      </thead>
                      <tbody className="divide-y divide-border">
                         {selectedItems.map(item => (
                           <tr key={item.book_id}>
                              <td className="px-4 py-3 font-medium">{item.title}</td>
                              <td className="px-4 py-3">
                                 <input 
                                  type="number" 
                                  value={item.quantity}
                                  onChange={(e) => updateQty(item.book_id, Number(e.target.value))}
                                  className="w-full rounded border border-border px-2 py-1 text-center font-bold"
                                  title="Nhập số lượng"
                                  placeholder="Số lượng"
                                 />
                              </td>
                              <td className="px-4 py-3 text-right text-error">
                                 <button 
                                   onClick={() => removeItem(item.book_id)}
                                   title="Xóa sản phẩm khỏi lệnh"
                                   aria-label="Xóa sản phẩm"
                                 ><Trash2 size={16} /></button>
                              </td>
                           </tr>
                         ))}
                      </tbody>
                   </table>
                </div>
             </div>

             <div className="space-y-2">
                <label className="text-sm font-bold uppercase tracking-wider text-secondary-foreground">Ghi chú</label>
                <textarea 
                  rows={3}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full rounded-lg border border-border px-4 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                  placeholder="Nhập ghi chú lệnh điều chuyển..."
                />
             </div>
          </div>

          <div className="border-t border-border bg-accent/20 px-6 py-4">
             <button 
              onClick={handleSubmit}
              disabled={loading}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-primary py-3 text-sm font-bold text-white shadow-md hover:bg-primary-hover disabled:opacity-50"
             >
                {loading ? <Loader2 className="animate-spin" size={18} /> : <Send size={18} />}
                Gửi lệnh Điều chuyển
             </button>
          </div>
        </div>
      </div>
    </>
  );
}
