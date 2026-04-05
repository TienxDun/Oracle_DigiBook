"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { Database, Lock, User, Key, LogIn, AlertCircle, ShieldAlert } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const [oracleUser, setOracleUser] = useState("DIGIBOOK_ADMIN");
  const [oraclePassword, setOraclePassword] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setMessage("");

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ oracleUser, oraclePassword }),
        credentials: "include",
      });

      const data = await response.json();
      if (!response.ok || !data.success) {
        setMessage(data.message ?? "Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.");
        return;
      }

      router.push("/dashboard");
    } catch {
      setMessage("Không thể kết nối được với máy chủ.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="container narrow">
      <div className="card stack mt-70 glass animate-in fade-in slide-in-from-bottom-4 duration-500">
        <div className="flex flex-col items-center gap-2 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10 text-primary mb-2 shadow-inner">
                <Database size={32} />
            </div>
            <h1 className="no-margin text-2xl font-black tracking-tight">Oracle 19c Dev Console</h1>
            <p className="no-margin muted">
                Công cụ kiểm thử đặc quyền cơ sở dữ liệu dành cho nhà phát triển.
            </p>
        </div>

        <div className="my-4 rounded-lg border border-amber-100 bg-amber-50 p-4 flex gap-3 items-start">
            <ShieldAlert className="text-amber-600 shrink-0 mt-0.5" size={18} />
            <p className="text-xs text-amber-800 leading-relaxed font-medium">
                Đây là khu vực dành riêng cho nhà phát triển. Vui lòng sử dụng tài khoản Oracle (DIGIBOOK_ADMIN/STAFF) đã được tạo từ script bảo mật.
            </p>
        </div>

        <form className="stack gap-6" onSubmit={onSubmit}>
          <label>
            <div className="flex items-center gap-2 mb-1">
                <User size={14} className="text-primary" />
                <span>Tên đăng nhập Oracle</span>
            </div>
            <input 
                value={oracleUser} 
                onChange={(e) => setOracleUser(e.target.value.toUpperCase())} 
                placeholder="Ví dụ: DIGIBOOK_ADMIN"
                required 
            />
          </label>
          <label>
            <div className="flex items-center gap-2 mb-1">
                <Key size={14} className="text-primary" />
                <span>Mật khẩu cơ sở dữ liệu</span>
            </div>
            <input 
                type="password" 
                value={oraclePassword} 
                onChange={(e) => setOraclePassword(e.target.value)} 
                placeholder="••••••••••••"
                required 
            />
          </label>
          <button type="submit" disabled={busy} className="mt-2 h-12 shadow-md">
            {busy ? (
                <>
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    Đang xác thực...
                </>
            ) : (
                <>
                    <LogIn size={18} />
                    Đăng nhập hệ thống
                </>
            )}
          </button>
          {message ? (
            <div className="danger-text flex items-center gap-2 p-3 bg-destructive/5 rounded-lg border border-destructive/10">
                <AlertCircle size={16} />
                {message}
            </div>
          ) : null}
        </form>

        <div className="mt-6 border-t border-border pt-4 text-center">
            <p className="text-[10px] uppercase font-bold tracking-widest text-muted-foreground/60">
                &copy; 2026 DigiBook Back-office Infrastructure
            </p>
        </div>
      </div>
    </main>
  );
}
