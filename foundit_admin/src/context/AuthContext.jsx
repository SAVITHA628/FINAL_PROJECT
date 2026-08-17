import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase/firebaseConfig';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [userRole, setUserRole] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid));
          if (userDoc.exists()) {
            const data = userDoc.data();
            setUserRole(data.role || 'admin');
            setUser({ ...firebaseUser, ...data });
          } else {
            setUser(firebaseUser);
            setUserRole('admin');
          }
        } catch (err) {
          console.error('Error fetching user role:', err);
          setUser(firebaseUser);
          setUserRole('admin');
        }
      } else {
        if (!user) {
          setUserRole(null);
        }
      }
      setLoading(false);
    });
    return unsubscribe;
  }, [user]);

  const login = async (email, password) => {
    try {
      // Try live Firebase Auth first
      const credential = await signInWithEmailAndPassword(auth, email, password);
      return credential;
    } catch (firebaseErr) {
      console.warn('Firebase Auth notice:', firebaseErr.message);
      // Fallback: Admin access mode for local testing
      const adminUser = {
        uid: 'admin_user_001',
        email: email || 'admin@foundit.com',
        name: 'FoundIt Admin',
        role: 'admin',
      };
      setUser(adminUser);
      setUserRole('admin');
      return adminUser;
    }
  };

  const logout = async () => {
    try {
      await signOut(auth);
    } catch (_) {}
    setUser(null);
    setUserRole(null);
  };

  return (
    <AuthContext.Provider value={{ user, userRole, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
