"use client";

import React, { useState } from "react";
import { BookMarked, Lock, User, ArrowRight, ShieldCheck } from "lucide-react";
import { useRouter } from "next/navigation";
import { useBranch, branches } from "@/context/branch-context";
import { toast } from "sonner";

export default function LoginPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const { login } = useBranch();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password })
      });

      const data = await res.json();

      if (data.success) {
        login({
          id: data.user.id,
          name: data.user.fullName,
          role: data.user.role,
          branchId: data.user.branchId,
        });
        toast.success(data.message);
        router.push("/dashboard");
      } else {
        toast.error(data.message);
      }
    } catch (error) {
      toast.error("Lỗi kết nối máy chủ");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-accent/30 p-4">
      <div className="w-full max-w-md space-y-8 rounded-2xl border border-border bg-white p-10 shadow-2xl animate-in fade-in zoom-in duration-500">
        {/* Logo Section */}
        <div className="flex flex-col items-center">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary text-white shadow-lg shadow-primary/20">
            <BookMarked size={36} />
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            Digi<span className="text-primary">Book</span>
          </h1>
          <p className="mt-2 text-sm font-medium text-secondary-foreground uppercase tracking-widest">
            Back-office Portal
          </p>
        </div>

        {/* Form Section */}
        <form onSubmit={handleLogin} className="mt-8 space-y-6">
          <div className="space-y-4">
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-wider text-secondary-foreground ml-1">
                Tài khoản
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 flex items-center pl-3 text-secondary-foreground group-focus-within:text-primary transition-colors">
                  <User size={18} />
                </div>
                <input
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full rounded-xl border border-border bg-accent/20 py-3 pl-10 pr-4 text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  placeholder="Nhập tên đăng nhập..."
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-wider text-secondary-foreground ml-1">
                Mật khẩu
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 flex items-center pl-3 text-secondary-foreground group-focus-within:text-primary transition-colors">
                  <Lock size={18} />
                </div>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-xl border border-border bg-accent/20 py-3 pl-10 pr-4 text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  placeholder="••••••••"
                />
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between px-1">
            <label className="flex items-center gap-2 cursor-pointer group">
              <input type="checkbox" className="h-4 w-4 rounded border-border text-primary focus:ring-primary" />
              <span className="text-xs text-secondary-foreground group-hover:text-foreground transition-colors font-medium">Ghi nhớ đăng nhập</span>
            </label>
            <a href="#" className="text-xs font-bold text-primary hover:underline">Quên mật khẩu?</a>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="group relative flex w-full items-center justify-center overflow-hidden rounded-xl bg-primary py-3.5 text-sm font-bold text-white shadow-lg shadow-primary/30 transition-all hover:bg-primary-hover active:scale-[0.98] disabled:opacity-70"
          >
            {isLoading ? (
              <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              <>
                Đăng nhập ngay
                <ArrowRight size={18} className="ml-2 transition-transform group-hover:translate-x-1" />
              </>
            )}
          </button>
        </form>

        {/* Footer Info */}
        <div className="mt-8 flex flex-col items-center gap-4 border-t border-border pt-6">
          <div className="flex items-center gap-2 text-[10px] text-secondary-foreground font-medium uppercase tracking-widest">
            <ShieldCheck size={14} className="text-success" />
            Secure Management Environment
          </div>
          <p className="text-center text-[10px] text-secondary-foreground">
            © 2025 DigiBook Inc. All rights reserved. <br/>
            Truy cập bị hạn chế bởi chính sách bảo mật nội bộ.
          </p>
        </div>
      </div>
    </div>
  );
}
