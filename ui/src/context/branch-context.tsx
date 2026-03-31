"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

interface Branch {
  id: string;
  name: string;
  address: string;
}

interface User {
  id: string;
  name: string;
  role: "ADMIN" | "STAFF";
  branchId?: string;
}

interface BranchContextType {
  currentBranch: Branch | null;
  setCurrentBranch: (branch: Branch) => void;
  currentUser: User | null;
  login: (user: User) => void;
  logout: () => void;
}

const BranchContext = createContext<BranchContextType | undefined>(undefined);

export const branches: Branch[] = [
  { id: "BR01", name: "DigiBook Quận 1", address: "123 Lê Lợi, Q.1" },
  { id: "BR02", name: "DigiBook Quận 3", address: "45 Tú Xương, Q.3" },
  { id: "WAREHOUSE", name: "Kho trung tâm", address: "Khu Công Nghệ Cao, Q.9" },
];

export function BranchProvider({ children }: { children: React.ReactNode }) {
  const [currentBranch, setCurrentBranch] = useState<Branch | null>(null);
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  useEffect(() => {
    // Mock persistent login
    const savedUser = localStorage.getItem("digibook_user");
    const savedBranch = localStorage.getItem("digibook_branch");
    
    if (savedUser) {
      const user = JSON.parse(savedUser);
      setCurrentUser(user);
      
      const branchId = savedBranch || user.branchId;
      const branch = branches.find(b => b.id === branchId) || branches[0];
      setCurrentBranch(branch);
    }
  }, []);

  const login = (user: User) => {
    setCurrentUser(user);
    localStorage.setItem("digibook_user", JSON.stringify(user));
    
    const branch = branches.find(b => b.id === user.branchId) || branches[0];
    setCurrentBranch(branch);
    localStorage.setItem("digibook_branch", branch.id);
  };

  const logout = () => {
    setCurrentUser(null);
    setCurrentBranch(null);
    localStorage.removeItem("digibook_user");
    localStorage.removeItem("digibook_branch");
  };

  const handleSetBranch = (branch: Branch) => {
    setCurrentBranch(branch);
    localStorage.setItem("digibook_branch", branch.id);
  };

  return (
    <BranchContext.Provider value={{ 
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
