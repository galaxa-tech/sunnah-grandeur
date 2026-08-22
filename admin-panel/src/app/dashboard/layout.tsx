"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth } from "@/lib/firebase";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
        // Redirection for demo/testing mode vs production:
        // Check if bypass key or mock admin mode is active in local storage for local testing
        const demoAdmin = typeof window !== 'undefined' ? localStorage.getItem("demoAdmin") : null;
        if (!demoAdmin) {
          router.push("/login");
          setLoading(false);
          return;
        }
      }
      setUser(currentUser);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [router]);

  if (loading) {
    return (
      <div className="min-h-screen bg-bg-primary flex flex-col items-center justify-center space-y-4">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary"></div>
        <p className="text-xs font-label-accent text-primary uppercase tracking-widest">
          Verifying Administrator Privileges...
        </p>
      </div>
    );
  }

  return <>{children}</>;
}
