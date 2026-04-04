"use client";

import React, { useMemo, useState } from "react";
import { X, Save, Pencil, Trash2 } from "lucide-react";
import { toast } from "sonner";

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

type CategoryManagerProps = {
  categories: Category[];
  onRefresh: () => Promise<void>;
  isOpen: boolean;
  onOpen: () => void;
  onClose: () => void;
};

type FormState = {
  category_name: string;
  parent_id: number | null;
  description: string;
  image_url: string;
  display_order: number;
  is_active: 0 | 1;
};

const emptyForm: FormState = {
  category_name: "",
  parent_id: null,
  description: "",
  image_url: "",
  display_order: 0,
  is_active: 1,
};

export function CategoryManager({ categories, onRefresh, isOpen, onOpen, onClose }: CategoryManagerProps) {
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState<FormState>(emptyForm);

  const parentOptions = useMemo(() => {
    if (!editingCategory) return categories;
    return categories.filter((item) => item.CATEGORY_ID !== editingCategory.CATEGORY_ID);
  }, [categories, editingCategory]);

  const categoryTree = useMemo(() => {
    const map = new Map<number, Category>();
    const roots: Category[] = [];

    categories.forEach((cat) => {
      map.set(cat.CATEGORY_ID, { ...cat, CHILDREN: [] });
    });

    categories.forEach((cat) => {
      if (cat.PARENT_ID) {
        const parent = map.get(cat.PARENT_ID);
        if (parent) {
          parent.CHILDREN = parent.CHILDREN || [];
          parent.CHILDREN.push(map.get(cat.CATEGORY_ID)!);
        }
      } else {
        roots.push(map.get(cat.CATEGORY_ID)!);
      }
    });

    return roots;
  }, [categories]);

  const openCreate = () => {
    setEditingCategory(null);
    setFormData(emptyForm);
    onOpen();
  };

  const openEdit = (category: Category) => {
    setEditingCategory(category);
    setFormData({
      category_name: category.CATEGORY_NAME,
      parent_id: category.PARENT_ID,
      description: category.DESCRIPTION ?? "",
      image_url: category.IMAGE_URL ?? "",
      display_order: category.DISPLAY_ORDER ?? 0,
      is_active: category.IS_ACTIVE ?? 1,
    });
    onOpen();
  };

  const closeModal = () => {
    if (saving) return;
    onClose();
  };

  const saveCategory = async () => {
    if (!formData.category_name.trim()) {
      toast.error("Tên danh mục là bắt buộc");
      return;
    }

    setSaving(true);
    try {
      const method = editingCategory ? "PUT" : "POST";
      const endpoint = editingCategory
        ? `/api/categories/${editingCategory.CATEGORY_ID}`
        : "/api/categories";

      const response = await fetch(endpoint, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });
      const result = await response.json();

      if (!result.success) {
        toast.error(result.message || "Không thể lưu danh mục");
        return;
      }

      toast.success(editingCategory ? "Đã cập nhật danh mục" : "Đã tạo danh mục");
      onClose();
      await onRefresh();
    } catch {
      toast.error("Lỗi khi lưu danh mục");
    } finally {
      setSaving(false);
    }
  };

  const deleteCategory = async (category: Category) => {
    const ok = window.confirm(`Xóa danh mục "${category.CATEGORY_NAME}"?`);
    if (!ok) return;

    try {
      const response = await fetch(`/api/categories/${category.CATEGORY_ID}`, {
        method: "DELETE",
      });
      const result = await response.json();
      if (!result.success) {
        toast.error(result.message || "Không thể xóa danh mục");
        return;
      }

      toast.success("Đã xóa danh mục");
      await onRefresh();
    } catch {
      toast.error("Lỗi khi xóa danh mục");
    }
  };

  const renderCategoryTree = (nodes: Category[], level = 0): React.ReactNode => {
    return nodes.map((node) => (
      <React.Fragment key={node.CATEGORY_ID}>
        <div className="flex items-center justify-between gap-2 px-3 py-2 text-sm hover:bg-accent/10 rounded">
          <div className="flex-1 min-w-0">
            {level > 0 && <span className="text-secondary-foreground text-xs">{"  ".repeat(level)}</span>}
            <button
              onClick={() => openEdit(node)}
              className="text-left font-medium text-foreground hover:text-primary truncate"
            >
              {node.CATEGORY_NAME}
            </button>
          </div>
          <div className="flex items-center gap-1 flex-shrink-0">
            <button
              onClick={() => openEdit(node)}
              className="p-1 text-secondary-foreground hover:bg-accent hover:text-foreground rounded"
              title="Sửa"
              aria-label={`Sửa ${node.CATEGORY_NAME}`}
            >
              <Pencil size={14} />
            </button>
            <button
              onClick={() => deleteCategory(node)}
              className="p-1 text-secondary-foreground hover:bg-error/10 hover:text-error rounded"
              title="Xóa"
              aria-label={`Xóa ${node.CATEGORY_NAME}`}
            >
              <Trash2 size={14} />
            </button>
          </div>
        </div>
        {node.CHILDREN && node.CHILDREN.length > 0 && renderCategoryTree(node.CHILDREN, level + 1)}
      </React.Fragment>
    ));
  };



  return (
    <>
      {isOpen && (
        <>
          <div className="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm" onClick={closeModal} />
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
            <div className="w-full max-w-4xl bg-white rounded-xl shadow-xl animate-in zoom-in-95 duration-300 my-auto flex flex-col max-h-[85vh]">
              <div className="flex items-center justify-between border-b border-border px-6 py-4">
                <h2 className="text-xl font-bold text-foreground">
                  Quản lý Danh mục Sách
                </h2>
                <button
                  onClick={closeModal}
                  title="Đóng"
                  aria-label="Đóng"
                  className="rounded-full p-2 text-secondary-foreground hover:bg-accent hover:text-foreground"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="flex-1 overflow-hidden flex gap-4 px-6 py-4">
                {/* Left: Category List */}
                <div className="w-72 border-r border-border pr-4 overflow-y-auto">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="font-semibold text-foreground">Danh mục</h3>
                    <button
                      onClick={openCreate}
                      className="px-2 py-1 text-xs bg-primary text-white rounded hover:bg-primary-hover"
                      title="Thêm danh mục"
                    >
                      + Thêm
                    </button>
                  </div>
                  <div className="space-y-1">
                    {categoryTree.length > 0 ? (
                      renderCategoryTree(categoryTree)
                    ) : (
                      <p className="text-xs text-secondary-foreground text-center py-4">Chưa có danh mục</p>
                    )}
                  </div>
                </div>

                {/* Right: Form */}
                <div className="flex-1 overflow-y-auto space-y-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-semibold text-foreground">Tên danh mục</label>
                  <input
                    value={formData.category_name}
                    onChange={(e) => setFormData({ ...formData, category_name: e.target.value })}
                    className="w-full rounded-lg border border-border px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                    placeholder="Nhập tên danh mục"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-sm font-semibold text-foreground">Danh mục cha</label>
                    <select
                      value={formData.parent_id ?? ""}
                      aria-label="Danh mục cha"
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          parent_id: e.target.value ? Number(e.target.value) : null,
                        })
                      }
                      className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                    >
                      <option value="">Danh mục gốc</option>
                      {parentOptions.map((item) => (
                        <option key={item.CATEGORY_ID} value={item.CATEGORY_ID}>
                          {item.CATEGORY_NAME}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-semibold text-foreground">Thứ tự hiển thị</label>
                    <input
                      type="number"
                      value={formData.display_order}
                      aria-label="Thứ tự hiển thị"
                      placeholder="0"
                      onChange={(e) =>
                        setFormData({ ...formData, display_order: Number(e.target.value || 0) })
                      }
                      className="w-full rounded-lg border border-border px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                    />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-semibold text-foreground">URL ảnh minh họa</label>
                  <input
                    type="url"
                    value={formData.image_url}
                    onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                    className="w-full rounded-lg border border-border px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                    placeholder="https://example.com/category.jpg"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-semibold text-foreground">Mô tả</label>
                  <textarea
                    rows={3}
                    value={formData.description}
                    aria-label="Mô tả"
                    placeholder="Mô tả ngắn cho danh mục"
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className="w-full rounded-lg border border-border px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-semibold text-foreground">Trạng thái</label>
                  <select
                    value={formData.is_active}
                    aria-label="Trạng thái danh mục"
                    onChange={(e) => setFormData({ ...formData, is_active: Number(e.target.value) as 0 | 1 })}
                    className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-primary"
                  >
                    <option value={1}>Hoạt động</option>
                    <option value={0}>Ẩn</option>
                  </select>
                </div>
              </div>
              </div>

              <div className="border-t border-border bg-accent/20 px-6 py-4 flex items-center gap-3">
                <button
                  onClick={closeModal}
                  disabled={saving}
                  className="flex-1 rounded-lg border border-border bg-white px-4 py-2.5 text-sm font-semibold text-foreground hover:bg-accent disabled:opacity-50"
                >
                  Hủy bỏ
                </button>
                <button
                  onClick={saveCategory}
                  disabled={saving}
                  className="flex flex-[2] items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-white shadow-md hover:bg-primary-hover disabled:opacity-50"
                >
                  <Save size={16} />
                  {editingCategory ? "Lưu thay đổi" : "Tạo danh mục"}
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
}
