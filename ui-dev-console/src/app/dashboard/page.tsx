"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Activity,
  AlertCircle,
  BarChart3,
  CheckCircle2,
  ClipboardCheck,
  Database,
  ExternalLink,
  FileCode,
  Info,
  LogOut,
  Play,
  RotateCcw,
  Search,
  ShieldCheck,
  Terminal,
  TableProperties
} from "lucide-react";
import { cn } from "@/lib/utils";

type JsonValue = Record<string, unknown> | unknown[] | string | number | boolean | null;
type ModuleKey = "views" | "procedures" | "triggers" | "security";

type ApiJson = {
  success?: boolean;
  message?: string;
  code?: string | number;
  [key: string]: unknown;
};

type RubricStatus = "met" | "partial" | "unmet" | "manual";

type RubricItem = {
  id: number;
  title: string;
  weight: number;
  requirement: string;
  status: RubricStatus;
  scoreAwarded: number;
  detail: string;
  evidence: Record<string, unknown>;
};

type RubricSummary = {
  totalWeight: number;
  totalAwarded: number;
  completionPercent: number;
};

type ProcedureName =
  | "SP_MANAGE_BOOK"
  | "SP_REPORT_MONTHLY_SALES"
  | "SP_PRINT_LOW_STOCK_INVENTORY"
  | "SP_CALCULATE_COUPON_DISCOUNT";

type TriggerScenario = "orders_validation_formula_error" | "orders_audit_probe" | "inventory_sync_probe";

type SecurityMatrix = Record<string, Record<string, string[]>>;

type HistoryItem = {
  id: string;
  module: ModuleKey;
  action: string;
  timestamp: string;
  success: boolean;
  expected?: "PASS" | "FAIL";
  evaluation?: "PASS" | "FAIL";
  message: string;
  response: ApiJson;
};

type ProcedurePreset = {
  id: string;
  label: string;
  procedureName: ProcedureName;
  expected: "PASS" | "FAIL";
  payload: Record<string, unknown>;
};

const procedureDefaults: Record<ProcedureName, Record<string, unknown>> = {
  SP_MANAGE_BOOK: {
    action: "ADD",
    bookId: null,
    isbn: null,
    title: `DEV_CONSOLE_${Date.now()}`,
    description: "Created by Oracle Dev Console",
    categoryId: 1,
    publisherId: 1,
    price: 120000,
    stockQuantity: 5,
    publicationYear: 2026,
    pageCount: 180,
    language: "vi",
    coverType: "PAPERBACK",
    updatedBy: null,
  },
  SP_REPORT_MONTHLY_SALES: {
    fromDate: new Date(new Date().getFullYear(), 0, 1).toISOString().slice(0, 10),
    toDate: new Date().toISOString().slice(0, 10),
    branchId: "",
  },
  SP_CALCULATE_COUPON_DISCOUNT: {
    couponCode: "WELCOME10",
    orderAmount: 500000,
  },
  SP_PRINT_LOW_STOCK_INVENTORY: {
    branchId: "",
  },
};

const PROCEDURE_PRESETS: ProcedurePreset[] = [
  {
    id: "manage-book-pass",
    label: "SP_MANAGE_BOOK - ADD hợp lệ",
    procedureName: "SP_MANAGE_BOOK",
    expected: "PASS",
    payload: {
      action: "ADD",
      bookId: null,
      isbn: null,
      title: `PRESET_OK_${Date.now()}`,
      description: "preset pass",
      categoryId: 1,
      publisherId: 1,
      price: 100000,
      stockQuantity: 3,
      publicationYear: 2026,
      pageCount: 120,
      language: "vi",
      coverType: "PAPERBACK",
      updatedBy: null,
    },
  },
  {
    id: "manage-book-fail",
    label: "SP_MANAGE_BOOK - action sai",
    procedureName: "SP_MANAGE_BOOK",
    expected: "FAIL",
    payload: {
      action: "INVALID_ACTION",
      bookId: null,
      isbn: null,
      title: "SHOULD_FAIL",
      description: null,
      categoryId: 1,
      publisherId: 1,
      price: 100000,
      stockQuantity: 1,
      publicationYear: 2026,
      pageCount: 120,
      language: "vi",
      coverType: "PAPERBACK",
      updatedBy: null,
    },
  },
  {
    id: "monthly-sales-pass",
    label: "SP_REPORT_MONTHLY_SALES - date hợp lệ",
    procedureName: "SP_REPORT_MONTHLY_SALES",
    expected: "PASS",
    payload: {
      fromDate: new Date(new Date().getFullYear(), 0, 1).toISOString().slice(0, 10),
      toDate: new Date().toISOString().slice(0, 10),
      branchId: "",
    },
  },
  {
    id: "monthly-sales-fail",
    label: "SP_REPORT_MONTHLY_SALES - fromDate > toDate",
    procedureName: "SP_REPORT_MONTHLY_SALES",
    expected: "FAIL",
    payload: {
      fromDate: "2026-12-31",
      toDate: "2026-01-01",
      branchId: "",
    },
  },
  {
    id: "low-stock-pass",
    label: "SP_PRINT_LOW_STOCK_INVENTORY - all branch",
    procedureName: "SP_PRINT_LOW_STOCK_INVENTORY",
    expected: "PASS",
    payload: {
      branchId: "",
    },
  },
  {
    id: "low-stock-fail",
    label: "SP_PRINT_LOW_STOCK_INVENTORY - branch sai kiểu",
    procedureName: "SP_PRINT_LOW_STOCK_INVENTORY",
    expected: "FAIL",
    payload: {
      branchId: "INVALID_ID",
    },
  },
  {
    id: "coupon-pass",
    label: "SP_CALCULATE_COUPON_DISCOUNT - amount hợp lệ",
    procedureName: "SP_CALCULATE_COUPON_DISCOUNT",
    expected: "PASS",
    payload: {
      couponCode: "WELCOME10",
      orderAmount: 500000,
    },
  },
  {
    id: "coupon-fail",
    label: "SP_CALCULATE_COUPON_DISCOUNT - amount âm",
    procedureName: "SP_CALCULATE_COUPON_DISCOUNT",
    expected: "FAIL",
    payload: {
      couponCode: "WELCOME10",
      orderAmount: -10,
    },
  },
];

function pretty(value: JsonValue): string {
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

function messageOf(data: ApiJson): string {
  return typeof data.message === "string" ? data.message : "";
}

function toCsv(rows: Record<string, unknown>[]): string {
  if (!rows.length) return "No data\n";

  const headers = Array.from(
    rows.reduce<Set<string>>((acc, row) => {
      Object.keys(row).forEach((k) => acc.add(k));
      return acc;
    }, new Set<string>())
  );

  const esc = (value: unknown) => {
    const text = typeof value === "string" ? value : JSON.stringify(value ?? "");
    const escaped = text.replace(/"/g, '""');
    return /[",\n]/.test(escaped) ? `"${escaped}"` : escaped;
  };

  const lines = [headers.join(",")];
  for (const row of rows) {
    lines.push(headers.map((h) => esc(row[h])).join(","));
  }

  return `${lines.join("\n")}\n`;
}

function downloadCsv(fileName: string, csvContent: string) {
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

export default function DashboardPage() {
  const router = useRouter();

  const [currentUser, setCurrentUser] = useState<string>("");
  const [loadingMe, setLoadingMe] = useState(true);

  const [viewName, setViewName] = useState("VW_ORDER_SALES_REPORT");
  const [viewLimit, setViewLimit] = useState(10);

  const [procedureName, setProcedureName] = useState<ProcedureName>("SP_REPORT_MONTHLY_SALES");
  const [procedurePayloadText, setProcedurePayloadText] = useState(pretty(procedureDefaults.SP_REPORT_MONTHLY_SALES));

  const [triggerScenario, setTriggerScenario] = useState<TriggerScenario>("orders_validation_formula_error");

  const [output, setOutput] = useState<string>("{}");
  const [busy, setBusy] = useState(false);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [securityMatrix, setSecurityMatrix] = useState<SecurityMatrix>({});
  const [lastViewRows, setLastViewRows] = useState<Record<string, unknown>[]>([]);
  const [presetStatus, setPresetStatus] = useState<Record<string, { evaluation: "PASS" | "FAIL"; message: string }>>({});
  const [rubric, setRubric] = useState<RubricItem[]>([]);
  const [rubricSummary, setRubricSummary] = useState<RubricSummary>({ totalWeight: 100, totalAwarded: 0, completionPercent: 0 });

  const rubricStatusClass: Record<RubricStatus, string> = {
    met: "badge-success",
    partial: "badge",
    unmet: "badge-danger",
    manual: "badge",
  };

  const rubricStatusLabel: Record<RubricStatus, string> = {
    met: "Đạt",
    partial: "Một phần",
    unmet: "Chưa đạt",
    manual: "Chấm tay",
  };

  const appendHistory = useCallback((item: Omit<HistoryItem, "id" | "timestamp">) => {
    setHistory((prev) => [
      {
        ...item,
        id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        timestamp: new Date().toISOString(),
      },
      ...prev,
    ]);
  }, []);

  useEffect(() => {
    async function loadMe() {
      setLoadingMe(true);
      try {
        const response = await fetch("/api/auth/me", { cache: "no-store", credentials: "include" });
        const data = await response.json();
        if (!response.ok || !data.success) {
          router.push("/login");
          return;
        }
        setCurrentUser(data.user.oracleUser);
      } catch {
        router.push("/login");
      } finally {
        setLoadingMe(false);
      }
    }

    void loadMe();
  }, [router]);

  const procedureOptions = useMemo(() => Object.keys(procedureDefaults) as ProcedureName[], []);

  const roles = useMemo(() => {
    const found = Object.keys(securityMatrix);
    const preferred = ["ADMIN_ROLE", "STAFF_ROLE", "GUEST_ROLE"];
    const merged = [...preferred, ...found.filter((r) => !preferred.includes(r))];
    return merged.filter((r, idx) => merged.indexOf(r) === idx);
  }, [securityMatrix]);

  const matrixObjects = useMemo(() => {
    const set = new Set<string>();
    for (const role of Object.keys(securityMatrix)) {
      for (const objectName of Object.keys(securityMatrix[role] ?? {})) {
        set.add(objectName);
      }
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b));
  }, [securityMatrix]);

  const runRequest = useCallback(async (url: string, init?: RequestInit) => {
    setBusy(true);
    try {
      const response = await fetch(url, {
        ...init,
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
          ...(init?.headers ?? {}),
        },
      });
      const data = (await response.json()) as ApiJson;
      setOutput(pretty(data));
      return data;
    } catch {
      const fallback = { success: false, message: "Không thể gọi API máy chủ." };
      setOutput(pretty(fallback));
      return fallback as ApiJson;
    } finally {
      setBusy(false);
    }
  }, []);

  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST", credentials: "include" });
    router.push("/login");
  };

  const onRunView = useCallback(() => {
    void (async () => {
      const data = await runRequest("/api/views/query", {
      method: "POST",
      body: JSON.stringify({ viewName, limit: viewLimit }),
    });
      const rows = Array.isArray(data.rows) ? (data.rows as Record<string, unknown>[]) : [];
      setLastViewRows(rows);
      appendHistory({
        module: "views",
        action: `Query ${viewName}`,
        success: data.success === true,
        message: messageOf(data),
        response: data,
      });
    })();
  }, [appendHistory, runRequest, viewName, viewLimit]);

  const onRunProcedure = useCallback(() => {
    let payload: Record<string, unknown>;
    try {
      payload = JSON.parse(procedurePayloadText) as Record<string, unknown>;
    } catch {
      const invalid = { success: false, message: "Dữ liệu JSON không hợp lệ." };
      setOutput(pretty(invalid));
      appendHistory({
        module: "procedures",
        action: `Execute ${procedureName}`,
        success: false,
        message: invalid.message,
        response: invalid,
      });
      return;
    }

    void (async () => {
      const data = await runRequest("/api/procedures/execute", {
      method: "POST",
      body: JSON.stringify({ procedureName, payload }),
    });
      appendHistory({
        module: "procedures",
        action: `Execute ${procedureName}`,
        success: data.success === true,
        message: messageOf(data),
        response: data,
      });
    })();
  }, [appendHistory, runRequest, procedureName, procedurePayloadText]);

  const onRunTriggerScenario = useCallback(() => {
    void (async () => {
      const data = await runRequest("/api/triggers/scenarios", {
      method: "POST",
      body: JSON.stringify({ scenario: triggerScenario }),
    });
      appendHistory({
        module: "triggers",
        action: `Scenario ${triggerScenario}`,
        success: data.success === true,
        message: messageOf(data),
        response: data,
      });
    })();
  }, [appendHistory, runRequest, triggerScenario]);

  const onLoadSecurityMatrix = useCallback(() => {
    void (async () => {
      const data = await runRequest("/api/security/matrix");
      const matrix = (data.matrix as SecurityMatrix) ?? {};
      setSecurityMatrix(matrix);
      appendHistory({
        module: "security",
        action: "Load security matrix",
        success: data.success === true,
        message: messageOf(data),
        response: data,
      });
    })();
  }, [runRequest, appendHistory]);

  const onLoadRubric = useCallback(() => {
    void (async () => {
      const data = await runRequest("/api/rubric/status");
      const loadedRubric = Array.isArray(data.rubric) ? (data.rubric as RubricItem[]) : [];
      const loadedSummary = (data.summary as RubricSummary | undefined) ?? {
        totalWeight: 100,
        totalAwarded: 0,
        completionPercent: 0,
      };

      setRubric(loadedRubric);
      setRubricSummary(loadedSummary);

      appendHistory({
        module: "security",
        action: "Load SQL rubric status",
        success: data.success === true,
        message: messageOf(data),
        response: data,
      });
    })();
  }, [runRequest, appendHistory]);

  useEffect(() => {
    if (!loadingMe) onLoadRubric();
  }, [loadingMe, onLoadRubric]);

  const runProcedurePreset = useCallback(async (preset: ProcedurePreset) => {
    const data = await runRequest("/api/procedures/execute", {
      method: "POST",
      body: JSON.stringify({ procedureName: preset.procedureName, payload: preset.payload }),
    });

    const actualPass = data.success === true;
    const evaluation =
      (preset.expected === "PASS" && actualPass) || (preset.expected === "FAIL" && !actualPass)
        ? "PASS"
        : "FAIL";

    setPresetStatus((prev) => ({
      ...prev,
      [preset.id]: {
        evaluation,
        message: messageOf(data) || (actualPass ? "Success" : "Failed as expected"),
      },
    }));

    appendHistory({
      module: "procedures",
      action: `Preset ${preset.id}`,
      success: actualPass,
      expected: preset.expected,
      evaluation,
      message: messageOf(data),
      response: data,
    });
  }, [runRequest, appendHistory]);

  const exportHistoryCsv = useCallback((module: ModuleKey | "all") => {
    const filtered = module === "all" ? history : history.filter((item) => item.module === module);
    const rows = filtered.map((item) => ({
      timestamp: item.timestamp,
      module: item.module,
      action: item.action,
      success: item.success,
      expected: item.expected ?? "",
      evaluation: item.evaluation ?? "",
      message: item.message,
      response: pretty(item.response),
    }));
    downloadCsv(`oracle-dev-console-${module}.csv`, toCsv(rows));
  }, [history]);

  const exportMatrixCsv = useCallback(() => {
    const rows: Record<string, unknown>[] = matrixObjects.map((objectName) => {
      const row: Record<string, unknown> = { object: objectName };
      for (const role of roles) {
        row[role] = (securityMatrix[role]?.[objectName] ?? []).join("|");
      }
      return row;
    });
    downloadCsv("oracle-security-matrix-grid.csv", toCsv(rows));
  }, [matrixObjects, roles, securityMatrix]);

  const exportViewRowsCsv = useCallback(() => {
    downloadCsv("oracle-views-last-result.csv", toCsv(lastViewRows));
  }, [lastViewRows]);

  const onSwitchProcedure = (value: ProcedureName) => {
    setProcedureName(value);
    setProcedurePayloadText(pretty(procedureDefaults[value] ?? {}));
  };

  if (loadingMe) {
    return (
      <main className="container flex items-center justify-center min-h-[50vh]">
        <div className="flex flex-col items-center gap-4">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent shadow-md" />
            <p className="text-sm font-bold text-muted-foreground uppercase tracking-widest">Đang tải phiên làm việc...</p>
        </div>
      </main>
    );
  }

  return (
    <main className="container stack">
      <div className="card row space-between glass shadow-xl border-primary/10">
        <div className="stack gap-6">
          <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary shadow-inner">
                  <Database size={20} />
              </div>
              <h1 className="no-margin text-xl font-black tracking-tight">Oracle Dev Console</h1>
          </div>
          <div className="row">
            <span className="badge">
                <ShieldCheck size={12} className="text-emerald-500" />
                Phiên làm việc: {currentUser}
            </span>
            <span className="badge">
                <Activity size={12} className="text-indigo-500" />
                Dữ liệu: sp, triggers, views, roles
            </span>
          </div>
        </div>
        <button className="danger h-10" onClick={handleLogout}>
            <LogOut size={16} />
            Đăng xuất
        </button>
      </div>

      <section className="card stack rubric-shell">
        <div className="row space-between">
          <div className="stack gap-6">
            <div className="row">
              <span className="badge">
                <ClipboardCheck size={12} />
                Tiêu chí chấm điểm SQL
              </span>
              <span className="badge">
                <BarChart3 size={12} />
                Tổng đạt: {rubricSummary.totalAwarded}/{rubricSummary.totalWeight}
              </span>
            </div>
            <h2 className="no-margin">Dashboard chấm điểm tự động theo tiêu chí đồ án</h2>
            <p className="muted no-margin">
              Dữ liệu lấy trực tiếp từ metadata Oracle và script transaction để đối chiếu mức đạt của từng hạng mục SQL.
            </p>
          </div>
          <div className="stack gap-6">
            <button onClick={onLoadRubric} disabled={busy}>Làm mới rubric</button>
            <div className="rubric-progress">
              <div className="rubric-progress-bar" style={{ width: `${Math.min(100, rubricSummary.completionPercent)}%` }} />
            </div>
            <p className="muted no-margin text-right">{rubricSummary.completionPercent}% hoàn thành</p>
          </div>
        </div>

        <div className="rubric-grid">
          {rubric.map((item) => (
            <article key={item.id} className="rubric-card">
              <div className="row space-between">
                <span className="badge">#{item.id}</span>
                <span className={cn("badge", rubricStatusClass[item.status])}>{rubricStatusLabel[item.status]}</span>
              </div>
              <h3 className="no-margin rubric-title">{item.title}</h3>
              <p className="muted no-margin">{item.requirement}</p>
              <p className="rubric-score no-margin">{item.scoreAwarded}/{item.weight} điểm</p>
              <p className="muted no-margin">{item.detail}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="card stack">
        <div className="row space-between">
          <h2 className="no-margin">Export CSV kết quả test</h2>
          <div className="row">
            <button className="secondary" onClick={() => exportHistoryCsv("views")}>Views</button>
            <button className="secondary" onClick={() => exportHistoryCsv("procedures")}>Procedures</button>
            <button className="secondary" onClick={() => exportHistoryCsv("triggers")}>Triggers</button>
            <button className="secondary" onClick={() => exportHistoryCsv("security")}>Security</button>
            <button onClick={() => exportHistoryCsv("all")}>All</button>
            <button className="secondary" onClick={exportMatrixCsv}>Matrix Grid</button>
          </div>
        </div>
      </section>

      <section className="card stack">
        <div className="row space-between">
          <h2 className="no-margin">Preset test procedures (expected PASS/FAIL)</h2>
        </div>
        <div className="preset-grid">
          {PROCEDURE_PRESETS.map((preset) => {
            const status = presetStatus[preset.id];
            return (
              <div key={preset.id} className="preset-card">
                <div className="row space-between">
                  <strong>{preset.label}</strong>
                  <span className="badge">Expect: {preset.expected}</span>
                </div>
                <div className="row">
                  <span className="badge">{preset.procedureName}</span>
                  {status ? (
                    <span className={cn("badge", status.evaluation === "PASS" ? "badge-success" : "badge-danger")}>
                      {status.evaluation === "PASS" ? <CheckCircle2 size={12} /> : <AlertCircle size={12} />}
                      {status.evaluation}
                    </span>
                  ) : (
                    <span className="badge">Not run</span>
                  )}
                </div>
                <p className="muted no-margin">{status?.message ?? "Bấm Run để kiểm tra."}</p>
                <button className="secondary" onClick={() => void runProcedurePreset(preset)} disabled={busy}>
                  <Play size={14} /> Run
                </button>
              </div>
            );
          })}
        </div>
      </section>

      <div className="grid2">
        <section className="card stack relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none">
              <Search size={64} />
          </div>
          <div className="flex items-center gap-2 mb-2">
              <TableProperties size={18} className="text-primary" />
              <h2 className="no-margin text-base font-bold">Views / Materialized View</h2>
          </div>
          <label>
            Đối tượng CSDL
            <select value={viewName} onChange={(e) => setViewName(e.target.value)}>
              <option>VW_ORDER_SALES_REPORT</option>
              <option>VW_CUSTOMER_SECURE_PROFILE</option>
              <option>MV_DAILY_BRANCH_SALES</option>
            </select>
          </label>
          <label>
            Số dòng giới hạn (1-100)
            <input type="number" value={viewLimit} onChange={(e) => setViewLimit(Number(e.target.value))} />
          </label>
          <div className="mt-2 flex flex-col gap-2">
              <button onClick={onRunView} disabled={busy} className="h-11">
                {busy ? <RotateCcw size={16} className="animate-spin" /> : <Play size={16} />}
                Truy vấn dữ liệu
              </button>
              <button className="secondary" onClick={exportViewRowsCsv}>Export view rows CSV</button>
              <p className="text-[10px] text-center text-muted-foreground flex items-center justify-center gap-1">
                Kết quả view lần cuối sẽ được xuất theo nút CSV riêng.
              </p>
          </div>
        </section>

        <section className="card stack relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none">
              <ShieldCheck size={64} />
          </div>
          <div className="flex items-center gap-2 mb-2">
              <Info size={18} className="text-primary" />
              <h2 className="no-margin text-base font-bold">Ma trận bảo mật Vai trò</h2>
          </div>
          <p className="no-margin muted text-xs leading-relaxed">
            Đọc ma trận đặc quyền trực tiếp từ các view hệ thống Oracle (dictionary views). Bạn nên đăng nhập bằng <strong>DIGIBOOK_ADMIN</strong> để xem đầy đủ đặc quyền của các role.
          </p>
          <div className="mt-auto">
              <button onClick={onLoadSecurityMatrix} disabled={busy} className="secondary w-full h-11">
                <ExternalLink size={16} />
                Tải ma trận quyền
              </button>
          </div>
        </section>
      </div>

      <section className="card stack">
        <div className="row space-between">
          <h2 className="no-margin">Matrix trực quan (Role × Object × Privilege)</h2>
          <span className="badge">Objects: {matrixObjects.length}</span>
        </div>

        {matrixObjects.length === 0 ? (
          <p className="muted no-margin">Chưa có dữ liệu matrix. Bấm “Tải ma trận quyền” trước.</p>
        ) : (
          <div className="matrix-wrapper">
            <table className="matrix-table">
              <thead>
                <tr>
                  <th>Object</th>
                  {roles.map((role) => (
                    <th key={role}>{role}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {matrixObjects.map((objectName) => (
                  <tr key={objectName}>
                    <td className="matrix-object-cell">{objectName}</td>
                    {roles.map((role) => {
                      const privileges = securityMatrix[role]?.[objectName] ?? [];
                      return (
                        <td key={`${objectName}-${role}`}>
                          <div className="matrix-privs">
                            {privileges.length > 0 ? (
                              privileges.map((priv) => (
                                <span key={`${objectName}-${role}-${priv}`} className="priv-chip">
                                  {priv}
                                </span>
                              ))
                            ) : (
                              <span className="muted">-</span>
                            )}
                          </div>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <div className="grid2">
        <section className="card stack relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none">
              <FileCode size={64} />
          </div>
          <div className="flex items-center gap-2 mb-2">
              <Terminal size={18} className="text-primary" />
              <h2 className="no-margin text-base font-bold">Thực thi Stored Procedure</h2>
          </div>
          <label>
            Tên Procedure
            <select value={procedureName} onChange={(e) => onSwitchProcedure(e.target.value as ProcedureName)}>
              {procedureOptions.map((item) => (
                <option key={item} value={item}>{item}</option>
              ))}
            </select>
          </label>
          <label>
            Dữ liệu đầu vào (JSON Payload)
            <textarea
              rows={8}
              className="font-mono text-sm leading-relaxed"
              value={procedurePayloadText}
              onChange={(e) => setProcedurePayloadText(e.target.value)}
              placeholder='{"param": "value"}'
            />
          </label>
          <div className="mt-2 flex flex-col gap-2">
              <button onClick={onRunProcedure} disabled={busy} className="h-11">
                {busy ? <RotateCcw size={16} className="animate-spin" /> : <Play size={16} />}
                Chạy Procedure
              </button>
              <p className="text-[10px] text-center text-muted-foreground flex items-center justify-center gap-1">
                Dùng preset test ở trên để chấm expected PASS/FAIL tự động.
              </p>
          </div>
        </section>

        <section className="card stack border-amber-200/50 bg-amber-50/20">
          <div className="flex items-center gap-2 mb-2">
              <AlertCircle size={18} className="text-amber-600" />
              <h2 className="no-margin text-base font-bold text-amber-900">Kiểm thử Trình kích hoạt (Triggers)</h2>
          </div>
          <div className="p-3 rounded-lg bg-amber-100/50 border border-amber-200 text-xs text-amber-800 leading-relaxed">
            Hệ thống sẽ chạy kịch bản bao gồm <strong>SAVEPOINT</strong> và thực hiện <strong>ROLLBACK</strong> tự động sau khi quan sát kết quả, đảm bảo dữ liệu thật trong DB không bị thay đổi vĩnh viễn.
          </div>
          <label className="text-amber-900">
            Kịch bản (Scenario)
            <select 
                value={triggerScenario} 
                  onChange={(e) => setTriggerScenario(e.target.value as TriggerScenario)}
                className="border-amber-200 focus:ring-amber-500"
            >
              <option value="orders_validation_formula_error">Mô phỏng lỗi ràng buộc đơn hàng (Trigger BIU)</option>
              <option value="orders_audit_probe">Kiểm tra ghi nhật ký kiểm toán (Trigger AIUD)</option>
              <option value="inventory_sync_probe">Kiểm tra đồng bộ tồn kho (Trigger AIUD)</option>
            </select>
          </label>
          <div className="mt-auto">
              <button onClick={onRunTriggerScenario} disabled={busy} className="danger w-full h-11 shadow-inner shadow-black/10">
                <Play size={16} />
                Bắt đầu kịch bản thử nghiệm
              </button>
          </div>
        </section>
      </div>

      <section className="card stack border-primary/20 shadow-lg">
        <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
                <Terminal size={18} className="text-primary" />
                <h2 className="no-margin text-base font-bold tracking-tight">Kết quả thực thi (Execution Output)</h2>
            </div>
            <div className="flex items-center gap-2">
                <div className={cn(
                    "h-2 w-2 rounded-full",
                    busy ? "bg-amber-500 animate-pulse" : "bg-emerald-500"
                )} />
                <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                    {busy ? "Đang xử lý..." : "Sẵn sàng"}
                </span>
            </div>
        </div>
        <pre className="output shadow-2xl relative">
            <div className="absolute top-2 right-4 text-[10px] uppercase font-bold text-white/20 select-none">
                Oracle Response JSON
            </div>
            {output}
        </pre>
      </section>

      <section className="card stack">
        <div className="row space-between">
          <h2 className="no-margin">Lịch sử test</h2>
          <span className="badge">Total: {history.length}</span>
        </div>
        {history.length === 0 ? (
          <p className="muted no-margin">Chưa có lịch sử.</p>
        ) : (
          <div className="history-list">
            {history.map((item) => (
              <div key={item.id} className="history-card">
                <div className="row space-between">
                  <div className="row">
                    <span className="badge">{item.module}</span>
                    <span className="badge">{item.action}</span>
                    <span className="badge">{new Date(item.timestamp).toLocaleString()}</span>
                  </div>
                  <div className="row">
                    <span className={cn("badge", item.success ? "badge-success" : "badge-danger")}>{item.success ? "PASS" : "FAIL"}</span>
                    {item.evaluation ? (
                      <span className={cn("badge", item.evaluation === "PASS" ? "badge-success" : "badge-danger")}>
                        expected {item.evaluation}
                      </span>
                    ) : null}
                  </div>
                </div>
                <p className="muted no-margin">{item.message || "No message"}</p>
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
