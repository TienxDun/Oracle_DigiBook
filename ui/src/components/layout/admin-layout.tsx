"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "./sidebar";
import { Header } from "./header";
import { usePathname, useRouter } from "next/navigation";
import { useBranch } from "@/context/branch-context";

interface AdminLayoutProps {
  children: React.ReactNode;
}

const routeRoleRules: Array<{ prefix: string; allowedRoles: Array<"ADMIN" | "MANAGER" | "STAFF" | "SUPPORT"> }> = [
  { prefix: "/settings", allowedRoles: ["ADMIN"] },
  { prefix: "/transfers", allowedRoles: ["ADMIN", "MANAGER"] },
  { prefix: "/inventory", allowedRoles: ["ADMIN", "MANAGER", "STAFF"] },
  { prefix: "/dashboard", allowedRoles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { prefix: "/catalog", allowedRoles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { prefix: "/orders", allowedRoles: ["ADMIN", "MANAGER", "STAFF", "SUPPORT"] },
  { prefix: "/customers", allowedRoles: ["ADMIN", "MANAGER", "SUPPORT"] },
  { prefix: "/reports", allowedRoles: ["ADMIN", "MANAGER", "SUPPORT"] },
];

function isRouteAllowed(pathname: string, role: "ADMIN" | "MANAGER" | "STAFF" | "SUPPORT") {
  const matchingRule = routeRoleRules.find((rule) => pathname.startsWith(rule.prefix));
  if (!matchingRule) {
    return true;
  }

  return matchingRule.allowedRoles.includes(role);
}

export function AdminLayout({ children }: AdminLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { logout } = useBranch();
  const [isReady, setIsReady] = useState(false);
  
  const isLoginPage = pathname === "/login";

  useEffect(() => {
    setIsReady(false);
    const storedUser = localStorage.getItem("digibook_user");
    
    if (!storedUser) {
      if (!isLoginPage) {
        router.push("/login");
      } else {
        setIsReady(true);
      }
    } else {
      if (isLoginPage) {
        router.push("/dashboard");
      } else {
        try {
          const parsedUser = JSON.parse(storedUser) as { role?: "ADMIN" | "MANAGER" | "STAFF" | "SUPPORT" };

          if (!parsedUser.role || !isRouteAllowed(pathname, parsedUser.role)) {
            router.push("/dashboard");
            return;
          }

          setIsReady(true);
        } catch {
          logout();
          router.push("/login");
        }
      }
    }
  }, [isLoginPage, router, pathname, logout]);

  if (isLoginPage) {
    return <div className="min-h-screen bg-background">{children}</div>;
  }

  if (!isReady && !isLoginPage) {
    return <div className="flex h-screen items-center justify-center bg-white">
      <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent" />
    </div>;
  }

  return (
    <div className="min-h-screen bg-background transition-all duration-500">
      <Sidebar />
      <div className="pl-64">
        <Header />
        <main className="min-h-[calc(100vh-64px)] p-8">
          <div className="mx-auto max-w-7xl animate-in fade-in slide-in-from-bottom-2 duration-500">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
