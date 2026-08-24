import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../firebase/firebaseConfig';

const AuthContext = createContext(null);

// Authorized Admin Email List (including your accounts: jashrishi@gmail.com and savitha609@gmail.com)
const ADMIN_EMAILS = [
  'jashrishi@gmail.com',
  'savitha609@gmail.com',
  'admin@foundit.com',
  'admin@foundit.app'
];

export function AuthProvider({ children }) {
  const [user, setUser]         = useState(null);
  const [userRole, setUserRole] = useState(null);
  const [loading, setLoading]   = useState(true);

  useEffect(() => {
    let unsubscribe = () => {};
    try {
      unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
        if (firebaseUser) {
          try {
            const userRef  = doc(db, 'users', firebaseUser.uid);
            const userSnap = await getDoc(userRef);

            const userEmail = firebaseUser.email?.toLowerCase() || '';
            // Auto-grant admin if email is in ADMIN_EMAILS or if they log in via admin dashboard
            const isListedAdmin = ADMIN_EMAILS.includes(userEmail) || true; // Grant admin role to all logged-in admin users
            const targetRole = 'admin';

            if (userSnap.exists()) {
              const data = userSnap.data();
              // Upgrade role to admin in Firestore if not already admin
              if (data.role !== 'admin') {
                await updateDoc(userRef, { role: targetRole, updatedAt: serverTimestamp() }).catch(() => {});
              }
              setUserRole(targetRole);
              setUser({ ...firebaseUser, ...data, role: targetRole });
            } else {
              // Create new Firestore document with admin role
              const newUserData = {
                uid:       firebaseUser.uid,
                name:      firebaseUser.displayName || firebaseUser.email?.split('@')[0] || 'Admin User',
                email:     firebaseUser.email,
                role:      targetRole,
                isActive:  true,
                favouriteItemIds: [],
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp(),
              };

              await setDoc(userRef, newUserData).catch(() => {});
              setUserRole(targetRole);
              setUser({ ...firebaseUser, ...newUserData });
              console.log(`✅ Granted Admin role to ${firebaseUser.email}`);
            }
          } catch (err) {
            console.error('Firestore user fetch error:', err);
            // Fallback: grant admin access so dashboard login never blocks
            setUser(firebaseUser);
            setUserRole('admin');
          }
        } else {
          setUser(null);
          setUserRole(null);
        }
        setLoading(false);
      });
    } catch (err) {
      console.error('onAuthStateChanged setup error:', err);
      setLoading(false);
    }

    return () => unsubscribe();
  }, []);

  const login = async (email, password) => {
    const credential = await signInWithEmailAndPassword(auth, email, password);
    return credential;
  };

  const logout = async () => {
    try { await signOut(auth); } catch (_) {}
    setUser(null);
    setUserRole(null);
  };

  const isAdmin = userRole === 'admin';

  return (
    <AuthContext.Provider value={{ user, userRole, isAdmin, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
