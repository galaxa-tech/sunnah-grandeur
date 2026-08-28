import { initializeApp, getApps, getApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getFunctions } from "firebase/functions";

const firebaseConfig = {
  projectId: "sunnah-grandeur",
  appId: "1:6748865044:web:a665e0eb1d42529ccd1d01", // admin app ID
  storageBucket: "sunnah-grandeur.firebasestorage.app",
  apiKey: "AIzaSyDX3H10keVelz9HppzN_Y0BKqhPWRCqV8U",
  authDomain: "sunnah-grandeur.firebaseapp.com",
  messagingSenderId: "6748865044",
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
export const db = getFirestore(app);
export const auth = getAuth(app);
export const functions = getFunctions(app, "us-central1");
export default app;
