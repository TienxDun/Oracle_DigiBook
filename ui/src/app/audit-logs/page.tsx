"use client";

import React, { useState, useEffect } from "react";
import { 
  History, Search, RefreshCw, Filter, ShieldAlert, ArrowRight, User, Globe
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

type AuditLog = {
  AUDIT_ID: number;
  ORDER_ID: number;
  ACTION_TYPE: "INSERT" | "UPDATE" | "DELETE";
  OLD_STATUS_CODE: string | null;
  NEW_STATUS_CODE: string | null;
  OLD_FINAL_AMOUNT: number | null;
  NEW_FINAL_AMOUNT: number | null;
  ACTION_BY: string;
  ACTION_AT: string;
  MODULE_NAME: string | null;
  IP_ADDRESS: string | null;
  NOTE: string | null;
};

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Filters
  const [actionType, setActionType] = useState("ALL");
  const [username, setUsername] = useState("");
  const [ipAddress, setIpAddress] = useState("");
  
  const [filterOptions, setFilterOptions] = useState<{ACTION_BY: string, IP_ADDRESS: string}[]>([]);

  useEffect(() => {
    fetchLogs();
  }, [actionType, username, ipAddress]);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (actionType !== "ALL") params.append("actionType", actionType);
      if (username) params.append("username", username);
      if (ipAddress) params.append("ipAddress", ipAddress);

      const res = await fetch(`/api/audit-logs?${params.toString()}`);
      const data = await res.json();
      if (data.success) {
        setLogs(data.data);
        if (filterOptions.length === 0 && data.filters) {
          setFilterOptions(data.filters);
        }
      } else {
        toast.error("Không thể tải nhật ký hệ thống");
      }
    } catch (error) {
      console.error("Failed to fetch logs:", error);
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  const uniqueUsernames = Array.from(new Set(filterOptions.map(f => f.ACTION_BY).filter(Boolean)));
  const uniqueIPs = Array.from(new Set(filterOptions.map(f => f.IP_ADDRESS).filter(Boolean)));

  const getActionColor = (action: string) => {
    switch (action) {
      case "INSERT": return "bg-success/10 text-success border-success/20";
      case "UPDATE": return "bg-warning/10 text-warning border-warning/20";
      case "DELETE": return "bg-destructive/10 text-destructive border-destructive/20";
      default: return "bg-secondary/10 text-secondary border-secondary/20";
    }
  };

  return (
    <div className="space-y-6 pb-10">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <ShieldAlert className="text-destructive" />
            Nhật ký Hệ thống (Audit Logs)
          </h1>
          <p className="text-sm text-secondary-foreground mt-1">
            Theo dõi vết thay đổi dữ liệu đơn hàng (Trigger <code className="bg-accent px-1 rounded">orders_audit_log</code>)
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => fetchLogs()}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <RefreshCw size={16} className={cn(loading && "animate-spin")} />
            Làm mới
          </button>
        </div>
      </div>

      {/* Filters Toolbar */}
      <div className="card-shadow flex flex-col gap-4 md:flex-row md:items-center p-4 rounded-xl border border-border bg-white">
        <div className="flex items-center gap-2 text-sm font-semibold text-secondary-foreground min-w-fit">
          <Filter size={16} /> Bộ lọc:
        </div>
        
        <div className="flex flex-col md:flex-row gap-3 w-full">
          {/* Action Type Filter */}
          <select 
            value={actionType}
            onChange={(e) => setActionType(e.target.value)}
            className="rounded-lg border border-border bg-white py-2 px-3 text-sm outline-none focus:ring-1 focus:ring-primary flex-1"
          >
            <option value="ALL">Tất cả thao tác</option>
            <option value="INSERT">Tạo mới (INSERT)</option>
            <option value="UPDATE">Cập nhật (UPDATE)</option>
            <option value="DELETE">Xóa (DELETE)</option>
          </select>

          {/* Username Filter */}
          <div className="relative flex-1">
            <User className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={16} />
            <select 
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full rounded-lg border border-border bg-white py-2 pl-9 pr-3 text-sm outline-none focus:ring-1 focus:ring-primary appearance-none"
            >
              <option value="">Mọi người dùng</option>
              {uniqueUsernames.map(usr => (
                <option key={usr} value={usr}>{usr}</option>
              ))}
            </select>
          </div>

          {/* IP Address Filter */}
          <div className="relative flex-1">
            <Globe className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={16} />
            <select 
              value={ipAddress}
              onChange={(e) => setIpAddress(e.target.value)}
              className="w-full rounded-lg border border-border bg-white py-2 pl-9 pr-3 text-sm outline-none focus:ring-1 focus:ring-primary appearance-none"
            >
              <option value="">Mọi địa chỉ IP</option>
              {uniqueIPs.map(ip => (
                <option key={ip} value={ip}>{ip}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Table Content */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Thời gian / ID</th>
                <th className="px-6 py-4">Thao tác</th>
                <th className="px-6 py-4">Sự thay đổi Trạng thái / Số tiền</th>
                <th className="px-6 py-4">Người thực hiện</th>
                <th className="px-6 py-4">IP / Cấp độ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading && logs.length === 0 ? (
                Array(7).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4"><Skeleton className="h-10 w-32" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-20 rounded-full" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-8 w-64" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-32" /></td>
                    <td className="px-6 py-4"><Skeleton className="h-6 w-24" /></td>
                  </tr>
                ))
              ) : logs.length > 0 ? (
                logs.map((log) => (
                  <tr key={log.AUDIT_ID} className="transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4 text-xs">
                      <div className="font-semibold text-foreground">
                        {new Date(log.ACTION_AT).toLocaleString('vi-VN')}
                      </div>
                      <div className="text-secondary-foreground mt-1 font-mono">
                        Log #{log.AUDIT_ID} <span className="mx-1">•</span> Order #{log.ORDER_ID}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className={cn(
                        "inline-flex items-center justify-center rounded-full border px-2.5 py-0.5 text-xs font-bold tracking-wider",
                        getActionColor(log.ACTION_TYPE)
                      )}>
                        {log.ACTION_TYPE}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {/* Status Change */}
                      {log.OLD_STATUS_CODE !== log.NEW_STATUS_CODE && (
                        <div className="flex items-center gap-2 text-xs mb-2">
                          <span className="font-medium text-secondary-foreground">Trạng thái:</span>
                          <span className="bg-accent px-1.5 py-0.5 rounded opacity-70">{log.OLD_STATUS_CODE || 'NULL'}</span>
                          <ArrowRight size={12} className="text-secondary-foreground"/>
                          <span className="bg-primary/10 text-primary px-1.5 py-0.5 rounded font-bold">{log.NEW_STATUS_CODE || 'NULL'}</span>
                        </div>
                      )}
                      {/* Final Amount Change */}
                      {log.OLD_FINAL_AMOUNT !== log.NEW_FINAL_AMOUNT && (
                        <div className="flex items-center gap-2 text-xs mt-1">
                          <span className="font-medium text-secondary-foreground">Tổng tiền:</span>
                          <span className="bg-accent px-1.5 py-0.5 rounded text-destructive line-through">
                            {log.OLD_FINAL_AMOUNT?.toLocaleString('vi-VN')} đ
                          </span>
                          <ArrowRight size={12} className="text-secondary-foreground"/>
                          <span className="bg-success/10 text-success px-1.5 py-0.5 rounded font-bold">
                            {log.NEW_FINAL_AMOUNT?.toLocaleString('vi-VN')} đ
                          </span>
                        </div>
                      )}
                      {log.OLD_STATUS_CODE === log.NEW_STATUS_CODE && log.OLD_FINAL_AMOUNT === log.NEW_FINAL_AMOUNT && (
                        <span className="text-xs text-secondary-foreground italic">Không có thay đổi trọng yếu</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <div className="h-6 w-6 rounded-full bg-primary/20 flex items-center justify-center text-primary text-xs font-bold">
                          {log.ACTION_BY?.charAt(0).toUpperCase()}
                        </div>
                        <span className="font-semibold text-sm">{log.ACTION_BY}</span>
                      </div>
                      <div className="text-[10px] text-secondary-foreground mt-1 truncate max-w-[150px]" title={log.NOTE || ""}>
                        {log.NOTE || "No note"}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-xs">
                      <div className="flex items-center gap-1.5 text-secondary-foreground">
                        <Globe size={12}/> {log.IP_ADDRESS || "localhost"}
                      </div>
                      <div className="flex items-center gap-1.5 text-secondary-foreground mt-1">
                        <History size={12}/> {log.MODULE_NAME || "Database Call"}
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-20 text-center text-secondary-foreground">
                    Không có bản ghi nhật ký nào.
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
