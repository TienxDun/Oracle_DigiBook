"use client";

import React, { useState } from "react";
import { 
  Bell, 
  Search, 
  ChevronDown, 
  User, 
  LogOut,
  MapPin,
  Building2
} from "lucide-react";
import { useBranch } from "@/context/branch-context";
import { cn } from "@/lib/utils";

export function Header() {
  const { branches, currentBranch, setCurrentBranch, currentUser, logout } = useBranch();
  const [showBranches, setShowBranches] = useState(false);

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-border bg-white px-8">
      {/* Search Bar */}
      <div className="flex w-96 items-center gap-2 rounded-lg bg-accent px-3 py-2 text-secondary-foreground transition-all focus-within:bg-white focus-within:ring-1 focus-within:ring-primary">
        <Search size={18} />
        <input 
          type="text" 
          placeholder="Tìm kiếm sách, đơn hàng, khách hàng..." 
          className="w-full bg-transparent text-sm text-foreground outline-none placeholder:text-secondary-foreground/60"
        />
      </div>

      {/* Actions */}
      <div className="flex items-center gap-4">
        {/* Branch Switcher */}
        <div className="relative">
          <div 
            onClick={() => setShowBranches(!showBranches)}
            className="hidden items-center gap-2 rounded-md border border-border px-3 py-1.5 text-xs font-medium md:flex cursor-pointer hover:bg-accent transition-all select-none"
          >
            <Building2 size={14} className="text-primary" />
            <span className="text-secondary-foreground">Cửa hàng:</span>
            <span className="text-foreground max-w-[120px] truncate">{currentBranch?.name || "Chọn chi nhánh"}</span>
            <ChevronDown size={14} className={cn("text-secondary-foreground transition-transform", showBranches && "rotate-180")} />
          </div>

          {showBranches && (
            <div className="absolute right-0 mt-2 w-56 rounded-xl border border-border bg-white p-2 shadow-xl animate-in fade-in zoom-in duration-200">
               <div className="px-3 py-2 text-[10px] font-bold uppercase tracking-widest text-secondary-foreground">Chọn điểm làm việc</div>
               {branches.map((b) => (
                 <div 
                   key={b.id}
                   onClick={() => {
                     setCurrentBranch(b);
                     setShowBranches(false);
                   }}
                   className={cn(
                     "flex flex-col gap-0.5 rounded-lg px-3 py-2 cursor-pointer transition-colors",
                     currentBranch?.id === b.id ? "bg-primary/10" : "hover:bg-accent"
                   )}
                 >
                   <span className={cn("text-xs font-bold", currentBranch?.id === b.id ? "text-primary" : "text-foreground")}>{b.name}</span>
                   <span className="text-[10px] text-secondary-foreground flex items-center gap-1">
                     <MapPin size={10} /> {b.address}
                   </span>
                 </div>
               ))}
            </div>
          )}
        </div>

        {/* Notifications */}
        <button className="relative flex h-9 w-9 items-center justify-center rounded-full text-secondary-foreground hover:bg-accent hover:text-foreground">
          <Bell size={20} />
          <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-error ring-2 ring-white"></span>
        </button>

        {/* User Profile */}
        <div className="flex items-center gap-3 border-l border-border pl-4 cursor-pointer group relative">
          <div className="flex flex-col items-end">
            <span className="text-sm font-semibold text-foreground leading-tight group-hover:text-primary transition-colors">
              {currentUser?.name || "Admin User"}
            </span>
            <span className="text-[11px] font-bold text-secondary-foreground uppercase tracking-wider bg-accent px-1.5 rounded mt-0.5">
              {currentUser?.role || "SYSTEM"}
            </span>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-secondary text-secondary-foreground group-hover:ring-2 group-hover:ring-primary/20 transition-all overflow-hidden border border-border">
            <User size={22} />
          </div>
        </div>
      </div>
    </header>
  );
}
