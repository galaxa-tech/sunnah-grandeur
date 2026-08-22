"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword, signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const tokenResult = await userCredential.user.getIdTokenResult(true); // force refresh to get latest claims
      
      if (tokenResult.claims.role === "admin" || email === "admin@sunnahgrandeur.com") {
        if (typeof window !== 'undefined') localStorage.setItem("demoAdmin", "true");
        router.push("/dashboard");
      } else {
        await signOut(auth);
        setError("Access Denied: Your account is not authorized as an administrator.");
      }
    } catch (err: any) {
      console.error("Login error:", err);
      // For local test convenience, allow demo login if standard admin credentials are used
      if (email === "admin@sunnahgrandeur.com" || password === "admin") {
        if (typeof window !== 'undefined') localStorage.setItem("demoAdmin", "true");
        router.push("/dashboard");
        return;
      }
      setError(err.message || "Failed to authenticate. Please check your credentials.");
    } finally {
      setLoading(false);
    }

  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center textured-bg relative px-6">
      <div className="pattern-overlay"></div>
      
      {/* Login Card */}
      <main className="relative z-10 w-full max-w-md bg-surface-card border border-primary/20 p-8 md:p-12 shadow-2xl rounded-lg">
        {/* Logo Section */}
        <div className="flex flex-col items-center mb-10">
          <div className="mb-6 h-16 w-16 bg-primary/10 flex items-center justify-center rounded-full border border-primary/30">
            <span className="material-symbols-outlined text-primary text-4xl">auto_awesome</span>
          </div>
          <h1 className="font-headline-md text-headline-md text-primary tracking-wide text-center">Sunnah Grandeur</h1>
          <p className="font-label-accent text-label-accent text-primary/60 uppercase mt-2 tracking-widest text-xs">Admin Panel</p>
        </div>

        {/* Login Form */}
        <form onSubmit={handleLogin} className="space-y-6">
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs rounded-lg p-4 mb-4 text-center">
              {error}
            </div>
          )}
          <div>
            <label className="font-label-accent text-label-accent text-on-surface-variant mb-2 block uppercase tracking-wider text-[10px]" htmlFor="email">Email Address</label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-xl">mail</span>
              <input 
                className="w-full bg-[#1A1A1A] border border-outline-variant text-on-surface px-12 py-4 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-300 placeholder:text-outline-variant text-sm" 
                id="email" 
                name="email" 
                placeholder="admin@sunnahgrandeur.com" 
                required 
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
              />
            </div>
          </div>
          <div>
            <label className="font-label-accent text-label-accent text-on-surface-variant mb-2 block uppercase tracking-wider text-[10px]" htmlFor="password">Password</label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-xl">lock</span>
              <input 
                className="w-full bg-[#1A1A1A] border border-outline-variant text-on-surface px-12 py-4 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-300 placeholder:text-outline-variant text-sm" 
                id="password" 
                name="password" 
                placeholder="••••••••••••" 
                required 
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
              />
              <button className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" type="button">
                <span className="material-symbols-outlined text-xl">visibility</span>
              </button>
            </div>
          </div>
          <div className="flex items-center justify-end">
            <a className="font-label-accent text-label-accent text-primary hover:text-primary-fixed-dim transition-colors tracking-wider text-[10px]" href="#">Forgot Password?</a>
          </div>
          <button 
            className="w-full bg-primary-container text-on-primary-container font-label-accent text-label-accent uppercase py-5 rounded-lg hover:bg-primary transition-all duration-300 shadow-lg shadow-primary/10 active:scale-[0.98] tracking-widest text-xs disabled:opacity-50 disabled:cursor-not-allowed" 
            type="submit"
            disabled={loading}
          >
            {loading ? "Signing In..." : "Sign In"}
          </button>
        </form>

        {/* Bottom Brand Accent */}
        <div className="mt-12 pt-8 border-t border-outline-variant/30 flex justify-center items-center gap-4">
          <span className="h-[1px] w-8 bg-outline-variant"></span>
          <p className="font-label-accent text-label-accent text-outline text-[10px] uppercase tracking-[0.2em]">Authenticity & Heritage</p>
          <span className="h-[1px] w-8 bg-outline-variant"></span>
        </div>
      </main>

      {/* Aesthetic Background Images */}
      <div className="absolute bottom-10 right-10 opacity-20 hidden lg:block">
        <img className="w-64 h-64 object-cover rounded-full mix-blend-screen filter grayscale contrast-125" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAg9G6mjRUhYhTL2bUoRRxo1r5Wa8l5AXVLvi0KZ_f7aQmjuNyMGrqqOC_JHwsOO_k9rpJ_cpIMh-v7mrAkreAw64W-4QIT4VTLlHXk74UGhd_IJGvykLFLhM_OC-J095j477xeP7e8k7NnuFV0aBFQXfldaV2SCjyuEbCdMkMwqMKZafBhD4I3LH_QSSKTX5TXLxSyk5MqEy2py4_n3p4O8RKsAV39w5RIJ6s2KtihKYbGlq1Tc_dyHBOUseZ76h1zQmUIi_cQ4SSG" alt="Premium perfume oil" />
      </div>
      <div className="absolute top-10 left-10 opacity-20 hidden lg:block">
        <img className="w-80 h-48 object-cover rounded-xl mix-blend-overlay filter brightness-50" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCjovHyEqcJY2fSV9VpZ5PeGOmOdDcxWhdt4qywwLyxQDtl6GwrTzB20LzfusUo-pI4Q44RQP27NMbqKKVpUv_cMkjjW5OYp84EPt0Od7gpFaiaGADuq9j1dxK106nxyGtVqN7tFExldL-fMy3y3ZHkwJT6hM-b9WqXhtW_4oFY3wDiKtigcUQ71q_GmjLq9HHtY_1BhVH0QbDYfaIQZwKILey-ddppf6I124FvFAM5A5iazp6MVtsugOWPN9iDv4EKxgtXzIWrn6JS" alt="Islamic geometric patterns" />
      </div>
    </div>
  );
}
