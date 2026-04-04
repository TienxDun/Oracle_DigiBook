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
  Globe
} from "lucide-react";
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend
} from "recharts";
import { motion, AnimatePresence } from "framer-motion";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { useBranch, SYSTEM_BRANCH } from "@/context/branch-context";
import { StockInDrawer } from "@/components/inventory/stock-in-drawer";
import { toast } from "sonner";
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
  const { currentBranch, currentUser } = useBranch();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [lowStock, setLowStock] = useState<BranchInventory[]>([]);
  const [chartData, setChartData] = useState<any[]>([]);
  const [branchPerformance, setBranchPerformance] = useState<any[]>([]);
  const [orderStatus, setOrderStatus] = useState<any[]>([]);
  const [activities, setActivities] = useState<any[]>([]);
  const [mounted, setMounted] = useState(false);
  const [isStockInOpen, setIsStockInOpen] = useState(false);
  const [selectedStockData, setSelectedStockData] = useState<{bookId?: number, branchId?: number}>({});

  useEffect(() => {
    setMounted(true);
    fetchDashboardData();
  }, [currentBranch]);

  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const branchId = currentBranch?.id || "ALL";
      const [statsRes, inventoryRes, revenueRes, performanceRes, activityRes, statusRes] = await Promise.all([
        fetch(`/api/dashboard/stats?branchId=${branchId}`),
        fetch(`/api/inventory?low_stock=true&branchId=${branchId}`),
        fetch(`/api/dashboard/revenue?branchId=${branchId}`),
        fetch(`/api/dashboard/branch-performance?branchId=${branchId}`),
        fetch(`/api/dashboard/activity?branchId=${branchId}`),
        fetch(`/api/dashboard/order-status?branchId=${branchId}`)
      ]);

      const statsData = await statsRes.json();
      const inventoryData = await inventoryRes.json();
      const revenueData = await revenueRes.json();
      const performanceData = await performanceRes.json();
      const activityData = await activityRes.json();
      const statusData = await statusRes.json();

      if (statsData.success) setStats(statsData.data);
      if (inventoryData.success) setLowStock(inventoryData.data);
      if (revenueData.success) setChartData(revenueData.data);
      if (performanceData.success) setBranchPerformance(performanceData.data);
      if (activityData.success) setActivities(activityData.data);
      if (statusData.success) setOrderStatus(statusData.data);
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
      value: stats ? `${((stats.TOTAL_REVENUE || 0) / 1000000).toFixed(1)}M` : "0.0M", 
      icon: TrendingUp, 
      change: stats ? `${(stats.REVENUE_CHANGE || 0) >= 0 ? '+' : ''}${stats.REVENUE_CHANGE || 0}%` : "0%", 
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
          <h1 className="text-3xl font-extrabold tracking-tight text-foreground">
            {currentBranch?.id === "ALL" ? "Hệ thống DigiBook" : `Chi nhánh ${currentBranch?.name}`}
          </h1>
          <p className="text-secondary-foreground font-medium">
            {currentBranch?.id === "ALL" 
              ? "Báo cáo tổng hợp hoạt động kinh doanh toàn hệ thống." 
              : `Báo cáo chi tiết hoạt động kinh doanh tại ${currentBranch?.name}.`
            }
          </p>
        </div>
        
        {currentBranch?.id === "ALL" && (
          <div className="flex items-center gap-2 rounded-xl bg-emerald-500/10 border border-emerald-500/20 px-4 py-2 shadow-sm">
             <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
             <span className="text-xs font-bold text-emerald-700 uppercase tracking-wider">Chế độ Tổng kết Toàn hệ thống</span>
          </div>
        )}
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

      {/* Charts Grid */}
      <div className="grid gap-8 lg:grid-cols-3">
        {/* Revenue Chart */}
        <motion.div 
          variants={itemVariants}
          className="lg:col-span-2 card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-8 flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-foreground">Xu hướng doanh thu</h3>
              <p className="text-xs text-secondary-foreground font-medium">Phân tích biến động doanh số trong 30 ngày gần nhất.</p>
            </div>
            <div className={cn(
              "flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-[10px] font-black uppercase tracking-wider",
              currentBranch?.id === "ALL" ? "bg-emerald-50 text-emerald-600 border-emerald-100" : "bg-indigo-50 text-indigo-600 border-indigo-100"
            )}>
              {currentBranch?.id === "ALL" ? <Globe size={12} /> : <Building2 size={12} />}
              {currentBranch?.id === "ALL" ? "Toàn hệ thống" : "Chi nhánh hiện tại"}
            </div>
          </div>
          
          <div className="h-[350px] w-full min-w-0">
            {loading ? (
              <div className="h-full w-full flex items-center justify-center bg-accent/5 rounded-xl border border-dashed border-border">
                <div className="flex flex-col items-center gap-2">
                  <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                  <span className="text-xs font-bold text-secondary-foreground">Đang tải phân tích...</span>
                </div>
              </div>
            ) : (
              mounted && chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={currentBranch?.id === "ALL" ? "#10b981" : "#6366f1"} stopOpacity={0.3}/>
                      <stop offset="95%" stopColor={currentBranch?.id === "ALL" ? "#10b981" : "#6366f1"} stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis 
                    dataKey="name" 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: "#64748b", fontSize: 10, fontWeight: 600 }}
                    minTickGap={30}
                    dy={10}
                  />
                  <YAxis 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: "#64748b", fontSize: 10, fontWeight: 600 }}
                    tickFormatter={(val) => `${(val / 1000000).toFixed(1)}M`}
                  />
                  <Tooltip 
                    content={({ active, payload, label }) => {
                      if (active && payload && payload.length) {
                        return (
                          <div className="glass rounded-xl border border-border/50 p-3 shadow-xl">
                            <p className="mb-1 text-[10px] font-black uppercase text-secondary-foreground/60">{label}</p>
                            <p className="text-sm font-black text-foreground">
                              {Number(payload[0].value).toLocaleString('vi-VN')}
                              <span className="ml-1 text-[10px] text-secondary-foreground">VNĐ</span>
                            </p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="total" 
                    stroke={currentBranch?.id === "ALL" ? "#10b981" : "#6366f1"} 
                    strokeWidth={4}
                    fillOpacity={1} 
                    fill="url(#colorRevenue)" 
                    animationDuration={2000}
                  />
                </AreaChart>
              </ResponsiveContainer>
              ) : (
                <div className="h-full w-full flex items-center justify-center bg-accent/5 rounded-xl border border-dashed border-border text-center p-6">
                  <div className="flex flex-col items-center gap-2 text-secondary-foreground/40">
                    <TrendingUp size={48} />
                    <span className="text-sm font-bold">Chưa có dữ liệu giao dịch trong 30 ngày</span>
                  </div>
                </div>
              )
            )}
          </div>
        </motion.div>

        {/* Order Status Pie Chart */}
        <motion.div 
          variants={itemVariants}
          className="card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-8">
            <h3 className="text-lg font-bold text-foreground">Trạng thái đơn hàng</h3>
            <p className="text-xs text-secondary-foreground font-medium">Tỷ lệ phân bổ trạng thái đơn hàng.</p>
          </div>

          <div className="h-[350px] w-full flex items-center justify-center">
            {loading ? (
               <Skeleton className="h-48 w-48 rounded-full" />
            ) : orderStatus.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={orderStatus}
                    cx="50%"
                    cy="45%"
                    innerRadius={70}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                    animationDuration={1500}
                  >
                    {orderStatus.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} stroke="none" />
                    ))}
                  </Pie>
                  <Tooltip 
                     content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        return (
                          <div className="glass rounded-xl border border-border/50 p-3 shadow-xl">
                            <div className="flex items-center gap-2 mb-1">
                               <div className="h-2 w-2 rounded-full" style={{ backgroundColor: payload[0].payload.color }} />
                               <span className="text-xs font-bold text-foreground">{payload[0].name}</span>
                            </div>
                            <p className="text-sm font-black text-foreground">
                              {payload[0].value} <span className="text-[10px] text-secondary-foreground font-medium">đơn hàng</span>
                            </p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Legend 
                    verticalAlign="bottom" 
                    height={36}
                    content={({ payload }) => (
                      <div className="flex flex-wrap justify-center gap-x-4 gap-y-2 mt-4">
                        {payload?.map((entry: any, index) => (
                          <div key={index} className="flex items-center gap-1.5">
                            <div className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.color }} />
                            <span className="text-[10px] font-bold text-secondary-foreground whitespace-nowrap">
                              {entry.value}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-secondary-foreground/40">
                <ShoppingCart size={48} className="mx-auto mb-2" />
                <p className="text-sm font-bold">Chưa có dữ liệu đơn hàng</p>
              </div>
            )}
          </div>
        </motion.div>
      </div>

      {/* Row 3: Branch Performance & Recent Activity */}
      <div className="grid gap-8 lg:grid-cols-3">
        {/* Branch Performance */}
        <motion.div 
          variants={itemVariants}
          className="card-shadow rounded-2xl border border-border bg-white p-6"
        >
          <div className="mb-8">
            <h3 className="text-lg font-bold text-foreground">Xếp hạng chi nhánh</h3>
            <p className="text-xs text-secondary-foreground font-medium">Tỷ trọng đóng góp doanh thu thực tế.</p>
          </div>

          <div className="space-y-6">
            {branchPerformance.length > 0 ? branchPerformance.map((branch, index) => {
              return (
                <div key={`${branch.name}-${index}`} className="space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-foreground truncate max-w-[150px]">{branch.name}</span>
                    <span className="font-black text-primary">
                      {Math.min(branch.progress || 0, 100)}%
                    </span>
                  </div>
                  <div className="h-1.5 w-full overflow-hidden rounded-full bg-accent/30">
                    <motion.div 
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min(branch.progress || 0, 100)}%` }}
                      transition={{ duration: 1.5, ease: "easeOut" }}
                      className={cn(
                        "h-full rounded-full shadow-sm",
                        currentBranch?.id === "ALL" ? "bg-emerald-500" : "bg-primary"
                      )} 
                    />
                  </div>
                </div>
              );
            }) : (
              <div className="flex flex-col items-center justify-center py-8 text-secondary-foreground/30">
                <TrendingUp size={32} className="mb-2" />
                <p className="text-xs font-bold">Chưa có báo cáo đóng góp</p>
              </div>
            )}
          </div>
        </motion.div>

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
              activities.map((activity, index) => (
                <div key={activity.id || `activity-${index}`} className="group relative flex gap-4 pl-4 transition-all">
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
                lowStock.slice(0, 5).map((item, index) => {
                  const isNotDistributed = !item.BRANCH_NAME;
                  const isOutOfStock = Number(item.QUANTITY_AVAILABLE) === 0;
                  
                  return (
                    <div key={item.INVENTORY_ID || `lowstock-${item.BOOK_ID || index}`} className="group flex items-center justify-between p-3 rounded-xl border border-border hover:bg-accent/10 transition-all">
                      <div className="flex items-center gap-3 overflow-hidden">
                          <div className={cn(
                            "h-10 w-10 shrink-0 overflow-hidden rounded flex items-center justify-center border",
                            isNotDistributed ? "bg-indigo-50 border-indigo-100" : "bg-accent/30 border-border"
                          )}>
                            <BookOpen size={16} className={cn(isNotDistributed ? "text-indigo-600" : "text-secondary-foreground")} />
                          </div>
                          <div className="min-w-0 flex-1">
                            <h4 className="text-sm font-bold text-foreground truncate group-hover:text-primary transition-colors">{item.BOOK_TITLE}</h4>
                            <div className="flex items-center gap-2 mt-0.5">
                              {isNotDistributed ? (
                                <span className="flex items-center gap-1 text-[9px] font-black bg-indigo-50 text-indigo-600 px-1.5 py-0.5 rounded border border-indigo-100 uppercase tracking-tighter">
                                  <Globe size={10} /> Chưa phân phối
                                </span>
                              ) : (
                                <span className="text-[10px] font-medium text-secondary-foreground uppercase truncate max-w-[120px]">{item.BRANCH_NAME}</span>
                              )}
                            </div>
                          </div>
                      </div>
                      <div className="flex flex-col items-end shrink-0 ml-4">
                          <span className={cn(
                            "text-xs font-black",
                            isOutOfStock ? "text-rose-600" : "text-amber-600"
                          )}>
                            {item.QUANTITY_AVAILABLE} cuốn
                          </span>
                          <span 
                            onClick={() => {
                              setSelectedStockData({
                                bookId: item.BOOK_ID,
                                branchId: item.BRANCH_ID || (currentBranch?.id !== "ALL" ? Number(currentBranch?.id) : undefined)
                              });
                              setIsStockInOpen(true);
                            }}
                            className={cn(
                              "text-[9px] font-bold uppercase tracking-tighter cursor-pointer hover:underline mt-1",
                              isNotDistributed ? "text-indigo-600" : "text-primary"
                            )}
                          >
                            {isNotDistributed ? "Phân bổ ngay →" : "Hàng về →"}
                          </span>
                      </div>
                    </div>
                  );
                })
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

      <StockInDrawer 
        isOpen={isStockInOpen}
        onClose={() => setIsStockInOpen(false)}
        onSuccess={fetchDashboardData}
        initialBookId={selectedStockData.bookId}
        initialBranchId={selectedStockData.branchId}
      />
    </motion.div>
  );
}
