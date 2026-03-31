import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AdminLayout } from "@/components/layout/admin-layout";
import { BranchProvider } from "@/context/branch-context";
import { Toaster } from "sonner";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "DigiBook | Back-office",
  description: "Advanced multi-branch bookstore management system.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi">
      <body className={`${inter.className} antialiased`}>
        <BranchProvider>
          <AdminLayout>
            {children}
          </AdminLayout>
          <Toaster richColors position="top-right" />
        </BranchProvider>
      </body>
    </html>
  );
}
