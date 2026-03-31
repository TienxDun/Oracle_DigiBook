"use client";

import React, { useState, useEffect } from "react";
import { X, Save, Image as ImageIcon, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

interface BookDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onRefresh?: () => void;
  book?: any;
}

export function BookDrawer({ isOpen, onClose, onRefresh, book }: BookDrawerProps) {
  const [loading, setLoading] = useState(false);
  const [categories, setCategories] = useState<any[]>([]);
  const [publishers, setPublishers] = useState<any[]>([]);
  
  // Form State
  const [formData, setFormData] = useState({
    title: "",
    isbn: "",
    price: 0,
    category_id: 0,
    publisher_id: 0,
    publication_year: new Date().getFullYear(),
    page_count: 0,
    language: "vi",
    cover_type: "Bìa mềm",
    description: "",
    is_active: 1
  });

  useEffect(() => {
    if (isOpen) {
      fetchCategories();
      fetchPublishers();
      if (book) {
        setFormData({
          title: book.TITLE || "",
          isbn: book.ISBN || "",
          price: Number(book.PRICE || 0),
          category_id: Number(book.CATEGORY_ID || 0),
          publisher_id: Number(book.PUBLISHER_ID || 0),
          publication_year: Number(book.PUBLICATION_YEAR || new Date().getFullYear()),
          page_count: Number(book.PAGE_COUNT || 0),
          language: book.LANGUAGE || "vi",
          cover_type: book.COVER_TYPE || "Bìa mềm",
          description: book.DESCRIPTION || "",
          is_active: Number(book.IS_ACTIVE ?? 1)
        });
      } else {
        setFormData({ 
          title: "", 
          isbn: "", 
          price: 0, 
          category_id: 0, 
          publisher_id: 0,
          publication_year: new Date().getFullYear(),
          page_count: 0,
          language: "vi",
          cover_type: "Bìa mềm",
          description: "",
          is_active: 1 
        });
      }
    }
  }, [isOpen, book]);

  const fetchCategories = async () => {
    try {
      const res = await fetch("/api/categories");
      const data = await res.json();
      if (data.success) setCategories(data.data);
    } catch (e) {
      console.error("Failed to fetch categories");
    }
  };

  const fetchPublishers = async () => {
    try {
      const res = await fetch("/api/publishers");
      const data = await res.json();
      if (data.success) setPublishers(data.data);
    } catch (e) {
      console.error("Failed to fetch publishers");
    }
  };

  const handleSave = async () => {
    setLoading(true);
    try {
      const url = book ? `/api/catalog/${book.BOOK_ID}` : "/api/catalog";
      const method = book ? "PUT" : "POST";
      
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData)
      });

      const result = await res.json();
      if (result.success) {
        toast.success(book ? "Cập nhật thành công!" : "Đã thêm sách mới!");
        if (onRefresh) onRefresh();
        onClose();
      } else {
        toast.error(result.message || "Có lỗi xảy ra");
      }
    } catch (error) {
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="fixed inset-0 z-50 bg-black/30 backdrop-blur-sm transition-opacity" onClick={onClose} />
      
      <div className="fixed inset-y-0 right-0 z-50 w-full max-w-xl bg-white shadow-2xl animate-in slide-in-from-right duration-300">
        <div className="flex h-full flex-col">
          <div className="flex items-center justify-between border-b border-border px-6 py-4">
            <h2 className="text-xl font-bold text-foreground">
              {book ? "Chỉnh sửa sách" : "Thêm sách mới"}
            </h2>
            <button onClick={onClose} className="rounded-full p-2 text-secondary-foreground hover:bg-accent hover:text-foreground">
              <X size={20} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto px-6 py-6">
            <div className="space-y-6">
              <div className="flex flex-col items-center justify-center rounded-xl border-2 border-dashed border-border bg-accent/30 p-8 text-center transition-all hover:bg-accent/50">
                <div className="mb-4 rounded-full bg-white p-4 text-primary shadow-sm"><ImageIcon size={32} /></div>
                <span className="text-sm font-medium text-foreground">Tải lên ảnh bìa</span>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2 space-y-2">
                  <label className="text-sm font-semibold text-foreground">Tên sách</label>
                  <input 
                    type="text" 
                    value={formData.title}
                    onChange={(e) => setFormData({...formData, title: e.target.value})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                    placeholder="Nhập tên sách..."
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Mã ISBN</label>
                  <input 
                    type="text" 
                    value={formData.isbn}
                    onChange={(e) => setFormData({...formData, isbn: e.target.value})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                    placeholder="978..."
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Giá bán (VND)</label>
                  <input 
                    type="number" 
                    value={formData.price}
                    onChange={(e) => setFormData({...formData, price: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Danh mục</label>
                  <select 
                    value={formData.category_id}
                    onChange={(e) => setFormData({...formData, category_id: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border bg-white px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value={0}>Chọn danh mục</option>
                    {categories.map((c: any) => (
                      <option key={c.CATEGORY_ID} value={c.CATEGORY_ID}>{c.CATEGORY_NAME}</option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Nhà xuất bản</label>
                  <select 
                    value={formData.publisher_id}
                    onChange={(e) => setFormData({...formData, publisher_id: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border bg-white px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value={0}>Chọn nhà xuất bản</option>
                    {publishers.map((p: any) => (
                      <option key={p.PUBLISHER_ID} value={p.PUBLISHER_ID}>{p.PUBLISHER_NAME}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Trạng thái</label>
                  <select 
                    value={formData.is_active}
                    onChange={(e) => setFormData({...formData, is_active: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border bg-white px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value={1}>Đang kinh doanh</option>
                    <option value={0}>Ngừng kinh doanh</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Năm xuất bản</label>
                  <input 
                    type="number" 
                    value={formData.publication_year}
                    onChange={(e) => setFormData({...formData, publication_year: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Số trang</label>
                  <input 
                    type="number" 
                    value={formData.page_count}
                    onChange={(e) => setFormData({...formData, page_count: Number(e.target.value)})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Ngôn ngữ</label>
                  <input 
                    type="text" 
                    value={formData.language}
                    onChange={(e) => setFormData({...formData, language: e.target.value})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-foreground">Loại bìa</label>
                  <input 
                    type="text" 
                    value={formData.cover_type}
                    onChange={(e) => setFormData({...formData, cover_type: e.target.value})}
                    className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-semibold text-foreground">Mô tả sách</label>
                <textarea 
                  rows={4}
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                  className="w-full rounded-lg border border-border px-4 py-2.5 text-sm outline-none focus:ring-1 focus:ring-primary resize-none"
                  placeholder="Nhập giới thiệu ngắn về nội dung sách..."
                />
              </div>
            </div>
          </div>

          <div className="border-t border-border bg-accent/20 px-6 py-4">
            <div className="flex items-center gap-3">
              <button 
                onClick={onClose}
                disabled={loading}
                className="flex-1 rounded-lg border border-border bg-white px-4 py-2.5 text-sm font-semibold text-foreground hover:bg-accent disabled:opacity-50"
              >Hủy bỏ</button>
              <button 
                onClick={handleSave}
                disabled={loading}
                className="flex flex-[2] items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-white shadow-md hover:bg-primary-hover disabled:opacity-50"
              >
                {loading ? <Loader2 className="animate-spin" size={18} /> : <Save size={18} />}
                {book ? "Lưu thay đổi" : "Thêm vào danh mục"}
              </button>
            </div>
          </div>
        </div>
      </div>
    </>

  );
}
