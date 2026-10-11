"use client";

import { useEffect, useState, useCallback } from 'react';
import { collection, doc, onSnapshot, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { signInAnonymously } from 'firebase/auth';
import { db, auth } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';

// Shares the Firestore path the mobile app already uses (favorites/{uid}/items/{productId}),
// so saved items sync between the website and the Daily Muslim app.
export function useWishlist() {
  const { user } = useAuth();
  const [ids, setIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!user) { setIds(new Set()); return; }
    return onSnapshot(
      collection(db, 'favorites', user.uid, 'items'),
      (snap) => setIds(new Set(snap.docs.map((d) => d.id))),
      () => setIds(new Set()),
    );
  }, [user]);

  const toggle = useCallback(async (productId: string) => {
    // Visitors without an account get a guest session so saving just works.
    if (!auth.currentUser) await signInAnonymously(auth);
    const uid = auth.currentUser!.uid;
    const ref = doc(db, 'favorites', uid, 'items', productId);
    if (ids.has(productId)) await deleteDoc(ref);
    else await setDoc(ref, { productId, addedAt: serverTimestamp() });
  }, [ids]);

  return { ids, has: (id: string) => ids.has(id), toggle };
}
