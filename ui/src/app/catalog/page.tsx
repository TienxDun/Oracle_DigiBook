"use client";

import React, { useState, useEffect } from "react";
import { 
  Plus, 
  Filter, 
  Search,
  ArrowUpDown,
  Download,
  Edit2,
  ShoppingBag,
  Package
} from "lucide-react";
import { cn } from "@/lib/utils";
import { BookDrawer } from "@/components/catalog/book-drawer";
import { CategoryManager } from "@/components/catalog/category-manager";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";
import type { Book } from "@/types/database";

type Category = {
  CATEGORY_ID: number;
  CATEGORY_NAME: string;
  PARENT_ID: number | null;
  DESCRIPTION: string | null;
  IMAGE_URL: string | null;
  DISPLAY_ORDER: number;
  IS_ACTIVE: 0 | 1;
  CHILDREN?: Category[];
};

export default function CatalogPage() {
  const [books, setBooks] = useState<Book[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBooks, setSelectedBooks] = useState<number[]>([]);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingBook, setEditingBook] = useState<Book | null>(null);
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoryTree, setCategoryTree] = useState<Category[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [selectedSort, setSelectedSort] = useState<string>("newest");
  const [selectedStatus, setSelectedStatus] = useState<string>("all"); // all | 1 | 0
  const [selectedStock, setSelectedStock] = useState<string>("all"); // all | in_stock | out_of_stock | low_stock
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total: 0, totalPages: 1 });
  const limit = 10;

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    fetchBooks();
  }, [page, search, selectedCategory, selectedSort, selectedStatus, selectedStock]);

  const fetchCategories = async () => {
    try {
      const res = await fetch("/api/categories");
      const data = await res.json();
      if (data.success) {
        setCategories(data.data || []);
        setCategoryTree(data.tree || []);
      }
    } catch {
      console.error("Failed to fetch categories");
    }
  };

  const fetchBooks = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: String(limit),
        search: search,
        sort: selectedSort,
      });
      if (selectedCategory !== "all") params.set("category_id", selectedCategory);
      if (selectedStatus !== "all") params.set("status", selectedStatus);
      if (selectedStock !== "all") params.set("stock_status", selectedStock);

      const res = await fetch(`/api/catalog?${params.toString()}`);
      const data = await res.json();
      if (data.success) {
        setBooks(data.data);
        setPagination({ total: data.pagination.total, totalPages: data.pagination.totalPages });
      }
    } catch (error) {
      console.error("Failed to fetch books:", error);
    } finally {
      setLoading(false);
    }
  };

  const toggleSelectAll = () => {
    if (selectedBooks.length === books.length) {
      setSelectedBooks([]);
    } else {
      setSelectedBooks(books.map(b => b.BOOK_ID));
    }
  };

  const toggleSelect = (id: number) => {
    if (selectedBooks.includes(id)) {
      setSelectedBooks(selectedBooks.filter(item => item !== id));
    } else {
      setSelectedBooks([...selectedBooks, id]);
    }
  };

  const handleCreate = () => {
    setEditingBook(null);
    setIsDrawerOpen(true);
  };

  const handleEdit = (book: Book) => {
    setEditingBook(book);
    setIsDrawerOpen(true);
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(e.target.value);
    setPage(1); // Reset to first page on search
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Bạn có chắc chắn muốn ngừng kinh doanh đầu sách này?")) return;
    
    try {
      const res = await fetch(`/api/catalog/${id}`, { method: "DELETE" });
      const data = await res.json();
      if (data.success) {
        toast.success("Đã cập nhật trạng thái sách");
        fetchBooks();
      }
    } catch {
      toast.error("Lỗi khi xóa sách");
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Danh mục Sách</h1>
          <p className="text-sm text-secondary-foreground">Danh sách toàn bộ đầu sách trong hệ thống DigiBook (Oracle 19c).</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setIsCategoryModalOpen(true)}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <Filter size={16} />
            Quản lý danh mục
          </button>
          <button className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors">
            <Download size={16} />
            Xuất file
          </button>
          <button 
            onClick={handleCreate}
            className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all"
          >
            <Plus size={16} />
            Thêm sách mới
          </button>
        </div>
      </div>

      {/* Bulk Action Bar (Floating) */}
      {selectedBooks.length > 0 && (
        <div className="fixed bottom-8 left-1/2 z-50 flex -translate-x-1/2 items-center gap-4 rounded-full bg-foreground px-6 py-3 text-white shadow-2xl animate-in slide-in-from-bottom-4">
          <span className="text-sm font-medium border-r border-white/20 pr-4">
            Đã chọn <span className="font-bold">{selectedBooks.length}</span> mục
          </span>
          <div className="flex items-center gap-2">
            <button className="rounded-md px-3 py-1.5 text-xs font-semibold hover:bg-white/10">Cập nhật giá</button>
            <button className="rounded-md px-3 py-1.5 text-xs font-semibold hover:bg-white/10">Đổi trạng thái</button>
            <button className="rounded-md px-3 py-1.5 text-xs font-semibold text-error hover:bg-error/10">Xóa</button>
          </div>
          <button 
            onClick={() => setSelectedBooks([])}
            title="Bỏ chọn"
            aria-label="Bỏ chọn tất cả"
            className="ml-2 rounded-full p-1 hover:bg-white/10 transition-colors"
          >
            <Plus size={16} className="rotate-45" />
          </button>
        </div>
      )}

      {/* Filters & Search */}
      <div className="card-shadow rounded-xl border border-border bg-white p-4">
        <div className="flex flex-col gap-4 md:flex-row md:items-center">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
            <input 
              type="text" 
              value={search}
              aria-label="Tìm kiếm sách"
              onChange={handleSearch}
              placeholder="Tìm theo tên sách, ISBN..." 
              className="w-full rounded-lg border border-border bg-accent/30 py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
            />
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {/* Lọc theo danh mục */}
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground pointer-events-none" size={16} />
              <select 
                value={selectedCategory}
                aria-label="Lọc theo danh mục"
                onChange={(e) => {
                  setSelectedCategory(e.target.value);
                  setPage(1);
                }}
                className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
              >
                <option value="all">Tất cả danh mục</option>
                {categories
                  .filter((c) => c.IS_ACTIVE === 1)
                  .map((c) => (
                  <option key={c.CATEGORY_ID} value={c.CATEGORY_ID}>{c.CATEGORY_NAME}</option>
                ))}
              </select>
            </div>

            {/* Lọc theo trạng thái kinh doanh */}
            <div className="relative">
              <ShoppingBag className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground pointer-events-none" size={14} />
              <select 
                value={selectedStatus}
                aria-label="Lọc theo trạng thái kinh doanh"
                onChange={(e) => {
                  setSelectedStatus(e.target.value);
                  setPage(1);
                }}
                className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
              >
                <option value="all">Tất cả trạng thái</option>
                <option value="1">Đang bán</option>
                <option value="0">Ngừng kinh doanh</option>
              </select>
            </div>

            {/* Lọc theo tình trạng kho */}
            <div className="relative">
              <Package className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground pointer-events-none" size={14} />
              <select 
                value={selectedStock}
                aria-label="Lọc theo tình trạng kho"
                onChange={(e) => {
                  setSelectedStock(e.target.value);
                  setPage(1);
                }}
                className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
              >
                <option value="all">Tất cả tình trạng</option>
                <option value="in_stock">Còn hàng</option>
                <option value="out_of_stock">Hết hàng</option>
                <option value="low_stock">Sắp hết hàng</option>
              </select>
            </div>

            {/* Sắp xếp */}
            <div className="relative">
              <ArrowUpDown className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground pointer-events-none" size={14} />
              <select 
                value={selectedSort}
                aria-label="Sắp xếp sách"
                onChange={(e) => setSelectedSort(e.target.value)}
                className="appearance-none rounded-lg border border-border bg-white py-2 pl-9 pr-8 text-sm font-medium outline-none hover:bg-accent transition-all cursor-pointer"
              >
                <option value="newest">Mới nhất</option>
                <option value="oldest">Cũ nhất</option>
                <option value="price_asc">Giá: Thấp đến Cao</option>
                <option value="price_desc">Giá: Cao đến Thấp</option>
                <option value="alphabetical">Tên: A-Z</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Books Table */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">
                  <input 
                    type="checkbox" 
                    aria-label="Chọn tất cả sách"
                    className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer"
                    checked={books.length > 0 && selectedBooks.length === books.length}
                    onChange={toggleSelectAll}
                  />
                </th>
                <th className="px-6 py-4">Thông tin sách</th>
                <th className="px-6 py-4">ISBN</th>
                <th className="px-6 py-4 text-center">Tình trạng</th>
                <th className="px-6 py-4">Trạng thái</th>
                <th className="px-6 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-4 rounded" /></td>
                    <td className="px-6 py-4 space-y-2">
                      <Skeleton className="h-4 w-48" />
                      <Skeleton className="h-3 w-32" />
                    </td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-24" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-12 mx-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-20 rounded-full" /></td>
                    <td className="px-6 py-4 text-right"><Skeleton className="h-8 w-16 ml-auto" /></td>
                  </tr>
                ))
              ) : books.length > 0 ? (
                books.map((book) => (
                  <tr key={book.BOOK_ID} className="group transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4">
                      <input 
                        type="checkbox" 
                        aria-label={`Chọn sách ${book.TITLE}`}
                        className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer"
                        checked={selectedBooks.includes(book.BOOK_ID)}
                        onChange={() => toggleSelect(book.BOOK_ID)}
                      />
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        {book.COVER_URL ? (
                          <img
                            src={book.COVER_URL}
                            alt={book.TITLE}
                            className="h-12 w-9 rounded object-cover"
                          />
                        ) : (
                          <div className="h-12 w-9 rounded bg-accent/50" />
                        )}
                        <div className="flex flex-col">
                          <span className="font-semibold text-foreground group-hover:text-primary transition-colors cursor-pointer" onClick={() => handleEdit(book)}>
                            {book.TITLE}
                          </span>
                          <span className="text-xs text-secondary-foreground">{book.AUTHOR_NAMES || "Không rõ tác giả"}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 font-mono text-xs">{book.ISBN}</td>
                    <td className="px-6 py-4 text-center">
                      <span className={cn(
                        "font-bold",
                        book.STOCK_QUANTITY <= 0 ? "text-error" : book.STOCK_QUANTITY < 50 ? "text-warning" : "text-foreground"
                      )}>
                        {book.STOCK_QUANTITY} cuốn
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className={cn(
                        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold",
                        book.IS_ACTIVE === 1 ? "bg-success/10 text-success" : "bg-error/10 text-error"
                      )}>
                        <div className={cn(
                          "h-1.5 w-1.5 rounded-full",
                          book.IS_ACTIVE === 1 ? "bg-success" : "bg-error"
                        )} />
                        {book.IS_ACTIVE === 1 ? "Đang bán" : "Ngừng kinh doanh"}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button 
                          onClick={() => handleEdit(book)}
                          className="rounded-md p-1.5 text-secondary-foreground hover:bg-primary/10 hover:text-primary transition-all"
                          title="Chỉnh sửa"
                          aria-label={`Chỉnh sửa ${book.TITLE}`}
                        >
                          <Edit2 size={16} />
                        </button>
                        <button 
                          onClick={() => handleDelete(book.BOOK_ID)}
                          className="rounded-md p-1.5 text-secondary-foreground hover:bg-error/10 hover:text-error transition-all"
                          title="Ngừng kinh doanh"
                          aria-label={`Ngừng kinh doanh ${book.TITLE}`}
                        >
                          <Plus size={16} className="rotate-45" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-20 text-center text-secondary-foreground">
                    Không tìm thấy đầu sách nào phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        
        {/* Pagination */}
        <div className="flex items-center justify-between border-t border-border bg-white px-6 py-4 text-sm text-secondary-foreground">
          <span>
            Hiển thị <span className="font-bold text-foreground">{pagination.total === 0 ? 0 : (page - 1) * limit + 1} - {Math.min(page * limit, pagination.total)}</span> trong tổng số <span className="font-bold text-foreground">{pagination.total}</span> sách
          </span>
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1 || loading}
              className="rounded border border-border px-3 py-1 hover:bg-accent disabled:opacity-50 transition-colors"
            >Trước</button>
            {Array.from({ length: Math.min(5, pagination.totalPages) }, (_, i) => {
              // Logic hiển thị trang đơn giản, có thể nâng cấp thêm
              const pageNum = i + 1;
              return (
                <button 
                  key={pageNum}
                  onClick={() => setPage(pageNum)}
                  className={cn(
                    "rounded border px-3 py-1 transition-all",
                    page === pageNum ? "border-primary bg-primary/5 text-primary font-bold" : "border-border hover:bg-accent"
                  )}
                >
                  {pageNum}
                </button>
              );
            })}
            <button 
              onClick={() => setPage(p => Math.min(pagination.totalPages, p + 1))}
              disabled={page === pagination.totalPages || loading}
              className="rounded border border-border px-3 py-1 hover:bg-accent disabled:opacity-50 transition-colors"
            >Sau</button>
          </div>
        </div>
      </div>

      {/* Book Drawer Component */}
      <BookDrawer 
        isOpen={isDrawerOpen} 
        onClose={() => setIsDrawerOpen(false)} 
        onRefresh={fetchBooks}
        book={editingBook}
      />

      {/* Category Manager Modal */}
      <CategoryManager 
        categories={categories}
        onRefresh={fetchCategories}
        isOpen={isCategoryModalOpen}
        onOpen={() => setIsCategoryModalOpen(true)}
        onClose={() => setIsCategoryModalOpen(false)}
      />
    </div>
  );
}
