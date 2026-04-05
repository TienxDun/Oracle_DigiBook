import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Oracle 19c Dev Console",
  description: "Trình điều khiển kiểm thử chuyên biệt cho Procedures, Triggers, Views và Bảo mật vai trò.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="vi" suppressHydrationWarning>
      <body>{children}</body>
    </html>
  );
}
