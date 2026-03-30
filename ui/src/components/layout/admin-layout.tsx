"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "./sidebar";
import { Header } from "./header";
import { usePathname, useRouter } from "next/navigation";
import { useBranch } from "@/context/branch-context";
import { cn } from "@/lib/utils";

interface AdminLayoutProps {
  children: React.ReactNode;
}

export function AdminLayout({ children }: AdminLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { currentUser } = useBranch();
  const [isReady, setIsReady] = useState(false);
  
  const isLoginPage = pathname === "/login";

  useEffect(() => {
    const storedUser = localStorage.getItem("digibook_user");
    if (!storedUser && !isLoginPage) {
      router.push("/login");
    } else {
      setIsReady(true);
    }
  }, [isLoginPage, router]);

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
