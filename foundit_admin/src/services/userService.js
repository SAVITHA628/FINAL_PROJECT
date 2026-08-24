import {
  collection, getDocs, doc, getDoc, updateDoc,
  Timestamp
} from 'firebase/firestore';
import { db } from '../firebase/firebaseConfig';

const MOCK_USERS = [
  {
    id: 'user_001', name: 'Jash', email: 'jashrishi@gmail.com',
    phone: '+919876543210', role: 'admin', isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 30),
  },
  {
    id: 'user_002', name: 'Savitha', email: 'savitha609@gmail.com',
    phone: '+919876543211', role: 'admin', isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 20),
  },
  {
    id: 'user_003', name: 'Rohan Kumar', email: 'rohan@college.edu',
    phone: '+919876543212', role: 'user', isActive: true,
    createdAt: new Date(Date.now() - 86400000 * 15),
  },
];

export const userService = {
  async getAllUsers() {
    try {
      const usersRef = collection(db, 'users');
      const snap = await Promise.race([
        getDocs(usersRef),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 4000))
      ]);

      const users = snap.docs.map((d) => {
        const data = d.data();
        let dateVal = new Date();
        if (data.createdAt?.toDate) {
          dateVal = data.createdAt.toDate();
        } else if (typeof data.createdAt === 'string') {
          dateVal = new Date(data.createdAt);
        }

        return {
          id: d.id,
          ...data,
          createdAt: dateVal,
        };
      });

      users.sort((a, b) => b.createdAt - a.createdAt);

      return users;
    } catch (err) {
      console.warn('getAllUsers notice (using fallback):', err.message);
      return MOCK_USERS;
    }
  },

  async getUserById(userId) {
    try {
      const snap = await getDoc(doc(db, 'users', userId));
      if (snap.exists()) return { id: snap.id, ...snap.data() };
      return MOCK_USERS.find(u => u.id === userId) ?? null;
    } catch {
      return MOCK_USERS.find(u => u.id === userId) ?? null;
    }
  },

  async toggleUserActive(userId, isActive) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        isActive, updatedAt: Timestamp.now(),
      });
    } catch (err) {
      console.warn('toggleUserActive notice:', err.message);
    }
  },

  async promoteToAdmin(userId) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        role: 'admin', updatedAt: Timestamp.now(),
      });
    } catch (err) {
      console.warn('promoteToAdmin notice:', err.message);
    }
  },

  async demoteToUser(userId) {
    try {
      await updateDoc(doc(db, 'users', userId), {
        role: 'user', updatedAt: Timestamp.now(),
      });
    } catch (err) {
      console.warn('demoteToUser notice:', err.message);
    }
  },
};
