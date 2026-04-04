// TypeScript interfaces mapping các bảng chính trong 2_create_tables.sql

export interface Branch {
  BRANCH_ID: number;
  BRANCH_CODE: string;
  BRANCH_NAME: string;
  BRANCH_TYPE: "STORE" | "WAREHOUSE" | "ONLINE_ONLY";
  ADDRESS: string;
  PROVINCE: string;
  DISTRICT: string;
  PHONE: string;
  EMAIL: string;
  STATUS: "ACTIVE" | "INACTIVE" | "CLOSED";
  IS_MAIN_BRANCH: 0 | 1;
}

export interface User {
  USER_ID: number;
  USERNAME: string;
  EMAIL: string;
  FULL_NAME: string;
  ROLE: "ADMIN" | "MANAGER" | "STAFF" | "SUPPORT";
  PHONE: string;
  IS_ACTIVE: 0 | 1;
  LAST_LOGIN_AT: Date;
}

export interface Book {
  BOOK_ID: number;
  ISBN: string;
  TITLE: string;
  DESCRIPTION: string;
  CATEGORY_ID: number;
  CATEGORY_NAME: string;
  PUBLISHER_ID: number;
  PUBLISHER_NAME: string;
  PRICE: number;
  STOCK_QUANTITY: number;
  PAGE_COUNT: number;
  PUBLICATION_YEAR: number;
  LANGUAGE: string;
  COVER_TYPE: string;
  IS_FEATURED: 0 | 1;
  IS_ACTIVE: 0 | 1;
  VIEW_COUNT: number;
  SOLD_COUNT: number;
  AUTHOR_NAMES: string; // Concatenated author names
  COVER_URL?: string;
  CREATED_AT: Date;
  UPDATED_AT: Date;
}

export interface Order {
  ORDER_ID: number;
  ORDER_CODE: string;
  CUSTOMER_ID: number;
  CUSTOMER_NAME: string;
  CUSTOMER_PHONE: string;
  BRANCH_ID: number;
  BRANCH_NAME: string;
  STATUS_CODE: string;
  STATUS_NAME_VI: string;
  STATUS_COLOR: string;
  TOTAL_AMOUNT: number;
  DISCOUNT_AMOUNT: number;
  SHIPPING_FEE: number;
  FINAL_AMOUNT: number;
  SHIP_ADDRESS: string;
  SHIP_DISTRICT: string;
  SHIP_PROVINCE: string;
  SHIP_PHONE: string;
  PAYMENT_METHOD: string;
  PAYMENT_STATUS: string;
  NOTE: string;
  ORDER_DATE: string;
  CREATED_AT: string;
  UPDATED_AT: string | null;
}

export interface BranchInventory {
  INVENTORY_ID: number;
  BRANCH_ID: number;
  BRANCH_NAME: string;
  BOOK_ID: number;
  BOOK_TITLE: string;
  ISBN: string;
  QUANTITY_AVAILABLE: number;
  LOW_STOCK_THRESHOLD: number;
  LAST_STOCK_IN_AT: Date;
}

export interface InventoryTransfer {
  TRANSFER_ID: number;
  TRANSFER_CODE: string;
  FROM_BRANCH_ID: number;
  FROM_BRANCH_NAME: string;
  TO_BRANCH_ID: number;
  TO_BRANCH_NAME: string;
  STATUS: string;
  TRANSFER_DATE: Date;
  COMPLETED_DATE: Date;
  CREATED_AT: Date;
}

export interface DashboardStats {
  TOTAL_ORDERS: number;
  TOTAL_REVENUE: number;
  TOTAL_STOCK: number;
  TOTAL_CUSTOMERS: number;
  PENDING_ORDERS: number;
  LOW_STOCK_COUNT: number;
  ORDERS_CHANGE: number;
  REVENUE_CHANGE: number;
  STOCK_CHANGE: number;
  CUSTOMERS_CHANGE: number;
}

