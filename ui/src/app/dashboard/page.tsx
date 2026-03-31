"use client";

import React, { useState, useEffect } from "react";
import { 
  Users, 
  ShoppingCart, 
  BookOpen, 
  TrendingUp,
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  Building2,
  Package,
  History,
  Info
} from "lucide-react";
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer
} from "recharts";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import type { DashboardStats, BranchInventory } from "@/types/database";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 }
};

export default function Dashboard() {
  const [activeBranchTab, setActiveBranchTab] = useState("ALL");
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [lowStock, setLowStock] = useState<BranchInventory[]>([]);
  const [chartData, setChartData] = useState<any[]>([]);
  const [branchPerformance, setBranchPerformance] = useState<any[]>([]);
  const [activities, setActivities] = useState<any[]>([]);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [statsRes, inventoryRes, revenueRes, performanceRes, activityRes] = await Promise.all([
        fetch("/api/dashboard/stats"),
        fetch("/api/inventory?low_stock=true"),
        fetch("/api/dashboard/revenue"),
        fetch("/api/dashboard/branch-performance"),
        fetch("/api/dashboard/activity")
      ]);

      const statsData = await statsRes.json();
      const inventoryData = await inventoryRes.json();
      const revenueData = await revenueRes.json();
      const performanceData = await performanceRes.json();
      const activityData = await activityRes.json();

      if (statsData.success) setStats(statsData.data);
      if (inventoryData.success) setLowStock(inventoryData.data);
      if (revenueData.success) setChartData(revenueData.data);
      if (performanceData.success) setBranchPerformance(performanceData.data);
      if (activityData.success) setActivities(activityData.data);
    } catch (error) {
      console.error("Failed to fetch dashboard data:", error);
    } finally {
      setLoading(false);
    }
  };

  const kpiCards = [
    { 
      label: "Tổng đơn hàng", 
      value: stats?.TOTAL_ORDERS.toLocaleString() || "0", 
      icon: ShoppingCart, 
      change: stats ? `${stats.ORDERS_CHANGE >= 0 ? '+' : ''}${stats.ORDERS_CHANGE}%` : "0%", 
      isPositive: (stats?.ORDERS_CHANGE ?? 0) >= 0, 
      color: "indigo" 
    },
    { 
      label: "Doanh thu hệ thống", 
      value: stats ? `${(stats.TOTAL_REVENUE / 1000000).toFixed(1)}M` : "0.0M", 
      icon: TrendingUp, 
      change: stats ? `${stats.REVENUE_CHANGE >= 0 ? '+' : ''}${stats.REVENUE_CHANGE}%` : "0%", 
      isPositive: (stats?.REVENUE_CHANGE ?? 0) >= 0, 
      color: "emerald" 
    },
    { 
      label: "Tồn kho tổng", 
      value: stats?.TOTAL_STOCK.toLocaleString() || "0", 
      icon: Package, 
      change: stats ? `${stats.STOCK_CHANGE >= 0 ? '+' : ''}${stats.STOCK_CHANGE}%` : "0%", 
      isPositive: (stats?.STOCK_CHANGE ?? 0) >= 0, 
      color: "rose" 
    },
    { 
      label: "Tổng khách hàng", 
      value: stats?.TOTAL_CUSTOMERS.toLocaleString() || "0", 
      icon: Users, 
      change: stats ? `${stats.CUSTOMERS_CHANGE >= 0 ? '+' : ''}${stats.CUSTOMERS_CHANGE}%` : "0%", 
      isPositive: (stats?.CUSTOMERS_CHANGE ?? 0) >= 0, 
      color: "amber" 
    },
  ];


  return (
    <motion.div 
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-8"
    >
      {/* Page Header */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">Trung tâm Quản trị</h1>
          <p className="text-secondary-foreground font-medium">Báo cáo tổng hợp hoạt động kinh doanh toàn hệ thống DigiBook.</p>
        </div>
        <div className="flex items-center gap-2 rounded-xl bg-accent/20 p-1 border border-border">
          <button 
            onClick={() => setActiveBranchTab("ALL")}
            className={cn(
              "px-4 py-1.5 text-xs font-bold rounded-lg transition-all",
              activeBranchTab === "ALL" ? "bg-white text-primary shadow-sm" : "text-secondary-foreground hover:bg-white/50"
            )}
          >Hệ thống</button>
          <button 
            onClick={() => setActiveBranchTab("BRANCH")}
            className={cn(
              "px-4 py-1.5 text-xs font-bold rounded-lg transition-all",
              activeBranchTab === "BRANCH" ? "bg-white text-primary shadow-sm" : "text-secondary-foreground hover:bg-white/50"
            )}
          >Chi nhánh</button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {loading ? (
          Array(4).fill(0).map((_, i) => (
            <div key={i} className="card-shadow rounded-2xl border border-border bg-white p-6 space-y-4">
              <div className="flex justify-between">
                <Skeleton className="h-12 w-12 rounded-xl" />
                <Skeleton className="h-6 w-16 rounded-full" />
              </div>
              <div className="space-y-2">
                <Skeleton className="h-3 w-20" />
                <Skeleton className="h-8 w-32" />
              </div>
            </div>
          ))
        ) : (
          kpiCards.map((stat) => (
            <motion.div 
              variants={itemVariants}
              key={stat.label} 
              className="group relative overflow-hidden card-shadow rounded-2xl border border-border bg-white p-6 transition-all hover:scale-[1.02]"
            >
              <div className="absolute top-0 right-0 p-3 opacity-5 group-hover:scale-125 transition-transform">
                 <stat.icon size={80} />
              </div>
              <div className="mb-4 flex items-center justify-between">
                <div className={cn(
                  "flex h-12 w-12 items-center justify-center rounded-xl shadow-lg shadow-black/5",
                  stat.color === "indigo" && "bg-indigo-50 text-indigo-600",
                  stat.color === "emerald" && "bg-emerald-50 text-emerald-600",
                  stat.color === "rose" && "bg-rose-50 text-rose-600",
                  stat.color === "amber" && "bg-amber-50 text-amber-600",
                )}>
                  <stat.icon size={22} />
                </div>
                <div className={cn(
                  "flex items-center gap-1 text-xs font-bold px-2 py-1 rounded-full",
                  stat.isPositive ? "bg-emerald-50 text-emerald-600" : "bg-rose-50 text-rose-600"
                )}>
                  {stat.isPositive ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
                  {stat.change}
                </div>
              </div>
              <div className="space-y-1">
                <span className="text-xs font-bold uppercase tracking-widest text-secondary-foreground/60">{stat.label}</span>
                <h2 className="text-2xl font-black text-foreground">{stat.value}</h2>
              </div>
            </motion.div>
          ))
        )}
      </div>

      {/* Main Analysis Section */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Revenue Chart */}
        <motion.div 
          variants={itemVariants}
          className="lg:col-span-2 card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-8 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-foreground">Xu hướng doanh thu</h3>
              <p className="text-xs text-secondary-foreground font-medium">Theo dõi tăng trưởng doanh số trong 7 ngày gần nhất.</p>
            </div>
            <select className="rounded-lg border border-border bg-accent/10 px-3 py-1.5 text-xs font-bold outline-none focus:ring-1 focus:ring-primary">
              <option>Theo tuần</option>
              <option>Theo tháng</option>
            </select>
          </div>
          
          <div className="h-[300px] w-full min-w-0">
            {loading ? (
              <div className="h-full w-full flex items-center justify-center bg-accent/5 rounded-xl border border-dashed border-border">
                <div className="flex flex-col items-center gap-2">
                  <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                  <span className="text-xs font-bold text-secondary-foreground">Đang tải biểu đồ...</span>
                </div>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%" minWidth={0}>
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorTotal" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#6366f1" stopOpacity={0.2}/>
                      <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis 
                    dataKey="name" 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: "#64748b", fontSize: 11, fontWeight: 600 }}
                    dy={10}
                  />
                  <YAxis 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: "#64748b", fontSize: 11, fontWeight: 600 }}
                    tickFormatter={(val) => `${(val / 1000000).toFixed(1)}M`}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      borderRadius: "12px", 
                      border: "none", 
                      boxShadow: "0 10px 15px -3px rgb(0 0 0 / 0.1)",
                      fontSize: "12px",
                      fontWeight: "bold"
                    }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="total" 
                    stroke="#6366f1" 
                    strokeWidth={3}
                    fillOpacity={1} 
                    fill="url(#colorTotal)" 
                    animationDuration={2000}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </motion.div>

        {/* Branch Performance */}
        <motion.div 
          variants={itemVariants}
          className="card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-8">
            <h3 className="text-lg font-bold text-foreground">Hiệu suất chi nhánh</h3>
            <p className="text-xs text-secondary-foreground font-medium">So sánh doanh số thực tế so với mục tiêu đề ra.</p>
          </div>

          <div className="space-y-8">
            {branchPerformance.map((branch) => {
              return (
                <div key={branch.name} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className="h-2 w-2 rounded-full bg-primary" />
                      <span className="font-bold text-foreground">{branch.name}</span>
                    </div>
                    <span className="font-bold text-foreground">{(branch.value / 1000000).toFixed(1)}M <span className="text-[10px] text-secondary-foreground">/ 0.5M</span></span>
                  </div>
                  <div className="h-2 w-full overflow-hidden rounded-full bg-accent/30">
                    <motion.div 
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min(branch.progress, 100)}%` }}
                      transition={{ duration: 1.5, ease: "easeOut" }}
                      className="h-full rounded-full bg-primary" 
                    />
                  </div>
                  <div className="flex justify-end">
                    <span className="text-[10px] font-black uppercase text-secondary-foreground/60">{branch.progress.toFixed(1)}% Hoàn thành</span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="mt-10 rounded-xl bg-accent/20 p-4 border border-border border-dashed">
             <div className="flex gap-3">
                <div className="shrink-0 pt-1">
                   <Info className="text-primary" size={16} />
                </div>
                <p className="text-[11px] font-medium leading-relaxed text-secondary-foreground">Hệ thống đang hoạt động ổn định. Các chỉ số doanh thu được cập nhật theo thời gian thực từ Oracle 19c.</p>
             </div>
          </div>
        </motion.div>
      </div>

      {/* Bottom Grid: Activity & Alerts */}
      <div className="grid gap-6 lg:grid-cols-2">
         {/* Activity Feed */}
         <motion.div 
          variants={itemVariants}
          className="card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-6 flex items-center justify-between font-bold">
            <div className="flex items-center gap-2">
              <History size={18} className="text-primary" />
              <h3 className="text-lg text-foreground">Hoạt động gần đây</h3>
            </div>
            <button className="text-xs text-primary hover:underline">Xem tất cả</button>
          </div>
          
          <div className="space-y-6">
            {activities.length > 0 ? (
              activities.map((activity) => (
                <div key={activity.id} className="group relative flex gap-4 pl-4 transition-all">
                  <div className={cn(
                    "absolute left-0 h-full w-[2px] transition-colors",
                    activity.status === 'success' ? "bg-emerald-500" : activity.status === 'info' ? "bg-blue-500" : "bg-amber-500"
                  )} />
                  <div className="flex-1 space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-bold text-foreground">{activity.title}</span>
                      <span className="text-[10px] font-bold text-secondary-foreground bg-accent px-1.5 py-0.5 rounded uppercase">{activity.time}</span>
                    </div>
                    <p className="text-xs text-secondary-foreground">{activity.description}</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="py-10 text-center text-sm text-secondary-foreground">Không có hoạt động mới</div>
            )}
          </div>
        </motion.div>

        {/* Low Stock Alerts */}
        <motion.div 
          variants={itemVariants}
          className="card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-6 flex items-center justify-between font-bold">
            <div className="flex items-center gap-2">
              <AlertCircle size={18} className={cn(lowStock.length > 0 ? "text-rose-500" : "text-emerald-500")} />
              <h3 className="text-lg text-foreground font-black">Cảnh báo tồn kho thấp</h3>
            </div>
            <span className={cn(
              "rounded-full px-2 py-1 text-[10px] shadow-sm border",
              lowStock.length > 0 ? "bg-rose-50 text-rose-600 border-rose-100" : "bg-emerald-50 text-emerald-600 border-emerald-100"
            )}>
              {lowStock.length} vật phẩm
            </span>
          </div>

          <div className="space-y-4">
             {loading ? (
                Array(3).fill(0).map((_, i) => (
                  <div key={i} className="flex items-center justify-between p-3 rounded-xl border border-border">
                    <div className="flex items-center gap-3">
                      <Skeleton className="h-10 w-10 rounded" />
                      <div className="space-y-1">
                        <Skeleton className="h-3 w-32" />
                        <Skeleton className="h-2 w-16" />
                      </div>
                    </div>
                    <Skeleton className="h-8 w-16 rounded-lg" />
                  </div>
                ))
             ) : lowStock.length > 0 ? (
                lowStock.slice(0, 5).map((item) => (
                  <div key={item.INVENTORY_ID} className="flex items-center justify-between p-3 rounded-xl border border-border hover:bg-accent/10 transition-colors">
                    <div className="flex items-center gap-3">
                        <div className="h-10 w-10 overflow-hidden rounded bg-accent/30 flex items-center justify-center">
                          <BookOpen size={16} className="text-secondary-foreground" />
                        </div>
                        <div className="max-w-[200px] overflow-hidden">
                          <h4 className="text-sm font-bold text-foreground truncate">{item.BOOK_TITLE}</h4>
                          <span className="text-[10px] font-medium text-secondary-foreground uppercase">{item.BRANCH_NAME}</span>
                        </div>
                    </div>
                    <div className="flex flex-col items-end">
                        <span className="text-xs font-black text-rose-600">{item.QUANTITY_AVAILABLE} cuốn</span>
                        <span className="text-[9px] font-bold uppercase text-secondary-foreground tracking-tighter cursor-pointer hover:text-primary">Điều phối ngay →</span>
                    </div>
                  </div>
                ))
             ) : (
                <div className="flex flex-col items-center justify-center py-10 text-center space-y-2">
                  <div className="h-12 w-12 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
                    <Package size={24} />
                  </div>
                  <p className="text-sm font-bold text-foreground">Kho hàng an toàn</p>
                  <p className="text-xs text-secondary-foreground">Không có sách nào dưới ngưỡng tồn kho.</p>
                </div>
             )}
          </div>
        </motion.div>
      </div>
    </motion.div>
  );
}
