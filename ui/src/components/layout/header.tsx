"use client";

import React, { useState } from "react";
import { 
  Bell, 
  Search, 
  ChevronDown, 
  User, 
  LogOut,
  MapPin,
  Building2,
  Globe
} from "lucide-react";
import { useBranch, SYSTEM_BRANCH } from "@/context/branch-context";
import { useRouter } from "next/navigation";
import { cn } from "@/lib/utils";

export function Header() {
  const { branches, currentBranch, setCurrentBranch, currentUser, logout } = useBranch();
  const [showBranches, setShowBranches] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const router = useRouter();

  const handleLogout = () => {
    logout();
    router.push("/login");
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-border bg-white px-8">
      {/* Search Bar */}
      <div className="flex w-96 items-center gap-2 rounded-xl bg-accent/40 px-3 py-2 text-secondary-foreground transition-all focus-within:bg-white focus-within:ring-2 focus-within:ring-primary/20 border border-transparent focus-within:border-primary/30 shadow-sm">
        <Search size={18} className="text-secondary-foreground/60" />
        <input 
          type="text" 
          placeholder="Tìm kiếm sách, đơn hàng, khách hàng..." 
          className="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-secondary-foreground/50 font-medium"
        />
      </div>

      {/* Actions */}
      <div className="flex items-center gap-4">
        {/* Branch Switcher */}
        <div className="relative">
          <div 
            onClick={() => (currentUser?.role === "ADMIN" || currentUser?.role === "SUPPORT") && setShowBranches(!showBranches)}
            className={cn(
              "hidden items-center gap-2 rounded-xl border border-border bg-accent/40 px-4 py-2 text-xs font-semibold md:flex transition-all select-none shadow-sm",
              (currentUser?.role === "ADMIN" || currentUser?.role === "SUPPORT") ? "cursor-pointer hover:bg-white hover:shadow-md hover:border-primary/30" : "cursor-default opacity-80"
            )}
          >
            <div className={cn(
              "flex h-6 w-6 items-center justify-center rounded-lg shadow-sm border",
              currentBranch?.id === "ALL" ? "bg-emerald-500 text-white border-emerald-400" : "bg-primary/10 text-primary border-primary/20"
            )}>
              {currentBranch?.id === "ALL" ? <Globe size={14} /> : <Building2 size={14} />}
            </div>
            <div className="flex flex-col">
              <span className="text-[10px] text-secondary-foreground leading-none mb-0.5">Phạm vi:</span>
              <span className="text-foreground max-w-[140px] truncate leading-none font-bold">
                {currentBranch?.id === "ALL" ? "Toàn hệ thống" : currentBranch?.name}
              </span>
            </div>
            {(currentUser?.role === "ADMIN" || currentUser?.role === "SUPPORT") && (
              <ChevronDown size={14} className={cn("text-secondary-foreground/60 transition-transform duration-300 ml-1", showBranches && "rotate-180")} />
            )}
          </div>

          {(currentUser?.role === "ADMIN" || currentUser?.role === "SUPPORT") && showBranches && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowBranches(false)} />
              <div className="absolute right-0 mt-3 w-72 rounded-2xl border border-border bg-white/80 backdrop-blur-xl p-2 shadow-2xl animate-in fade-in zoom-in duration-300 z-50 overflow-hidden">
                <div className="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-secondary-foreground/60 border-b border-border/50 mb-1">
                   Chọn phạm vi làm việc
                </div>
                <div className="max-h-[400px] overflow-y-auto custom-scrollbar flex flex-col gap-1 p-1">
                  {/* System-wide option */}
                  <div 
                    onClick={() => {
                      setCurrentBranch(SYSTEM_BRANCH);
                      setShowBranches(false);
                    }}
                    className={cn(
                      "group flex items-start gap-3 rounded-xl px-3 py-3 cursor-pointer transition-all duration-200",
                      currentBranch?.id === "ALL" ? "bg-emerald-500 text-white shadow-lg shadow-emerald-500/20" : "hover:bg-accent"
                    )}
                  >
                    <div className={cn(
                      "mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-lg transition-colors border",
                      currentBranch?.id === "ALL" ? "bg-white/20 border-white/30" : "bg-emerald-500/10 text-emerald-600 border-emerald-500/20 group-hover:bg-emerald-500 group-hover:text-white"
                    )}>
                      <Globe size={18} />
                    </div>
                    <div className="flex flex-col overflow-hidden">
                      <span className="text-sm font-black truncate">Toàn hệ thống</span>
                      <span className={cn(
                        "text-[10px] truncate leading-tight mt-0.5",
                        currentBranch?.id === "ALL" ? "text-white/80" : "text-secondary-foreground"
                      )}>Xem báo cáo tổng hợp từ tất cả chi nhánh</span>
                    </div>
                  </div>

                  <div className="h-[1px] bg-border/40 my-1 mx-2" />

                  {/* Individual branches */}
                  {branches.map((b) => (
                    <div 
                      key={b.id}
                      onClick={() => {
                        setCurrentBranch(b);
                        setShowBranches(false);
                      }}
                      className={cn(
                        "group flex items-start gap-3 rounded-xl px-3 py-2.5 cursor-pointer transition-all duration-200",
                        currentBranch?.id === b.id ? "bg-primary text-white shadow-lg shadow-primary/20" : "hover:bg-accent"
                      )}
                    >
                      <div className={cn(
                        "mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg transition-colors border",
                        currentBranch?.id === b.id ? "bg-white/20 border-white/30" : "bg-accent/60 group-hover:bg-primary/10 text-primary border-primary/10 group-hover:border-primary/20"
                      )}>
                        <MapPin size={16} />
                      </div>
                      <div className="flex flex-col overflow-hidden">
                        <span className="text-sm font-bold truncate">{b.name}</span>
                        <span className={cn(
                          "text-[10px] truncate leading-tight mt-0.5",
                          currentBranch?.id === b.id ? "text-white/80" : "text-secondary-foreground"
                        )}>{b.address}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>

        {/* Notifications */}
        <button 
          className="group relative flex h-10 w-10 items-center justify-center rounded-full border border-border bg-white text-secondary-foreground shadow-sm transition-all hover:bg-accent hover:shadow-md active:scale-95"
          title="Thông báo"
          aria-label="Xem thông báo"
        >
          <Bell size={20} className="transition-transform group-hover:animate-shake" />
          <span className="absolute right-2.5 top-2.5 h-2.5 w-2.5 rounded-full bg-rose-500 ring-4 ring-white animate-pulse"></span>
        </button>

        {/* User Profile */}
        <div className="relative">
          <div 
            onClick={() => setShowUserMenu(!showUserMenu)}
            className="flex items-center gap-3 border-l border-border pl-6 cursor-pointer group select-none py-1"
          >
            <div className="flex flex-col items-end">
              <span className="text-sm font-extrabold text-foreground leading-tight group-hover:text-primary transition-colors">
                {currentUser?.name || "Tài khoản"}
              </span>
              <div className="flex items-center gap-1.5 mt-1">
                <span className="text-[9px] font-black text-white uppercase tracking-tighter bg-primary px-1.5 py-0.5 rounded shadow-sm shadow-primary/30">
                  {currentUser?.role || "GUEST"}
                </span>
              </div>
            </div>
            <div className="relative h-11 w-11 rounded-2xl bg-secondary p-0.5 group-hover:ring-2 group-hover:ring-primary/20 transition-all duration-300 shadow-sm border border-border overflow-hidden">
                <div className="h-full w-full rounded-xl bg-white flex items-center justify-center text-secondary-foreground shadow-inner">
                  <User size={24} />
                </div>
            </div>
          </div>

          {showUserMenu && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowUserMenu(false)} />
              <div className="absolute right-0 mt-4 w-64 rounded-2xl border border-border bg-white/90 backdrop-blur-xl p-2 shadow-2xl animate-in fade-in slide-in-from-top-4 duration-300 z-50">
                <div className="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-secondary-foreground/60 border-b border-border/50 mb-2 flex items-center gap-2">
                    <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                    Trạng thái trực tuyến
                </div>
                
                <div className="flex flex-col gap-1 mb-2">
                   <div className="flex items-center gap-3 px-3 py-2 rounded-xl bg-accent/40">
                      <div className="p-2 rounded-lg bg-white shadow-sm text-primary">
                        <User size={16} />
                      </div>
                      <div className="flex flex-col overflow-hidden">
                        <span className="text-xs font-black text-foreground truncate">@{currentUser?.username || "username"}</span>
                        <span className="text-[10px] font-medium text-secondary-foreground truncate">ID: {currentUser?.staffId || "---"}</span>
                      </div>
                   </div>
                </div>

                <div className="h-[1px] bg-border/50 mx-2 my-2" />

                <button 
                  onClick={handleLogout}
                  className="group flex w-full items-center gap-3 rounded-xl px-3 py-3 text-sm font-bold text-rose-600 hover:bg-rose-50 transition-all duration-200"
                >
                  <div className="p-1.5 rounded-lg bg-rose-100/50 group-hover:bg-rose-100 transition-colors">
                    <LogOut size={16} />
                  </div>
                  Đăng xuất
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
