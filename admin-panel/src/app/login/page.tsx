"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword, sendPasswordResetEmail, signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isResetMode, setIsResetMode] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const tokenResult = await userCredential.user.getIdTokenResult(true);
      
      const userEmail = userCredential.user.email?.toLowerCase();
      const isAdminEmail = userEmail === "sunnahgrandeur.nyc@gmail.com" || 
                           userEmail === "admin@sunnahgrandeur.com" || 
                           userEmail === "talharrc@gmail.com" || 
                           userEmail === "rihadhamid20@gmail.com";

      const role = tokenResult.claims.role;
      if (role === "admin" || role === "superAdmin" || isAdminEmail) {
        router.push("/dashboard");
      } else {
        await signOut(auth);
        setError("Access Denied: Your account is not authorized as an administrator.");
      }
    } catch (err: any) {
      console.error("Login error:", err);
      if (err.code === "auth/invalid-credential" || err.code === "auth/user-not-found" || err.code === "auth/wrong-password") {
        setError("Invalid email address or password. Please check your credentials.");
      } else {
        setError(err.message || "Failed to authenticate. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!email) {
      setError("Please enter your admin email address.");
      return;
    }

    setLoading(true);
    try {
      await sendPasswordResetEmail(auth, email);
      setSuccess("Password reset instructions have been sent to your email.");
    } catch (err: any) {
      console.error("Reset password error:", err);
      setError(err.message || "Failed to send password reset email. Please verify your email.");
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
        <div className="flex flex-col items-center mb-8">
          <div className="mb-4 h-16 w-16 bg-primary/10 flex items-center justify-center rounded-full border border-primary/30">
            <span className="material-symbols-outlined text-primary text-4xl">auto_awesome</span>
          </div>
          <h1 className="font-headline-md text-headline-md text-primary tracking-wide text-center">Sunnah Grandeur</h1>
          <p className="font-label-accent text-label-accent text-primary/60 uppercase mt-1 tracking-widest text-xs">
            {isResetMode ? "Password Recovery" : "Admin Command Center"}
          </p>
        </div>

        {/* Feedback Alerts */}
        {error && (
          <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs rounded-lg p-4 mb-6 text-center">
            {error}
          </div>
        )}
        {success && (
          <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs rounded-lg p-4 mb-6 text-center">
            {success}
          </div>
        )}

        {/* Form Container */}
        {isResetMode ? (
          <form onSubmit={handleResetPassword} className="space-y-6">
            <div>
              <label className="font-label-accent text-label-accent text-on-surface-variant mb-2 block uppercase tracking-wider text-[10px]" htmlFor="resetEmail">
                Admin Email Address
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-xl">mail</span>
                <input 
                  className="w-full bg-[#1A1A1A] border border-outline-variant text-on-surface px-12 py-4 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-300 placeholder:text-outline-variant text-sm" 
                  id="resetEmail" 
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

            <button 
              className="w-full bg-primary-container text-on-primary-container font-label-accent text-label-accent uppercase py-4 rounded-lg hover:bg-primary transition-all duration-300 shadow-lg shadow-primary/10 tracking-widest text-xs disabled:opacity-50" 
              type="submit"
              disabled={loading}
            >
              {loading ? "Sending Link..." : "Send Recovery Email"}
            </button>

            <div className="text-center pt-2">
              <button
                type="button"
                onClick={() => { setIsResetMode(false); setError(null); setSuccess(null); }}
                className="font-label-accent text-label-accent text-primary hover:underline tracking-wider text-xs"
              >
                ← Back to Admin Sign In
              </button>
            </div>
          </form>
        ) : (
          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label className="font-label-accent text-label-accent text-on-surface-variant mb-2 block uppercase tracking-wider text-[10px]" htmlFor="email">
                Email Address
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-xl">mail</span>
                <input 
                  className="w-full bg-[#1A1A1A] border border-outline-variant text-on-surface px-12 py-4 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-300 placeholder:text-outline-variant text-sm" 
                  id="email" 
                  name="email" 
                  placeholder="sunnahgrandeur.nyc@gmail.com" 
                  required 
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                />
              </div>
            </div>
            <div>
              <label className="font-label-accent text-label-accent text-on-surface-variant mb-2 block uppercase tracking-wider text-[10px]" htmlFor="password">
                Password
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant text-xl">lock</span>
                <input 
                  className="w-full bg-[#1A1A1A] border border-outline-variant text-on-surface px-12 py-4 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-300 placeholder:text-outline-variant text-sm" 
                  id="password" 
                  name="password" 
                  placeholder="••••••••••••" 
                  required 
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                />
                <button 
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary" 
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  <span className="material-symbols-outlined text-xl">
                    {showPassword ? "visibility_off" : "visibility"}
                  </span>
                </button>
              </div>
            </div>

            <div className="flex items-center justify-end">
              <button 
                type="button"
                onClick={() => { setIsResetMode(true); setError(null); setSuccess(null); }}
                className="font-label-accent text-label-accent text-primary hover:text-primary-fixed-dim transition-colors tracking-wider text-[10px]"
              >
                Forgot Password?
              </button>
            </div>

            <button 
              className="w-full bg-primary-container text-on-primary-container font-label-accent text-label-accent uppercase py-4 rounded-lg hover:bg-primary transition-all duration-300 shadow-lg shadow-primary/10 active:scale-[0.98] tracking-widest text-xs disabled:opacity-50 disabled:cursor-not-allowed" 
              type="submit"
              disabled={loading}
            >
              {loading ? "Authenticating..." : "Sign In to Admin Panel"}
            </button>
          </form>
        )}

        {/* Bottom Brand Accent */}
        <div className="mt-10 pt-6 border-t border-outline-variant/30 flex justify-center items-center gap-4">
          <span className="h-[1px] w-8 bg-outline-variant"></span>
          <p className="font-label-accent text-label-accent text-outline text-[10px] uppercase tracking-[0.2em]">Authenticity &amp; Heritage</p>
          <span className="h-[1px] w-8 bg-outline-variant"></span>
        </div>
      </main>
    </div>
  );
}
