"use client";

import React, { useState, useEffect } from "react";
import { 
  Plus, 
  ArrowRight, 
  Clock, 
  CheckCircle2, 
  Truck,
  FileText,
  Search,
  Filter
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { TransferModal } from "@/components/inventory/transfer-modal";

export default function TransfersPage() {
  const [transfers, setTransfers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("ALL");
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    fetchTransfers();
  }, [activeTab]);

  const fetchTransfers = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/transfers?status=${activeTab}`);
      const data = await res.json();
      if (data.success) {
        setTransfers(data.data);
      }
    } catch (error) {
      console.error("Failed to fetch transfers");
    } finally {
      setLoading(false);
    }
  };

  const getStatusConfig = (status: string) => {
    switch (status) {
      case "COMPLETED": return { label: "Đã nhận", color: "bg-success/10 text-success", icon: CheckCircle2 };
      case "SHIPPING": return { label: "Đang giao", color: "bg-info/10 text-info", icon: Truck };
      case "APPROVED": return { label: "Đã duyệt", color: "bg-primary/10 text-primary", icon: CheckCircle2 };
      default: return { label: "Chờ duyệt", color: "bg-warning/10 text-warning", icon: Clock };
    }
  };

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Điều chuyển Kho hàng</h1>
          <p className="text-sm text-secondary-foreground">Cân đối tồn kho giữa các chi nhánh DigiBook (Oracle 19c).</p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-semibold text-white shadow-md hover:bg-primary-hover transition-all"
        >
          <Plus size={18} />
          Tạo lệnh điều chuyển mới
        </button>
      </div>

      <TransferModal 
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
        onRefresh={fetchTransfers} 
      />

      {/* States Grid */}
      <div className="grid gap-6 sm:grid-cols-3">
         <div className="card-shadow flex items-center gap-4 rounded-xl border border-border bg-white p-6">
            <div className="rounded-lg bg-warning/10 p-3 text-warning"><Clock size={24} /></div>
            <div className="flex flex-col">
               <span className="text-2xl font-bold">{transfers.filter(t => t.STATUS === 'PENDING').length.toString().padStart(2, '0')}</span>
               <span className="text-xs font-semibold text-secondary-foreground uppercase tracking-wider">Chờ phê duyệt</span>
            </div>
         </div>
         <div className="card-shadow flex items-center gap-4 rounded-xl border border-border bg-white p-6">
            <div className="rounded-lg bg-info/10 p-3 text-info"><Truck size={24} /></div>
            <div className="flex flex-col">
               <span className="text-2xl font-bold">{transfers.filter(t => t.STATUS === 'SHIPPING').length.toString().padStart(2, '0')}</span>
               <span className="text-xs font-semibold text-secondary-foreground uppercase tracking-wider">Đang vận chuyển</span>
            </div>
         </div>
         <div className="card-shadow flex items-center gap-4 rounded-xl border border-border bg-white p-6">
            <div className="rounded-lg bg-success/10 p-3 text-success"><CheckCircle2 size={24} /></div>
            <div className="flex flex-col">
               <span className="text-2xl font-bold">{transfers.filter(t => t.STATUS === 'COMPLETED').length.toString().padStart(2, '0')}</span>
               <span className="text-xs font-semibold text-secondary-foreground uppercase tracking-wider">Hoàn tất</span>
            </div>
         </div>
      </div>

      {/* Transfers List */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="border-b border-border p-4 flex flex-col gap-4 md:flex-row md:items-center justify-between">
           <div className="flex items-center gap-1">
             {["ALL", "PENDING", "APPROVED", "SHIPPING", "COMPLETED"].map(tab => (
               <button 
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={cn(
                  "px-3 py-1.5 text-xs font-bold rounded-lg transition-all",
                  activeTab === tab ? "bg-primary/10 text-primary" : "text-secondary-foreground hover:bg-accent"
                )}
               >
                 {tab === "ALL" ? "Tất cả" : tab}
               </button>
             ))}
           </div>
          <div className="relative flex-1 max-w-sm">
             <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
             <input 
               type="text" 
               placeholder="Tìm theo mã điều chuyển..." 
               className="w-full rounded-lg border border-border bg-accent/30 py-2 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
             />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Mã lệnh</th>
                <th className="px-6 py-4">Hành trình</th>
                <th className="px-6 py-4 text-center">Số lượng</th>
                <th className="px-6 py-4 text-center">Ngày tạo</th>
                <th className="px-6 py-4">Trạng thái</th>
                <th className="px-6 py-4"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-24" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-48" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-12 mx-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-4 w-32 mx-auto" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-24 rounded-full" /></td>
                    <td className="px-6 py-4 text-right"><Skeleton className="h-8 w-8 ml-auto rounded-full" /></td>
                  </tr>
                ))
              ) : transfers.length > 0 ? (
                transfers.map((item) => {
                  const config = getStatusConfig(item.STATUS);
                  return (
                    <tr key={item.TRANSFER_ID} className="group transition-colors hover:bg-accent/10">
                      <td className="px-6 py-4">
                        <span className="font-bold text-foreground">#{item.TRANSFER_CODE}</span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                           <span className="font-medium text-secondary-foreground">{item.FROM_BRANCH_NAME}</span>
                           <ArrowRight size={14} className="text-primary" />
                           <span className="font-medium text-foreground">{item.TO_BRANCH_NAME}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className="font-bold text-foreground">{item.TOTAL_QUANTITY} cuốn</span>
                        <div className="text-[10px] text-secondary-foreground uppercase">{item.TOTAL_ITEMS} đầu sách</div>
                      </td>
                      <td className="px-6 py-4 text-center text-secondary-foreground">
                        {item.REQUEST_DATE ? new Date(item.REQUEST_DATE).toLocaleDateString("vi-VN") : "---"}
                      </td>
                      <td className="px-6 py-4">
                        <div className={cn(
                          "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider",
                          config.color
                        )}>
                          <config.icon size={12} />
                          {config.label}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button className="rounded-md p-1.5 text-secondary-foreground hover:bg-accent hover:text-foreground transition-all">
                          <FileText size={18} />
                        </button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-20 text-center text-secondary-foreground font-medium">
                    Không có lệnh điều chuyển nào được tìm thấy.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
