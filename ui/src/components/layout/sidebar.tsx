"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  LayoutDashboard, 
  BookOpen, 
  Warehouse, 
  ArrowLeftRight, 
  ShoppingCart, 
  Settings,
  BookMarked,
  Users,
  ChartColumn,
  FolderTree,
  Building2,
  ShieldCheck,
  Ticket,
  History
} from "lucide-react";
import { useBranch } from "@/context/branch-context";
import { cn } from "@/lib/utils";

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", href: "/dashboard", roles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { icon: BookOpen, label: "Catalog", href: "/catalog", roles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { icon: FolderTree, label: "Categories", href: "/categories", roles: ["ADMIN", "MANAGER"] },
  { icon: Warehouse, label: "Inventory", href: "/inventory", roles: ["ADMIN", "MANAGER", "STAFF"] },
  { icon: ArrowLeftRight, label: "Transfers", href: "/transfers", roles: ["ADMIN", "MANAGER"] },
  { icon: ShoppingCart, label: "Orders", href: "/orders", roles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { icon: Users, label: "Customers", href: "/customers", roles: ["ADMIN", "MANAGER", "SUPPORT"] },
  { icon: Ticket, label: "Coupons", href: "/coupons", roles: ["ADMIN", "MANAGER"] },
  { icon: ShieldCheck, label: "Staff", href: "/staff", roles: ["ADMIN", "MANAGER"] },
  { icon: Building2, label: "Branches", href: "/branches", roles: ["ADMIN"] },
  { icon: ChartColumn, label: "Reports", href: "/reports", roles: ["ADMIN", "MANAGER", "SUPPORT"] },
  { icon: History, label: "Audit Logs", href: "/audit-logs", roles: ["ADMIN"] },
  { icon: Settings, label: "Settings", href: "/settings", roles: ["ADMIN"] },
];

export function Sidebar() {
  const pathname = usePathname();
  const { currentUser } = useBranch();

  const filteredItems = menuItems.filter(item => 
    !item.roles || (currentUser && item.roles.includes(currentUser.role))
  );

  return (
    <aside className="fixed left-0 top-0 z-40 h-screen w-64 border-r border-border bg-white transition-transform">
      <div className="flex h-full flex-col px-3 py-4">
        {/* Logo */}
        <div className="mb-10 flex items-center gap-2 px-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-white">
            <BookMarked size={24} />
          </div>
          <span className="text-xl font-bold tracking-tight text-foreground">
            Digi<span className="text-primary">Book</span>
          </span>
        </div>

        {/* Navigation */}
        <nav className="flex-1 space-y-1">
          {filteredItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-4 py-3 text-sm font-medium transition-colors",
                  isActive 
                    ? "bg-primary/10 text-primary" 
                    : "text-secondary-foreground hover:bg-accent hover:text-foreground"
                )}
              >
                <item.icon size={20} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Footer info (Optional) */}
        <div className="mt-auto px-4 py-4 text-xs text-secondary-foreground opacity-60">
          © 2025 DigiBook Back-office
        </div>
      </div>
    </aside>
  );
}
