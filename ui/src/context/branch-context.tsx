"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

interface Branch {
  id: string;
  name: string;
  address: string;
}

interface User {
  id: string;
  username: string;
  name: string;
  role: "ADMIN" | "MANAGER" | "STAFF" | "SUPPORT";
  branchId?: string;
  staffId?: string;
}

interface BranchContextType {
  branches: Branch[];
  currentBranch: Branch | null;
  setCurrentBranch: (branch: Branch) => void;
  currentUser: User | null;
  login: (user: User) => void;
  logout: () => void;
}

const BranchContext = createContext<BranchContextType | undefined>(undefined);

export const SYSTEM_BRANCH: Branch = {
  id: "ALL",
  name: "Toàn hệ thống",
  address: "Quản lý toàn bộ chi nhánh"
};

export function BranchProvider({ children }: { children: React.ReactNode }) {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [currentBranch, setCurrentBranch] = useState<Branch | null>(null);
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  // Fetch branches from API
  useEffect(() => {
    async function fetchBranches() {
      try {
        const response = await fetch("/api/branches");
        const json = await response.json();
        if (json.success && json.data) {
          const mappedBranches = json.data.map((b: any) => ({
            id: b.BRANCH_ID.toString(),
            name: b.BRANCH_NAME,
            address: b.ADDRESS || "",
          }));
          setBranches(mappedBranches);
          
          // Set default branch if none saved
          const savedBranchId = localStorage.getItem("digibook_branch");
          if (savedBranchId === "ALL") {
            setCurrentBranch(SYSTEM_BRANCH);
          } else if (savedBranchId) {
            const saved = mappedBranches.find((b: any) => b.id === savedBranchId);
            if (saved) setCurrentBranch(saved);
            else setCurrentBranch(mappedBranches[0]);
          } else {
            setCurrentBranch(mappedBranches[0]);
          }
        }
      } catch (error) {
        console.error("Failed to fetch branches:", error);
      }
    }
    fetchBranches();
  }, []);

  useEffect(() => {
    // Mock persistent login (vẫn giữ logic localStorage nhưng data từ DB qua Login API)
    const savedUser = localStorage.getItem("digibook_user");
    
    if (savedUser) {
      const user = JSON.parse(savedUser);
      setCurrentUser(user);
    }
  }, []);

  const login = (user: User) => {
    setCurrentUser(user);
    localStorage.setItem("digibook_user", JSON.stringify(user));
    
    if (user.branchId && branches.length > 0) {
      const branchIdStr = String(user.branchId);
      const branch = branches.find(b => b.id === branchIdStr);
      if (branch) {
        setCurrentBranch(branch);
        localStorage.setItem("digibook_branch", branch.id);
      }
    }
  };

  const logout = () => {
    setCurrentUser(null);
    setCurrentBranch(null);
    localStorage.removeItem("digibook_user");
    localStorage.removeItem("digibook_branch");
  };

  const handleSetBranch = (branch: Branch) => {
    // Chỉ cho phép đổi chi nhánh nếu là ADMIN hoặc SUPPORT
    if (currentUser?.role === "ADMIN" || currentUser?.role === "SUPPORT") {
      setCurrentBranch(branch);
      localStorage.setItem("digibook_branch", branch.id);
    }
  };

  return (
    <BranchContext.Provider value={{ 
      branches,
      currentBranch, 
      setCurrentBranch: handleSetBranch, 
      currentUser, 
      login, 
      logout 
    }}>
      {children}
    </BranchContext.Provider>
  );
}

export function useBranch() {
  const context = useContext(BranchContext);
  if (context === undefined) {
    throw new Error("useBranch must be used within a BranchProvider");
  }
  return context;
}
