"use client";

import React, { useState } from "react";
import { 
  User, 
  Building2, 
  ShieldCheck, 
  LocateFixed,
  Save,
  Lock
} from "lucide-react";
import { useBranch } from "@/context/branch-context";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

export default function SettingsPage() {
  const { currentUser, currentBranch } = useBranch();
  const [activeSection, setActiveSection] = useState("profile");

  const sections = [
    { id: "profile", label: "Cá nhân", icon: User },
    { id: "branch", label: "Chi nhánh", icon: Building2 },
    { id: "security", label: "Bảo mật", icon: ShieldCheck },
  ];

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-foreground">Thiết lập hệ thống</h1>
        <p className="text-secondary-foreground font-medium">Quản lý thông tin cá nhân và cấu hình chi nhánh của bạn.</p>
      </div>

      <div className="grid gap-8 lg:grid-cols-4">
        {/* Navigation Sidebar */}
        <div className="lg:col-span-1 space-y-1">
          {sections.map((section) => (
            <button
              key={section.id}
              onClick={() => setActiveSection(section.id)}
              className={cn(
                "flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition-all hover:bg-accent/30",
                activeSection === section.id 
                  ? "bg-primary/10 text-primary shadow-sm" 
                  : "text-secondary-foreground hover:text-foreground"
              )}
            >
              <section.icon size={18} />
              {section.label}
            </button>
          ))}
        </div>

        {/* Content Area */}
        <div className="lg:col-span-3 card-shadow rounded-2xl border border-border bg-white p-8">
          {activeSection === "profile" && (
            <div className="space-y-8">
               <div>
                  <h3 className="text-lg font-bold text-foreground">Thông tin cá nhân</h3>
                  <p className="text-xs text-secondary-foreground font-medium uppercase tracking-widest mt-1">Hồ sơ người dùng trong hệ thống back-office</p>
               </div>

               <div className="flex items-center gap-6 pb-8 border-b border-border">
                  <div className="flex h-24 w-24 items-center justify-center rounded-2xl bg-secondary text-secondary-foreground text-3xl font-black border border-border shadow-inner">
                    {currentUser?.name?.charAt(0) || "A"}
                  </div>
                  <div className="space-y-2">
                    <button className="rounded-lg bg-primary px-4 py-2 text-xs font-bold text-white shadow-md hover:bg-primary-hover transition-all">Thay đổi ảnh</button>
                    <button className="ml-3 text-xs font-bold text-error border border-error/20 px-4 py-2 rounded-lg hover:bg-error/5 transition-all">Gỡ bỏ</button>
                    <p className="text-[10px] text-secondary-foreground font-medium uppercase tracking-tighter mt-2">JPG, PNG hoặc GIF. Tối đa 800kB.</p>
                  </div>
               </div>

               <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Họ và tên</label>
                    <div className="relative group">
                       <input 
                         type="text" 
                         defaultValue={currentUser?.name || "Admin User"}
                         className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                         title="Tên người dùng"
                         placeholder="Tên đầy đủ"
                       />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Email</label>
                    <input 
                      type="email" 
                      defaultValue={currentUser?.name ? `${currentUser.name.toLowerCase().replace(/\s/g, '.')}@digibook.com.vn` : "admin@digibook.com.vn"}
                      className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                      title="Địa chỉ email"
                      placeholder="Email"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Số điện thoại</label>
                    <input 
                      type="text" 
                      defaultValue="0988 777 999"
                      className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all"
                      title="Số điện thoại"
                      placeholder="Số điện thoại"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Phân quyền</label>
                    <div className="flex h-[46px] items-center px-4 rounded-xl border border-border bg-accent/5 font-bold text-sm text-primary">
                       {currentUser?.role || "ADMIN"}
                    </div>
                  </div>
               </div>

               <div className="flex justify-end pt-4">
                  <button 
                    onClick={() => toast.success("Đã lưu cập nhật thông tin cá nhân thành công!")}
                    className="flex items-center gap-2 rounded-xl bg-primary px-8 py-3 text-sm font-bold text-white shadow-lg shadow-primary/20 hover:bg-primary-hover transition-all"
                  >
                    <Save size={18} />
                    Lưu thay đổi
                  </button>
               </div>
            </div>
          )}

          {activeSection === "branch" && (
            <div className="space-y-8">
               <div>
                  <h3 className="text-lg font-bold text-foreground">Thông tin chi nhánh hiện tại</h3>
                  <p className="text-xs text-secondary-foreground font-medium uppercase tracking-widest mt-1">Thông tin chi tiết của {currentBranch?.name || "Hệ thống"}</p>
               </div>

               <div className="grid gap-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Tên chi nhánh</label>
                    <input 
                      type="text" 
                      readOnly
                      value={currentBranch?.name || ""}
                      title="Tên chi nhánh"
                      aria-label="Tên chi nhánh"
                      className="w-full rounded-xl border border-border bg-accent/20 py-3 px-4 text-sm outline-none font-bold text-foreground"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Địa chỉ chi nhánh</label>
                    <div className="flex items-center gap-3 rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm text-secondary-foreground">
                       <LocateFixed size={18} className="text-primary" />
                       {currentBranch?.address || "Chưa xác định"}
                    </div>
                  </div>
                  
                  <div className="rounded-xl border border-warning/20 bg-warning/5 p-4 flex gap-4">
                     <Lock size={20} className="text-warning shrink-0" />
                     <div className="space-y-1">
                        <h4 className="text-sm font-bold text-warning">Chế độ xem mặc định</h4>
                        <p className="text-xs text-secondary-foreground">Bạn chỉ có quyền xem thông tin chi nhánh này. Để thay đổi thông tin liên lạc chi nhánh, vui lòng liên hệ Ban quản trị hệ thống.</p>
                     </div>
                  </div>
               </div>
            </div>
          )}

          {activeSection === "security" && (
            <div className="space-y-8">
               <div>
                  <h3 className="text-lg font-bold text-foreground">Bảo mật tài khoản</h3>
                  <p className="text-xs text-secondary-foreground font-medium uppercase tracking-widest mt-1">Cập nhật mật khẩu và thiết lập xác thực</p>
               </div>
               
               <div className="space-y-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Mật khẩu hiện tại</label>
                    <input type="password" placeholder="••••••••" className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Mật khẩu mới</label>
                    <input type="password" placeholder="••••••••" className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase text-secondary-foreground ml-1">Xác nhận mật khẩu</label>
                    <input type="password" placeholder="••••••••" className="w-full rounded-xl border border-border bg-accent/10 py-3 px-4 text-sm outline-none focus:ring-1 focus:ring-primary transition-all" />
                  </div>
               </div>

               <div className="flex justify-end pt-4">
                  <button 
                    onClick={() => toast.success("Đã thay đổi mật khẩu tài khoản thành công!")}
                    className="rounded-xl bg-primary px-8 py-3 text-sm font-bold text-white shadow-lg hover:bg-primary-hover transition-all"
                  >
                    Đổi mật khẩu
                  </button>
               </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
