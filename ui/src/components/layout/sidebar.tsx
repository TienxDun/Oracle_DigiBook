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
  BookMarked
} from "lucide-react";
import { cn } from "@/lib/utils";

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", href: "/dashboard" },
  { icon: BookOpen, label: "Catalog", href: "/catalog" },
  { icon: Warehouse, label: "Inventory", href: "/inventory" },
  { icon: ArrowLeftRight, label: "Transfers", href: "/transfers" },
  { icon: ShoppingCart, label: "Orders", href: "/orders" },
  { icon: Settings, label: "Settings", href: "/settings" },
];

export function Sidebar() {
  const pathname = usePathname();

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
          {menuItems.map((item) => {
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
