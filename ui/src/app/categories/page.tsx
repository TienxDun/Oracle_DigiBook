"use client";

import React, { useState, useEffect } from "react";
import { 
  FolderTree, 
  Search,
  Plus,
  RefreshCw,
  ChevronRight,
  ChevronDown,
  LayoutGrid,
  List
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

type Category = {
  CATEGORY_ID: number;
  CATEGORY_NAME: string;
  PARENT_ID: number | null;
  DESCRIPTION: string | null;
  IMAGE_URL: string | null;
  DISPLAY_ORDER: number;
  IS_ACTIVE: 0 | 1;
  CHILDREN: Category[];
};

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [tree, setTree] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [expandedRows, setExpandedRows] = useState<number[]>([]);
  const [viewMode, setViewMode] = useState<"table" | "grid">("table");

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/categories");
      const data = await res.json();
      if (data.success) {
        setCategories(data.data);
        setTree(data.tree);
        // Expand all root nodes by default
        setExpandedRows(data.tree.map((c: any) => c.CATEGORY_ID));
      } else {
        toast.error("Không thể tải danh sách danh mục");
      }
    } catch (error) {
      console.error("Failed to fetch categories:", error);
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  const toggleExpand = (id: number) => {
    setExpandedRows(prev => 
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  const renderCategoryRow = (category: Category, level: number = 0) => {
    const isExpanded = expandedRows.includes(category.CATEGORY_ID);
    const hasChildren = category.CHILDREN && category.CHILDREN.length > 0;

    return (
      <React.Fragment key={category.CATEGORY_ID}>
        <tr className="group transition-colors hover:bg-accent/10">
          <td className="px-6 py-4">
            <div className="flex items-center gap-2" style={{ paddingLeft: `${level * 24}px` }}>
              {hasChildren ? (
                <button 
                  onClick={() => toggleExpand(category.CATEGORY_ID)}
                  className="rounded hover:bg-accent p-0.5 transition-colors"
                >
                  {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                </button>
              ) : (
                <div className="w-5" />
              )}
              <div className="flex h-8 w-8 items-center justify-center rounded bg-primary/10 text-primary">
                <FolderTree size={16} />
              </div>
              <span className="font-semibold text-foreground">{category.CATEGORY_NAME}</span>
            </div>
          </td>
          <td className="px-6 py-4">
            <span className="text-xs text-secondary-foreground line-clamp-1">
              {category.DESCRIPTION || "Không có mô tả"}
            </span>
          </td>
          <td className="px-6 py-4 text-center text-xs font-mono">
            {category.DISPLAY_ORDER}
          </td>
          <td className="px-6 py-4 text-center">
            <div className={cn(
              "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold",
              category.IS_ACTIVE === 1 ? "bg-success/10 text-success" : "bg-secondary/10 text-secondary"
            )}>
              {category.IS_ACTIVE === 1 ? "Đang hoạt động" : "Ẩn"}
            </div>
          </td>
          <td className="px-6 py-4 text-right">
            <button className="text-secondary-foreground hover:text-primary p-2 transition-colors">
              <Plus size={14} className="rotate-45" />
            </button>
          </td>
        </tr>
        {isExpanded && hasChildren && category.CHILDREN.map(child => renderCategoryRow(child, level + 1))}
      </React.Fragment>
    );
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Danh mục Sản phẩm</h1>
          <p className="text-sm text-secondary-foreground">Quản lý cấu trúc phân loại sách trong toàn hệ thống.</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={fetchCategories}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <RefreshCw size={16} className={cn(loading && "animate-spin")} />
            Làm mới
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all">
            <Plus size={16} />
            Thêm danh mục
          </button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
          <input 
            type="text" 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm theo tên danh mục..." 
            className="w-full rounded-lg border border-border bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
          />
        </div>
        <div className="flex items-center gap-2 rounded-lg border border-border bg-white p-1 shadow-sm">
            <button 
                onClick={() => setViewMode("table")}
                className={cn(
                    "flex items-center gap-2 rounded-md px-3 py-1.5 text-xs font-semibold transition-all",
                    viewMode === "table" ? "bg-primary text-white" : "hover:bg-accent text-secondary-foreground"
                )}
            >
                <List size={14} />
                Bảng
            </button>
            <button 
                onClick={() => setViewMode("grid")}
                className={cn(
                    "flex items-center gap-2 rounded-md px-3 py-1.5 text-xs font-semibold transition-all",
                    viewMode === "grid" ? "bg-primary text-white" : "hover:bg-accent text-secondary-foreground"
                )}
            >
                <LayoutGrid size={14} />
                Lưới
            </button>
        </div>
      </div>

      {/* Categories Content */}
      {viewMode === "table" ? (
        <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
                <tr>
                  <th className="px-6 py-4">Tên danh mục</th>
                  <th className="px-6 py-4">Mô tả</th>
                  <th className="px-6 py-4 text-center">Thứ tự</th>
                  <th className="px-6 py-4 text-center">Trạng thái</th>
                  <th className="px-6 py-4 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i}>
                      <td className="px-6 py-4"><Skeleton className="h-6 w-48" /></td>
                      <td className="px-6 py-4"><Skeleton className="h-4 w-64" /></td>
                      <td className="px-6 py-4"><Skeleton className="h-4 w-8 mx-auto" /></td>
                      <td className="px-6 py-4"><Skeleton className="h-6 w-20 rounded-full mx-auto" /></td>
                      <td className="px-6 py-4 text-right"><Skeleton className="h-8 w-8 ml-auto" /></td>
                    </tr>
                  ))
                ) : tree.length > 0 ? (
                  tree.map(root => renderCategoryRow(root))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-6 py-20 text-center text-secondary-foreground">
                      Không tìm thấy danh mục nào phù hợp.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {loading ? (
                Array(8).fill(0).map((_, i) => (
                    <div key={i} className="card-shadow space-y-3 rounded-xl border border-border bg-white p-4">
                        <Skeleton className="h-32 w-full rounded-lg" />
                        <Skeleton className="h-4 w-32" />
                        <Skeleton className="h-3 w-48" />
                    </div>
                ))
            ) : categories.length > 0 ? (
                categories.map(category => (
                    <div key={category.CATEGORY_ID} className="card-shadow group relative flex flex-col items-center rounded-xl border border-border bg-white p-6 text-center transition-all hover:border-primary/50 hover:shadow-lg">
                        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                            <FolderTree size={32} />
                        </div>
                        <h3 className="font-bold text-foreground">{category.CATEGORY_NAME}</h3>
                        <p className="mt-2 text-xs text-secondary-foreground line-clamp-2 min-h-[32px]">
                            {category.DESCRIPTION || "Không có mô tả chi tiết."}
                        </p>
                        <div className="mt-4 flex flex-wrap justify-center gap-2">
                             <div className="rounded-full bg-accent px-2.5 py-0.5 text-[10px] font-bold text-secondary-foreground">
                                ORDER: {category.DISPLAY_ORDER}
                             </div>
                             <div className={cn(
                                "rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider",
                                category.IS_ACTIVE === 1 ? "bg-success/10 text-success" : "bg-secondary/10 text-secondary"
                             )}>
                                {category.IS_ACTIVE === 1 ? "Active" : "Hidden"}
                             </div>
                        </div>
                    </div>
                ))
            ) : (
                <div className="col-span-full py-20 text-center text-secondary-foreground">
                    Không tìm thấy danh mục nào.
                </div>
            )}
        </div>
      )}
    </div>
  );
}
