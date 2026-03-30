"use client";

import React, { useState, useEffect } from "react";
import { 
  Search, 
  Filter, 
  MoreHorizontal, 
  Eye, 
  Truck, 
  CheckCircle2, 
  Clock,
  Calendar,
  User as UserIcon
} from "lucide-react";
import { cn } from "@/lib/utils";
import { OrderDetailDrawer } from "@/components/orders/order-detail-drawer";
import { Skeleton } from "@/components/ui/skeleton";
import type { Order } from "@/types/database";

const statusConfig: any = {
  PENDING: { label: "Chờ xác nhận", color: "bg-warning/10 text-warning", icon: Clock },
  CONFIRMED: { label: "Đã xác nhận", color: "bg-info/10 text-info", icon: CheckCircle2 },
  SHIPPING: { label: "Đang giao", color: "bg-primary/10 text-primary", icon: Truck },
  DELIVERED: { label: "Đã giao", color: "bg-success/10 text-success", icon: CheckCircle2 },
  CANCELLED: { label: "Đã hủy", color: "bg-error/10 text-error", icon: Clock },
};

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("ALL");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total: 0, totalPages: 1 });
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);
  const limit = 10;

  useEffect(() => {
    fetchOrders();
  }, [page, activeTab, search]);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const url = `/api/orders?page=${page}&limit=${limit}&status=${activeTab}&search=${encodeURIComponent(search)}`;
      const res = await fetch(url);
      const data = await res.json();
      if (data.success) {
        setOrders(data.data);
        setPagination({ total: data.pagination.total, totalPages: data.pagination.totalPages });
      }
    } catch (error) {
      console.error("Failed to fetch orders:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleRowClick = (order: any) => {
    setSelectedOrder(order);
    setIsDrawerOpen(true);
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(e.target.value);
    setPage(1);
  };

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Đơn hàng</h1>
          <p className="text-sm text-secondary-foreground">Theo dõi và xử lý đơn hàng từ tất cả chi nhánh DigiBook (Oracle 19c).</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border">
        {["ALL", "PENDING", "CONFIRMED", "SHIPPING", "DELIVERED", "CANCELLED"].map((tab) => (
          <button 
            key={tab}
            onClick={() => { setActiveTab(tab); setPage(1); }}
            className={cn(
              "px-4 py-2 text-sm font-medium transition-all relative",
              activeTab === tab ? "text-primary border-b-2 border-primary" : "text-secondary-foreground hover:text-foreground"
            )}
          >
            {tab === "ALL" ? "Tất cả" : statusConfig[tab]?.label || tab}
          </button>
        ))}
      </div>

      {/* Table & List */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="border-b border-border p-4 bg-accent/20">
          <div className="flex flex-col gap-4 md:flex-row md:items-center justify-between">
            <div className="relative flex-1 max-w-sm">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
                <input 
                  type="text" 
                  value={search}
                  onChange={handleSearch}
                  placeholder="Tìm đơn hàng, khách hàng..." 
                  className="w-full rounded-lg border border-border bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                />
            </div>
            <div className="flex gap-2">
                <button className="flex items-center gap-2 rounded-lg border border-border bg-white px-3 py-2 text-sm font-medium hover:bg-accent transition-colors">
                    <Calendar size={16} />
                    Ngày tạo
                </button>
                <button className="flex items-center gap-2 rounded-lg border border-border bg-white px-3 py-2 text-sm font-medium hover:bg-accent text-secondary-foreground transition-colors">
                    <Filter size={16} />
                    Bộ lọc
                </button>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/30 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Mã đơn</th>
                <th className="px-6 py-4">Khách hàng</th>
                <th className="px-6 py-4">Chi nhánh</th>
                <th className="px-6 py-4 text-right">Tổng thanh toán</th>
                <th className="px-6 py-4 text-center">Trạng thái</th>
                <th className="px-6 py-4">Thời gian</th>
                <th className="px-6 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-24" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-32" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-20" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-24 ml-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-24 rounded-full mx-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-32" /></td>
                    <td className="px-6 py-4 text-right"><Skeleton className="h-8 w-16 ml-auto" /></td>
                  </tr>
                ))
              ) : orders.length > 0 ? (
                orders.map((order) => (
                  <tr key={order.ORDER_ID} className="group transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4">
                      <span className="font-bold text-foreground cursor-pointer" onClick={() => handleRowClick(order)}>#{order.ORDER_CODE}</span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                          <div className="h-8 w-8 rounded-full bg-secondary flex items-center justify-center text-secondary-foreground">
                              <UserIcon size={14} />
                          </div>
                          <span className="font-medium text-foreground">{order.CUSTOMER_NAME}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-secondary-foreground font-medium">{order.BRANCH_NAME}</td>
                    <td className="px-6 py-4 text-right font-bold text-foreground">
                      {order.FINAL_AMOUNT?.toLocaleString("vi-VN")} đ
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className={cn(
                          "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider shadow-sm",
                          statusConfig[order.STATUS_CODE]?.color || "bg-accent text-secondary-foreground"
                      )}>
                          {(() => {
                              const Icon = statusConfig[order.STATUS_CODE]?.icon || Clock;
                              return <Icon size={12} />;
                          })()}
                          {order.STATUS_NAME_VI}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-secondary-foreground text-xs font-medium">
                      {order.CREATED_AT ? new Date(order.CREATED_AT).toLocaleString("vi-VN") : "---"}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                          <button 
                              onClick={() => handleRowClick(order)}
                              className="rounded-md p-1.5 text-primary hover:bg-primary/10 transition-all"
                          >
                              <Eye size={18} />
                          </button>
                          <button className="rounded-md p-1.5 text-secondary-foreground hover:bg-accent hover:text-foreground transition-all">
                              <MoreHorizontal size={18} />
                          </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-20 text-center text-secondary-foreground">
                    Không tìm thấy đơn hàng nào phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        
        {/* Pagination */}
        <div className="flex items-center justify-between border-t border-border bg-white px-6 py-4 text-sm text-secondary-foreground">
          <span>
            Hiển thị <span className="font-bold text-foreground">{(page - 1) * limit + 1} - {Math.min(page * limit, pagination.total)}</span> trong tổng số <span className="font-bold text-foreground">{pagination.total}</span> đơn hàng
          </span>
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1 || loading}
              className="rounded border border-border px-3 py-1 hover:bg-accent disabled:opacity-50"
            >Trước</button>
            <button 
              onClick={() => setPage(p => Math.min(pagination.totalPages, p + 1))}
              disabled={page === pagination.totalPages || loading}
              className="rounded border border-border px-3 py-1 hover:bg-accent disabled:opacity-50"
            >Sau</button>
          </div>
        </div>
      </div>

      {/* Order Detail Drawer */}
      <OrderDetailDrawer 
        isOpen={isDrawerOpen} 
        onClose={() => setIsDrawerOpen(false)} 
        onRefresh={fetchOrders}
        order={selectedOrder}
      />
    </div>
  );
}
