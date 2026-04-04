"use client";

import React, { useState, useEffect } from "react";
import { 
  Users, 
  Search,
  Mail,
  Phone,
  Briefcase,
  Shield,
  Plus,
  RefreshCw,
  BadgeInfo
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";

type Staff = {
  STAFF_ID: number;
  STAFF_CODE: string;
  FULL_NAME: string;
  ROLE: string;
  JOB_TITLE: string;
  DEPARTMENT: string;
  BRANCH_NAME: string;
  BRANCH_CODE: string;
  STATUS: string;
  EMAIL: string;
  PHONE: string;
};

export default function StaffPage() {
  const [staffList, setStaffList] = useState<Staff[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetchStaff();
  }, []);

  const fetchStaff = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/staff");
      const data = await res.json();
      if (data.success) {
        setStaffList(data.data);
      } else {
        toast.error("Không thể tải danh sách nhân viên");
      }
    } catch (error) {
      console.error("Failed to fetch staff:", error);
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setLoading(false);
    }
  };

  const filteredStaff = staffList.filter(s => 
    s.FULL_NAME.toLowerCase().includes(search.toLowerCase()) ||
    s.STAFF_CODE.toLowerCase().includes(search.toLowerCase()) ||
    s.EMAIL.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Quản lý Nhân sự</h1>
          <p className="text-sm text-secondary-foreground">Danh sách nhân viên tại các chi nhánh và phân quyền hệ thống.</p>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={fetchStaff}
            className="flex items-center gap-2 rounded-lg border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-accent transition-colors"
          >
            <RefreshCw size={16} className={cn(loading && "animate-spin")} />
            Làm mới
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover transition-all">
            <Plus size={16} />
            Thêm nhân viên
          </button>
        </div>
      </div>

      {/* Filters & Summary */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary-foreground" size={18} />
          <input 
            type="text" 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm theo tên, mã NV, email..." 
            className="w-full rounded-lg border border-border bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
          />
        </div>
        <div className="flex gap-2">
            <div className="card-shadow flex items-center gap-3 rounded-xl border border-border bg-white px-4 py-2">
                <Users size={18} className="text-primary" />
                <div>
                    <p className="text-[10px] font-bold uppercase tracking-wider text-secondary-foreground">Tổng nhân viên</p>
                    <p className="text-lg font-bold">{staffList.length}</p>
                </div>
            </div>
        </div>
      </div>

      {/* Staff Table */}
      <div className="card-shadow overflow-hidden rounded-xl border border-border bg-white">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-accent/50 text-xs font-semibold uppercase tracking-wider text-secondary-foreground border-b border-border">
              <tr>
                <th className="px-6 py-4">Nhân viên</th>
                <th className="px-6 py-4">Liên hệ</th>
                <th className="px-6 py-4">Công việc / Chi nhánh</th>
                <th className="px-6 py-4">Phân quyền</th>
                <th className="px-6 py-4 text-center">Trạng thái</th>
                <th className="px-6 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array(5).fill(0).map((_, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <Skeleton className="h-10 w-10 rounded-full" />
                        <div className="space-y-2">
                          <Skeleton className="h-4 w-32" />
                          <Skeleton className="h-3 w-20" />
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 space-y-2">
                        <Skeleton className="h-4 w-40" />
                        <Skeleton className="h-4 w-24" />
                    </td>
                    <td className="px-6 py-4 space-y-2">
                        <Skeleton className="h-4 w-36" />
                        <Skeleton className="h-4 w-28" />
                    </td>
                    <td className="px-6 py-4">
                        <Skeleton className="h-6 w-20 rounded-full" />
                    </td>
                    <td className="px-6 py-4">
                        <Skeleton className="h-6 w-20 rounded-full mx-auto" />
                    </td>
                    <td className="px-6 py-4 text-right">
                        <Skeleton className="h-8 w-16 ml-auto" />
                    </td>
                  </tr>
                ))
              ) : filteredStaff.length > 0 ? (
                filteredStaff.map((staff) => (
                  <tr key={staff.STAFF_ID} className="group transition-colors hover:bg-accent/10">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-bold">
                            {staff.FULL_NAME.charAt(0)}
                        </div>
                        <div className="flex flex-col">
                          <span className="font-semibold text-foreground group-hover:text-primary transition-colors cursor-pointer">
                            {staff.FULL_NAME}
                          </span>
                          <span className="text-xs font-mono text-secondary-foreground">{staff.STAFF_CODE}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <div className="flex items-center gap-1.5 text-xs text-secondary-foreground">
                            <Mail size={12} />
                            {staff.EMAIL}
                        </div>
                        <div className="flex items-center gap-1.5 text-xs text-secondary-foreground">
                            <Phone size={12} />
                            {staff.PHONE || "Chưa cập nhật"}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                        <div className="flex flex-col">
                            <div className="flex items-center gap-1.5 font-medium">
                                <Briefcase size={14} className="text-primary" />
                                {staff.JOB_TITLE || staff.DEPARTMENT || "Nhân viên"}
                            </div>
                            <span className="text-xs text-secondary-foreground">{staff.BRANCH_NAME} ({staff.BRANCH_CODE})</span>
                        </div>
                    </td>
                    <td className="px-6 py-4">
                        <div className={cn(
                          "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold",
                          staff.ROLE === 'ADMIN' ? "bg-error/10 text-error" : 
                          staff.ROLE === 'MANAGER' ? "bg-warning/10 text-warning" : 
                          "bg-primary/10 text-primary"
                        )}>
                          <Shield size={12} />
                          {staff.ROLE}
                        </div>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className={cn(
                        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold",
                        staff.STATUS === 'ACTIVE' ? "bg-success/10 text-success" : "bg-secondary/10 text-secondary"
                      )}>
                        {staff.STATUS === 'ACTIVE' ? "Đang làm việc" : "Nghỉ việc"}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                        <button className="rounded-md border border-border p-2 hover:bg-accent transition-colors">
                            <BadgeInfo size={16} className="text-secondary-foreground" />
                        </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-20 text-center text-secondary-foreground">
                    Không tìm thấy nhân viên nào phù hợp.
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
