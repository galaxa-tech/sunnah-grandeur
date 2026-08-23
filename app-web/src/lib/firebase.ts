import { initializeApp, getApps, getApp } from "firebase/app";
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore";
import { getAuth, connectAuthEmulator } from "firebase/auth";
import { getFunctions, connectFunctionsEmulator } from "firebase/functions";

const firebaseConfig = {
  projectId: "sunnah-grandeur",
  appId: "1:6748865044:web:a50ab96d823a83bacd1d01",
  storageBucket: "sunnah-grandeur.firebasestorage.app",
  apiKey: "AIzaSyDX3H10keVelz9HppzN_Y0BKqhPWRCqV8U",
  authDomain: "sunnah-grandeur.firebaseapp.com",
  messagingSenderId: "6748865044",
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
export const db = getFirestore(app);
export const auth = getAuth(app);
export const functions = getFunctions(app);

// Connect to Local Firebase Emulators in local development
if (
  typeof window !== "undefined" &&
  (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1")
) {
  try {
    // Only connect if emulators are enabled locally
    if (process.env.NEXT_PUBLIC_USE_EMULATORS === "true") {
      connectFirestoreEmulator(db, "localhost", 8080);
      connectFunctionsEmulator(functions, "localhost", 5001);
      connectAuthEmulator(auth, "http://localhost:9099");
    }
  } catch (e) {
    // Emulators already connected
  }
}

export default app;
