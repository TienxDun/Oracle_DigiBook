"use client";

import React, { useState, useEffect } from "react";
import { X, CheckCircle2, Clock, Truck, Package, MapPin, Phone, User, Calendar, CreditCard, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

interface OrderDetailDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onRefresh?: () => void;
  order: any;
}

export function OrderDetailDrawer({ isOpen, onClose, onRefresh, order }: OrderDetailDrawerProps) {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    if (isOpen && order?.ORDER_ID) {
      fetchOrderItems();
    }
  }, [isOpen, order]);

  const fetchOrderItems = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/orders/${order.ORDER_ID}/items`);
      const data = await res.json();
      if (data.success) setItems(data.data);
    } catch (e) {
      console.error("Failed to fetch order items");
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (newStatus: string) => {
    setUpdating(true);
    try {
      const res = await fetch(`/api/orders/${order.ORDER_ID}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status_code: newStatus })
      });
      const data = await res.json();
      if (data.success) {
        toast.success("Cập nhật trạng thái thành công");
        if (onRefresh) onRefresh();
        onClose();
      } else {
        toast.error(data.message);
      }
    } catch (e) {
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setUpdating(false);
    }
  };

  if (!isOpen || !order) return null;

  return (
    <>
      <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 z-50 w-full max-w-2xl bg-white shadow-2xl animate-in slide-in-from-right duration-300">
        <div className="flex h-full flex-col">
          <div className="flex items-center justify-between border-b border-border bg-accent/10 px-6 py-4">
            <div>
               <h2 className="text-xl font-bold text-foreground">Chi tiết Đơn hàng #{order.ORDER_CODE}</h2>
               <p className="text-xs text-secondary-foreground font-medium uppercase tracking-wider">
                  Ngày tạo: {order.ORDER_DATE ? new Date(order.ORDER_DATE).toLocaleDateString("vi-VN") : "---"}
               </p>
            </div>
            <button onClick={onClose} className="rounded-full p-2 text-secondary-foreground hover:bg-accent hover:text-foreground">
              <X size={20} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto px-6 py-6">
            <div className="grid gap-8">
              <div className="space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-widest text-primary border-l-4 border-primary pl-3">Sản phẩm đã đặt</h3>
                <div className="rounded-xl border border-border bg-accent/10 overflow-hidden">
                  <table className="w-full text-sm">
                    <thead className="bg-accent/30 text-xs font-semibold uppercase text-secondary-foreground">
                      <tr>
                        <th className="px-4 py-2 text-left">Sản phẩm</th>
                        <th className="px-4 py-2 text-center">SL</th>
                        <th className="px-4 py-2 text-right">Giá</th>
                        <th className="px-4 py-2 text-right">Tổng</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {loading ? (
                        <tr><td colSpan={4} className="p-10 text-center"><Loader2 className="animate-spin inline mr-2"/> Đang tải...</td></tr>
                      ) : items.map((item, idx) => (
                        <tr key={idx}>
                          <td className="px-4 py-3">
                            <div className="font-medium text-foreground">{item.book_title}</div>
                            <div className="text-[11px] text-secondary-foreground">ISBN: {item.isbn}</div>
                          </td>
                          <td className="px-4 py-3 text-center">{item.quantity}</td>
                          <td className="px-4 py-3 text-right">{item.unit_price.toLocaleString()} đ</td>
                          <td className="px-4 py-3 text-right font-bold text-foreground">{item.total.toLocaleString()} đ</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot className="bg-accent/40 border-t border-border font-bold">
                        <tr>
                            <td colSpan={3} className="px-4 py-2 text-right text-foreground">Tổng cộng thanh toán:</td>
                            <td className="px-4 py-2 text-right text-lg text-primary">{order.FINAL_AMOUNT?.toLocaleString()} đ</td>
                        </tr>
                    </tfoot>
                  </table>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-8">
                 <div className="space-y-4">
                    <h3 className="text-sm font-bold uppercase tracking-widest text-primary border-l-4 border-primary pl-3">Khách hàng</h3>
                    <div className="card-shadow space-y-3 rounded-xl border border-border p-4 text-sm bg-white">
                        <div className="flex items-center gap-3">
                            <User size={16} className="text-secondary-foreground" />
                            <span className="font-semibold text-foreground">{order.CUSTOMER_NAME}</span>
                        </div>
                        <div className="flex items-center gap-3">
                            <Phone size={16} className="text-secondary-foreground" />
                            <span className="text-secondary-foreground">{order.SHIP_PHONE || order.CUSTOMER_PHONE || "---"}</span>
                        </div>
                        <div className="flex items-center gap-3">
                            <MapPin size={16} className="text-secondary-foreground shrink-0" />
                            <span className="text-xs text-secondary-foreground">{order.SHIP_ADDRESS}, {order.SHIP_DISTRICT}, {order.SHIP_PROVINCE}</span>
                        </div>
                    </div>
                 </div>

                 <div className="space-y-4">
                    <h3 className="text-sm font-bold uppercase tracking-widest text-primary border-l-4 border-primary pl-3">Trạng thái</h3>
                    <div className={cn(
                      "inline-flex items-center gap-2 rounded-xl border border-border p-4 text-sm font-bold uppercase tracking-widest",
                      order.STATUS_CODE === 'DELIVERED' ? "bg-emerald-50 text-emerald-600" : "bg-warning/10 text-warning"
                    )}>
                      {order.STATUS_CODE}
                    </div>
                 </div>
              </div>
            </div>
          </div>

          <div className="border-t border-border bg-accent/20 px-6 py-4">
            <div className="flex items-center gap-4">
               <button 
                onClick={() => handleUpdateStatus('CANCELLED')}
                disabled={updating || order.STATUS_CODE === 'CANCELLED'}
                className="flex-1 rounded-lg border border-border bg-white py-2.5 text-sm font-semibold text-error hover:bg-error/10 disabled:opacity-50 transition-colors"
               >Hủy đơn</button>
               <button 
                onClick={() => handleUpdateStatus('CONFIRMED')}
                disabled={updating || order.STATUS_CODE !== 'PENDING'}
                className="flex-[2] items-center justify-center flex gap-2 rounded-lg bg-primary py-2.5 text-sm font-bold text-white shadow-md hover:bg-primary-hover disabled:opacity-50 transition-all"
               >
                  {updating && <Loader2 className="animate-spin" size={18} />}
                  Xác nhận & Giao hàng
               </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
