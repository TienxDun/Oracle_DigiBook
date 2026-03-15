# PL/SQL for IoTSmart

‣ 

```SQL
IOTSMART_DATABASE
│
├── 1️⃣ DATA INTEGRITY (BẮT BUỘC)
│   │
│   ├── Constraints
│   │   ├── PK / FK
│   │   ├── UNIQUE (SKU, invoice_number)
│   │   ├── CHECK (status, quantity >= 0)
│   │   └── NOT NULL
│   │
│   ├── Stock Protection
│   │   ├── SELECT FOR UPDATE (row locking)
│   │   ├── Prevent negative stock (trigger/check)
│   │   └── Atomic stock deduction procedure
│   │
│   └── Invoice Protection
│       ├── Unique invoice number
│       ├── Lock issued invoice (BEFORE UPDATE trigger)
│       └── State transition validation
│
├── 2️⃣ TRANSACTION CONTROL (CRITICAL)
│   │
│   ├── finalize_order_tx procedure
│   │   ├── Deduct stock
│   │   ├── Insert inventory_transaction
│   │   ├── Calculate VAT
│   │   ├── Create invoice
│   │   └── Commit / Rollback
│   │
│   └── Concurrency handling
│       ├── Row-level locking
│       ├── Deadlock safety
│       └── Exception management
│
├── 3️⃣ AUDIT & TRACEABILITY
│   │
│   ├── inventory_transaction table
│   ├── salary/order/invoice audit triggers
│   ├── error_log table
│   └── pkg_audit.log_error procedure
│
├── 4️⃣ TAX & FINANCIAL CONSISTENCY
│   │
│   ├── VAT calculation function
│   ├── tax_rate effective-date logic
│   ├── total_with_vat computation
│   └── Deterministic financial calculation
│
├── 5️⃣ PERFORMANCE OPTIMIZATION
│   │
│   ├── Proper indexing
│   ├── Composite PK (stock)
│   ├── Materialized view (revenue summary)
│   ├── DBMS_SCHEDULER jobs
│   └── Bulk processing (FORALL, BULK COLLECT)
│
├── 6️⃣ SECURITY & ACCESS CONTROL
│   │
│   ├── Role-based GRANT
│   ├── Revoke direct DML from app user
│   ├── API-style stored procedures
│   └── Optional VPD (row-level security)
│
└── 7️⃣ REPORTING SUPPORT (NOT FULL BI)
    │
    ├── Pre-aggregated revenue views
    ├── Inventory snapshot logic
    └── Monthly tax export procedure
```

- [📄 IoTSmart - VIEW](./IoTSmart - VIEW/IoTSmart - VIEW.md)

- [📄 IoTSmart - PACKAGE INVENTORY](./IoTSmart - PACKAGE INVENTORY/IoTSmart - PACKAGE INVENTORY.md)

- [📄 IoTSmart - TRIGGER](./IoTSmart - TRIGGER/IoTSmart - TRIGGER.md)

- [📄 IoTSmart - SALES FINALIZE TRANSACTION](./IoTSmart - SALES FINALIZE TRANSACTION/IoTSmart - SALES FINALIZE TRANSACTION.md)

