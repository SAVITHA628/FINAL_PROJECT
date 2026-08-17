import { collection, getDocs, doc, updateDoc, orderBy, query, Timestamp } from 'firebase/firestore';
import { db } from '../firebase/firebaseConfig';

const MOCK_USERS = [
  {
    id: 'user_001',
    name: 'Jash',
    email: 'jash@college.edu',
    phone: '+919876543210',
    role: 'admin',
    isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 30),
  },
  {
    id: 'user_002',
    name: 'Rohan Kumar',
    email: 'rohan@college.edu',
    phone: '+919876543211',
    role: 'user',
    isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 20),
  },
  {
    id: 'user_003',
    name: 'Anita Desai',
    email: 'anita@college.edu',
    phone: '+919876543212',
    role: 'user',
    isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 15),
  },
];

export const userService = {
  async getAllUsers() {
    try {
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), 1500)
      );
      const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'));
      const snap = await Promise.race([getDocs(q), timeoutPromise]);
      if (snap.empty) return MOCK_USERS;
      return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch (_) {
      return MOCK_USERS;
    }
  },

  async toggleUserActive(userId, isActive) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        isActive,
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },

  async promoteToAdmin(userId) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        role: 'admin',
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },

  async demoteToUser(userId) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        role: 'user',
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },
};
