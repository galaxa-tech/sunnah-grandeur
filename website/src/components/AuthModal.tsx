"use client";
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

type Mode = "signIn" | "signUp" | "reset";

interface Props {
  onClose: () => void;
}

export default function AuthModal({ onClose }: Props) {
  const { signIn, signUp, signInWithGoogle, resetPassword } = useAuth();
  const [mode, setMode] = useState<Mode>("signIn");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [loading, setLoading] = useState(false);

  const clearMessages = () => { setError(""); setInfo(""); };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearMessages();
    setLoading(true);
    try {
      if (mode === "signIn") {
        await signIn(email, password);
        onClose();
      } else if (mode === "signUp") {
        const user = await signUp(email, password);
        // Create Firestore profile via direct write (Cloud Function also handles this
        // but may have cold-start delay on first registration)
        await setDoc(doc(db, "users", user.uid), {
          uid: user.uid,
          name: name.trim(),
          email: user.email,
          role: "user",
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }, { merge: true });
        onClose();
      } else {
        await resetPassword(email);
        setInfo("Password reset email sent. Please check your inbox.");
      }
    } catch (err: unknown) {
      const msg = (err as { code?: string; message?: string })?.code || "An error occurred.";
      if (msg.includes("user-not-found") || msg.includes("wrong-password") || msg.includes("invalid-credential")) {
        setError("Invalid email or password.");
      } else if (msg.includes("email-already-in-use")) {
        setError("An account with this email already exists.");
      } else if (msg.includes("weak-password")) {
        setError("Password must be at least 6 characters.");
      } else {
        setError("Something went wrong. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    clearMessages();
    setLoading(true);
    try {
      await signInWithGoogle();
      onClose();
    } catch {
      setError("Google sign-in failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4" onClick={onClose}>
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />
      <div
        className="relative w-full max-w-md bg-surface-card border border-border-subtle rounded-2xl shadow-2xl p-8 animate-in fade-in zoom-in-95"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-text-secondary hover:text-text-primary transition-colors"
          aria-label="Close"
        >
          <span className="material-symbols-outlined">close</span>
        </button>

        {/* Logo / Title */}
        <div className="text-center mb-6">
          <p className="text-xs text-text-secondary uppercase tracking-[0.2em] mb-1">Sunnah Grandeur</p>
          <h2 className="text-xl font-bold text-text-primary font-serif">
            {mode === "signIn" ? "Welcome Back" : mode === "signUp" ? "Create Account" : "Reset Password"}
          </h2>
        </div>

        {/* Error / Info */}
        {error && (
          <div className="mb-4 p-3 bg-red-500/10 border border-red-500/30 rounded text-red-400 text-xs text-center">
            {error}
          </div>
        )}
        {info && (
          <div className="mb-4 p-3 bg-emerald-500/10 border border-emerald-500/30 rounded text-emerald-400 text-xs text-center">
            {info}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === "signUp" && (
            <div>
              <label className="block text-xs text-text-secondary uppercase tracking-wider mb-1">Full Name</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
                className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none transition-colors"
              />
            </div>
          )}

          <div>
            <label className="block text-xs text-text-secondary uppercase tracking-wider mb-1">Email</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none transition-colors"
            />
          </div>

          {mode !== "reset" && (
            <div>
              <label className="block text-xs text-text-secondary uppercase tracking-wider mb-1">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-[#141414] border border-border-subtle rounded px-3 py-2.5 text-sm text-text-primary focus:border-primary-container focus:outline-none transition-colors"
              />
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary-container text-bg-primary font-bold text-xs uppercase tracking-widest py-3.5 rounded hover:bg-[#e6c364] transition-colors shadow-lg disabled:opacity-50"
          >
            {loading ? "Please wait..." : mode === "signIn" ? "Sign In" : mode === "signUp" ? "Create Account" : "Send Reset Email"}
          </button>
        </form>

        {mode !== "reset" && (
          <>
            <div className="flex items-center gap-3 my-4">
              <div className="flex-1 h-px bg-border-subtle" />
              <span className="text-xs text-text-secondary">or</span>
              <div className="flex-1 h-px bg-border-subtle" />
            </div>

            <button
              onClick={handleGoogle}
              disabled={loading}
              className="w-full flex items-center justify-center gap-3 border border-border-subtle rounded py-3 text-sm text-text-primary hover:border-primary-container hover:bg-primary-container/5 transition-colors disabled:opacity-50"
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Continue with Google
            </button>
          </>
        )}

        {/* Mode switcher */}
        <div className="mt-5 text-center text-xs text-text-secondary space-y-2">
          {mode === "signIn" && (
            <>
              <p>
                Don&apos;t have an account?{" "}
                <button onClick={() => { clearMessages(); setMode("signUp"); }} className="text-primary-container hover:underline font-semibold">
                  Sign Up
                </button>
              </p>
              <p>
                <button onClick={() => { clearMessages(); setMode("reset"); }} className="text-text-secondary hover:text-primary-container hover:underline">
                  Forgot password?
                </button>
              </p>
            </>
          )}
          {mode === "signUp" && (
            <p>
              Already have an account?{" "}
              <button onClick={() => { clearMessages(); setMode("signIn"); }} className="text-primary-container hover:underline font-semibold">
                Sign In
              </button>
            </p>
          )}
          {mode === "reset" && (
            <p>
              <button onClick={() => { clearMessages(); setMode("signIn"); }} className="text-text-secondary hover:text-primary-container hover:underline">
                ← Back to Sign In
              </button>
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
