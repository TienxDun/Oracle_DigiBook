"use client";

import React, { useState, useEffect } from "react";
import { 
  Ticket, Search, Plus, RefreshCw, Edit, Trash, Calculator, CheckCircle2, XCircle
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

type Coupon = {
  COUPON_ID: number;
  COUPON_CODE: string;
  COUPON_NAME: string;
  DESCRIPTION: string | null;
  DISCOUNT_TYPE: "PERCENT" | "FIXED";
  DISCOUNT_VALUE: number;
  MIN_ORDER_AMOUNT: number;
  MAX_DISCOUNT_AMOUNT: number | null;
  USAGE_LIMIT: number | null;
  USAGE_COUNT: number;
  PER_CUSTOMER_LIMIT: number;
  START_DATE: string;
  END_DATE: string;
  IS_ACTIVE: 0 | 1;
};

export default function CouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  
  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState<Coupon | null>(null);
  
  // Test Procedure states
  const [isTestOpen, setIsTestOpen] = useState(false);
  const [testCode, setTestCode] = useState("");
  const [testAmount, setTestAmount] = useState<number | "">("");
  const [testResult, setTestResult] = useState<{ amount: number; message: string } | null>(null);
  const [isTesting, setIsTesting] = useState(false);

  useEffect(() => {
    fetchCoupons();
  }, []);

  const fetchCoupons = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/coupons");
      const data = await res.json();
      if (data.success) {
        setCoupons(data.data);
      } else {
        toast.error("Không thể tải danh sách mã giảm giá");
      }
    } catch (error) {
      console.error("Failed to fetch coupons:", error);
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  const handleTestProcedure = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!testCode || testAmount === "") {
      toast.error("Vui lòng nhập mã và số tiền đơn hàng");
      return;
    }
    
    setIsTesting(true);
    try {
      const res = await fetch("/api/coupons/test", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ coupon_code: testCode, order_amount: Number(testAmount) })
      });
      const data = await res.json();
      if (data.success) {
        setTestResult({
          amount: data.discount_amount,
          message: data.message
        });
        if (data.message === "OK") {
          toast.success("Mã hợp lệ! Đã tính toán giảm giá.");
        } else {
          toast.warning(`Không hợp lệ: ${data.message}`);
        }
      } else {
        toast.error(data.message || "Lỗi khi gọi test procedure");
      }
    } catch (error) {
      console.error("Error testing procedure:", error);
      toast.error("Lỗi hệ thống khi test.");
    } finally {
      setIsTesting(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Bạn có chắc muốn xóa mã giảm giá này?")) return;
    try {
      const res = await fetch(`/api/coupons/${id}`, { method: "DELETE" });
      const data = await res.json();
      if (data.success) {
        toast.success(data.message);
        fetchCoupons();
      } else {
        toast.error(data.message);
      }
    } catch (error) {
      toast.error("Lỗi khi xóa mã giảm giá");
    }
  };

  const filteredCoupons = coupons.filter(c => 
    c.COUPON_CODE.toLowerCase().includes(search.toLowerCase()) || 
    c.COUPON_NAME.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6 pb-10">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Ticket className="text-primary" />
            Quản lý Khuyến mãi (Coupons)
          </h1>
          <p className="text-sm text-secondary-foreground mt-1">Tạo và cấu hình các chương trình giảm giá cho khách hàng.</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setIsTestOpen(!isTestOpen)}
            className="flex items-center gap-2 rounded-lg border border-primary bg-primary/10 px-4 py-2 text-sm font-semibold text-primary hover:bg-primary/20 transition-all"
          >
            <Calculator size={16} />
            Test Procedure
          </button>
          <button 
            onClick={() => { setEditingCoupon(null); setIsModalOpen(true); }}
            className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all"
          >
            <Plus size={16} />
            Tạo mã mới
          </button>
        </div>
      </div>

      {/* Test Procedure Section */}
      {isTestOpen && (
        <div className="card-shadow space-y-4 rounded-xl border border-primary/20 bg-primary/5 p-5 animate-in slide-in-from-top-4">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-primary flex items-center gap-2">
              <Calculator size={18} /> Call Procedure: <code className="bg-white px-2 py-0.5 rounded text-sm text-foreground">sp_calculate_coupon_discount</code>
            </h3>
            <button onClick={() => setIsTestOpen(false)} className="text-secondary-foreground hover:text-foreground">
              <XCircle size={20} />
            </button>
          </div>
          <form className="flex flex-col md:flex-row gap-4 items-end" onSubmit={handleTestProcedure}>
            <div className="flex-1 w-full">
              <label className="text-xs font-medium text-secondary-foreground mb-1 block">Mã Coupon</label>
              <input 
                type="text" 
                value={testCode}
                onChange={e => setTestCode(e.target.value)}
                placeholder="VD: TRUONG2025" 
                className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm uppercase outline-none focus:border-primary"
                required
              />
            </div>
            <div className="flex-1 w-full">
              <label className="text-xs font-medium text-secondary-foreground mb-1 block">Tổng tiền Đơn hàng (VND)</label>
              <input 
                type="number" 
                value={testAmount}
                onChange={e => setTestAmount(e.target.value === "" ? "" : Number(e.target.value))}
                placeholder="VD: 500000" 
                className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm outline-none focus:border-primary"
                required
              />
            </div>
            <button 
              type="submit" 
              disabled={isTesting}
              className="w-full md:w-auto flex items-center justify-center gap-2 rounded-lg bg-black px-6 py-2 text-sm font-bold text-white transition-all hover:bg-gray-800 disabled:opacity-70"
            >
              {isTesting ? "Đang tính..." : "Tính KQ"}
            </button>
          </form>

          {testResult && (
            <div className={cn(
              "mt-4 p-4 rounded-lg border flex items-start gap-3",
              testResult.message === "OK" ? "bg-success/10 border-success/30 text-success" : "bg-destructive/10 border-destructive/30 text-destructive"
            )}>
              {testResult.message === "OK" ? <CheckCircle2 className="shrink-0 mt-0.5" /> : <XCircle className="shrink-0 mt-0.5" />}
              <div>
                <p className="font-semibold">{testResult.message === "OK" ? "Mã hợp lệ. Có thể áp dụng." : "Mã không thể áp dụng."}</p>
                <div className="text-sm mt-1 flex gap-4">
                  <span>Trạng thái trả về: <strong>{testResult.message}</strong></span>
                  <span>Số tiền được giảm: <strong className="text-lg">{testResult.amount.toLocaleString('vi-VN')} đ</strong></span>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Toolbar */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
          <input 
            type="text" 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm theo ID hoặc tên chương trình..." 
            className="w-full max-w-md rounded-lg border border-border bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
          />
        </div>
        <button 
          onClick={fetchCoupons}
          className="flex items-center justify-center gap-2 rounded-lg border border-border bg-white p-2 hover:bg-accent transition-colors"
          title="Làm mới"
        >
          <RefreshCw size={18} className={cn(loading && "animate-spin")} />
        </button>
      </div>

      {/* Table Content */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Mã / Tên</th>
                <th className="px-6 py-4">Giá trị giảm</th>
                <th className="px-6 py-4">Đơn tối thiểu</th>
                <th className="px-6 py-4">Lượt dùng</th>
                <th className="px-6 py-4">Thời hạn</th>
                <th className="px-6 py-4 text-center">Trạng thái</th>
                <th className="px-6 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4"><Skeleton className="h-10 w-40" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-24" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-20" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-16" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-8 w-32" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-20 mx-auto rounded-full" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-8 w-16 ml-auto" /></td>
                  </tr>
                ))
              ) : filteredCoupons.length > 0 ? (
                filteredCoupons.map((c) => (
                  <tr key={c.COUPON_ID} className="transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4">
                      <div className="font-bold text-primary uppercase">{c.COUPON_CODE}</div>
                      <div className="text-secondary-foreground text-xs mt-1">{c.COUPON_NAME}</div>
                    </td>
                    <td className="px-6 py-4">
                      {c.DISCOUNT_TYPE === "PERCENT" ? (
                        <div className="font-bold">{c.DISCOUNT_VALUE}%</div>
                      ) : (
                        <div className="font-bold">{c.DISCOUNT_VALUE.toLocaleString('vi-VN')} đ</div>
                      )}
                      {c.MAX_DISCOUNT_AMOUNT && <div className="text-xs text-secondary-foreground">Tối đa: {c.MAX_DISCOUNT_AMOUNT.toLocaleString('vi-VN')}đ</div>}
                    </td>
                    <td className="px-6 py-4">
                      {c.MIN_ORDER_AMOUNT > 0 ? `${c.MIN_ORDER_AMOUNT.toLocaleString('vi-VN')} đ` : "Không có"}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1 text-xs">
                        <div className="w-full bg-accent rounded-full h-1.5 overflow-hidden">
                          <div 
                            className="bg-primary h-full" 
                            style={{ 
                              width: c.USAGE_LIMIT ? `${Math.min(100, (c.USAGE_COUNT / c.USAGE_LIMIT) * 100)}%` : '0%' 
                            }} 
                          />
                        </div>
                        <span className="text-secondary-foreground">
                          {c.USAGE_COUNT} / {c.USAGE_LIMIT || '∞'}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-xs tabular-nums text-secondary-foreground">
                      <div>Từ: {new Date(c.START_DATE).toLocaleDateString('vi-VN')}</div>
                      <div>Đến: {new Date(c.END_DATE).toLocaleDateString('vi-VN')}</div>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className={cn(
                        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold uppercase tracking-wider",
                        c.IS_ACTIVE === 1 
                          ? new Date(c.END_DATE).getTime() < Date.now() 
                            ? "bg-warning/10 text-warning" // active but expired
                            : "bg-success/10 text-success"
                          : "bg-secondary/10 text-secondary"
                      )}>
                        {c.IS_ACTIVE === 0 ? "Vô hiệu" : new Date(c.END_DATE).getTime() < Date.now() ? "Hết hạn" : "Active"}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        <button 
                          onClick={() => { setEditingCoupon(c); setIsModalOpen(true); }}
                          className="rounded-md border border-border p-2 text-secondary-foreground hover:bg-accent hover:text-primary transition-colors"
                        >
                          <Edit size={16} />
                        </button>
                        <button 
                          onClick={() => handleDelete(c.COUPON_ID)}
                          className="rounded-md border border-border p-2 text-secondary-foreground hover:bg-destructive/10 hover:border-destructive/30 hover:text-destructive transition-colors"
                        >
                          <Trash size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center text-secondary-foreground">
                    Không tìm thấy mã giảm giá nào.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* CRUD Modal would go here (simplified request did not explicitly ask for a full modal if standard form was preferred, but requested Thêm Sửa Xóa so a custom inline or basic modal is useful. For brevity, using standard logic via window.prompt could work, but a simple Form component is better.) */}
      {isModalOpen && (
        <CouponModal 
          isOpen={isModalOpen} 
          onClose={() => setIsModalOpen(false)} 
          coupon={editingCoupon}
          onSuccess={() => { setIsModalOpen(false); fetchCoupons(); }}
        />
      )}
    </div>
  );
}

// Inline component for the Modal Form to keep it all in one file
function CouponModal({ isOpen, onClose, coupon, onSuccess }: { isOpen: boolean, onClose: () => void, coupon: Coupon | null, onSuccess: () => void }) {
  const [formData, setFormData] = useState({
    coupon_code: coupon?.COUPON_CODE || "",
    coupon_name: coupon?.COUPON_NAME || "",
    description: coupon?.DESCRIPTION || "",
    discount_type: coupon?.DISCOUNT_TYPE || "PERCENT",
    discount_value: coupon?.DISCOUNT_VALUE || 0,
    min_order_amount: coupon?.MIN_ORDER_AMOUNT || 0,
    max_discount_amount: coupon?.MAX_DISCOUNT_AMOUNT || "",
    usage_limit: coupon?.USAGE_LIMIT || "",
    per_customer_limit: coupon?.PER_CUSTOMER_LIMIT || 1,
    start_date: coupon ? new Date(coupon.START_DATE).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
    end_date: coupon ? new Date(coupon.END_DATE).toISOString().split('T')[0] : "",
    is_active: coupon ? coupon.IS_ACTIVE : 1
  });
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const isEdit = !!coupon;
      const url = isEdit ? `/api/coupons/${coupon.COUPON_ID}` : "/api/coupons";
      const method = isEdit ? "PUT" : "POST";
      
      const payload: any = { ...formData };
      if (payload.max_discount_amount === "") payload.max_discount_amount = null;
      if (payload.usage_limit === "") payload.usage_limit = null;

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (data.success) {
        toast.success(data.message);
        onSuccess();
      } else {
        toast.error(data.message);
      }
    } catch (error) {
      toast.error("Lỗi khi lưu dữ liệu");
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-white rounded-2xl shadow-xl animate-in fade-in zoom-in-95">
        <div className="flex items-center justify-between border-b p-5 sticky top-0 bg-white z-10">
          <h2 className="text-xl font-bold flex items-center gap-2">
            <Ticket className="text-primary"/>
            {coupon ? "Cập nhật Mã giảm giá" : "Tạo Mã giảm giá mới"}
          </h2>
          <button onClick={onClose} className="p-2 hover:bg-accent rounded-full"><XCircle size={24} className="text-secondary-foreground"/></button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-sm font-semibold">Mã Code (CODE) <span className="text-destructive">*</span></label>
              <input type="text" required value={formData.coupon_code} onChange={e => setFormData({...formData, coupon_code: e.target.value.toUpperCase()})} className="w-full border rounded-lg p-2 focus:ring-1 focus:border-primary uppercase outline-none" placeholder="VD: TET2025" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold">Tên Chương trình <span className="text-destructive">*</span></label>
              <input type="text" required value={formData.coupon_name} onChange={e => setFormData({...formData, coupon_name: e.target.value})} className="w-full border rounded-lg p-2 focus:ring-1 focus:border-primary outline-none" placeholder="VD: Khuyến mãi Tết Dương lịch" />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-semibold">Hình thức giảm</label>
              <select value={formData.discount_type} onChange={e => setFormData({...formData, discount_type: e.target.value as "PERCENT"|"FIXED"})} className="w-full border rounded-lg p-2 outline-none">
                <option value="PERCENT">Giảm theo %</option>
                <option value="FIXED">Giảm số tiền cố định (VNĐ)</option>
              </select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold">Mức giảm ({formData.discount_type === "PERCENT" ? "%" : "VNĐ"}) <span className="text-destructive">*</span></label>
              <input type="number" required min="1" value={formData.discount_value} onChange={e => setFormData({...formData, discount_value: Number(e.target.value)})} className="w-full border rounded-lg p-2 outline-none" />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-semibold">Đơn hàng Tối thiểu (VNĐ)</label>
              <input type="number" min="0" value={formData.min_order_amount} onChange={e => setFormData({...formData, min_order_amount: Number(e.target.value)})} className="w-full border rounded-lg p-2 outline-none" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold">Giảm Tối đa (VNĐ) <span className="font-normal text-xs text-secondary-foreground">(Bỏ trống nếu KQ)</span></label>
              <input type="number" min="0" value={formData.max_discount_amount} onChange={e => setFormData({...formData, max_discount_amount: e.target.value})} className="w-full border rounded-lg p-2 outline-none" />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-semibold">Ngày Bắt đầu <span className="text-destructive">*</span></label>
              <input type="date" required value={formData.start_date} onChange={e => setFormData({...formData, start_date: e.target.value})} className="w-full border rounded-lg p-2 outline-none" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold">Ngày Kết thúc <span className="text-destructive">*</span></label>
              <input type="date" required value={formData.end_date} onChange={e => setFormData({...formData, end_date: e.target.value})} className="w-full border rounded-lg p-2 outline-none" />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-semibold">Số lượng vé (Usage Limit)</label>
              <input type="number" min="1" value={formData.usage_limit} onChange={e => setFormData({...formData, usage_limit: e.target.value})} placeholder="Bỏ trống: Vô hạn" className="w-full border rounded-lg p-2 outline-none" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-semibold">Giới hạn/1 khách</label>
              <input type="number" required min="1" value={formData.per_customer_limit} onChange={e => setFormData({...formData, per_customer_limit: Number(e.target.value)})} className="w-full border rounded-lg p-2 outline-none" />
            </div>
          </div>
          
          <div className="space-y-2">
            <label className="text-sm font-semibold">Mô tả thêm</label>
            <textarea value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full border rounded-lg p-2 h-20 outline-none" placeholder="Ghi chú nội bộ..." />
          </div>

          <div className="flex items-center gap-3 bg-accent/30 p-3 rounded-lg border">
            <input type="checkbox" id="is_active" checked={formData.is_active === 1} onChange={e => setFormData({...formData, is_active: e.target.checked ? 1 : 0})} className="w-5 h-5 accent-primary" />
            <label htmlFor="is_active" className="font-semibold cursor-pointer">Kích hoạt mã này ngay lập tức</label>
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t sticky bottom-0 bg-white">
            <button type="button" onClick={onClose} className="px-6 py-2 rounded-lg font-medium text-secondary-foreground hover:bg-accent transition-colors">Hủy</button>
            <button type="submit" disabled={saving} className="px-6 py-2 rounded-lg font-bold bg-primary text-white hover:bg-primary-hover transition-colors shadow-md disabled:opacity-70 flex items-center gap-2">
              {saving ? <RefreshCw className="animate-spin w-4 h-4"/> : null} 
              {coupon ? "Lưu thay đổi" : "Tạo Mới"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
