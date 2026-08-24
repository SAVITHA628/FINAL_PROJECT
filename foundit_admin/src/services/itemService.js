import {
  collection, getDocs, getDoc, doc, updateDoc, deleteDoc,
  query, where, Timestamp, onSnapshot, addDoc
} from 'firebase/firestore';
import { db } from '../firebase/firebaseConfig';

// ─── Fallback Mock Data (Only used if Firestore network fails) ─────────
const MOCK_ITEMS = [
  {
    id: 'item_001', type: 'lost', title: 'Blue Samsung Galaxy A54',
    description: 'Lost blue Samsung phone near library cafeteria with stickers.',
    category: 'Electronics', location: 'Library Cafeteria',
    status: 'active', verificationStatus: 'PENDING',
    imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&q=80',
    reportedBy: 'user_001', reporterName: 'Jash', reporterPhone: '+919876543210',
    createdAt: new Date(Date.now() - 86400000 * 2), isActive: true,
  },
  {
    id: 'item_002', type: 'found', title: 'College ID Card - Priya Sharma',
    description: 'Found ID card near parking lot. Roll: CSE-2024-042.',
    category: 'ID Card', location: 'Main Parking Lot',
    status: 'active', verificationStatus: 'VERIFIED', verifiedByAdmin: true,
    imageUrl: 'https://images.unsplash.com/photo-1578574577315-3fbeb0cecdc2?w=400&q=80',
    reportedBy: 'user_002', reporterName: 'Rohan Kumar', reporterPhone: '+919876543211',
    createdAt: new Date(Date.now() - 86400000), isActive: true,
  },
  {
    id: 'item_003', type: 'lost', title: 'Silver Car Keys with Red Keychain',
    description: 'Maruti Suzuki keys with red keychain last seen in canteen.',
    category: 'Keys', location: 'Central Canteen',
    status: 'active', verificationStatus: 'PENDING',
    imageUrl: 'https://images.unsplash.com/photo-1583473848882-f9a5bc7fd2ee?w=400&q=80',
    reportedBy: 'user_003', reporterName: 'Anita Desai', reporterPhone: '+919876543212',
    createdAt: new Date(Date.now() - 3600000 * 6), isActive: true,
  },
];

const ITEMS_COLLECTION = 'items';

export const itemService = {

  // Fetch all items from Firestore database
  async getAllItems() {
    try {
      const itemsRef = collection(db, ITEMS_COLLECTION);
      const snap = await Promise.race([
        getDocs(itemsRef),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 4000))
      ]);

      const items = snap.docs.map((d) => {
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
          updatedAt: data.updatedAt?.toDate?.() ?? null,
        };
      });

      // Sort by newest first
      items.sort((a, b) => b.createdAt - a.createdAt);

      return items;
    } catch (err) {
      console.warn('Firestore getAllItems notice (using fallback):', err.message);
      return MOCK_ITEMS;
    }
  },

  async getItemById(id) {
    try {
      const snap = await getDoc(doc(db, ITEMS_COLLECTION, id));
      if (snap.exists()) {
        const data = snap.data();
        return { id: snap.id, ...data, createdAt: data.createdAt?.toDate?.() ?? new Date() };
      }
      return MOCK_ITEMS.find(i => i.id === id) ?? null;
    } catch {
      return MOCK_ITEMS.find(i => i.id === id) ?? null;
    }
  },

  async getStats() {
    const items = await this.getAllItems();
    return {
      total:               items.length,
      lost:                items.filter(i => (i.type || i.itemType)?.toLowerCase() === 'lost').length,
      found:               items.filter(i => (i.type || i.itemType)?.toLowerCase() === 'found').length,
      active:              items.filter(i => (i.status || i.itemStatus)?.toLowerCase() === 'active').length,
      claimed:             items.filter(i => (i.status || i.itemStatus)?.toLowerCase() === 'claimed').length,
      returned:            items.filter(i => (i.status || i.itemStatus)?.toLowerCase() === 'returned').length,
      expired:             items.filter(i => (i.status || i.itemStatus)?.toLowerCase() === 'expired').length,
      disputed:            items.filter(i => (i.status || i.itemStatus)?.toLowerCase() === 'disputed').length,
      pendingVerification: items.filter(i => i.verificationStatus === 'PENDING').length,
      verifiedItems:       items.filter(i => i.verificationStatus === 'VERIFIED').length,
    };
  },

  async updateItemStatus(id, newStatus) {
    try {
      await updateDoc(doc(db, ITEMS_COLLECTION, id), {
        status:    newStatus.toLowerCase(),
        itemStatus: newStatus.toUpperCase(),
        updatedAt: Timestamp.now(),
      });
    } catch (err) {
      console.warn('updateItemStatus notice:', err.message);
    }
  },

  async verifyItem(id, status = 'VERIFIED') {
    try {
      await updateDoc(doc(db, ITEMS_COLLECTION, id), {
        verificationStatus: status,
        verifiedByAdmin:    status === 'VERIFIED',
        updatedAt:          Timestamp.now(),
      });
    } catch (err) {
      console.warn('verifyItem notice:', err.message);
    }
  },

  async deleteItem(id) {
    try {
      await deleteDoc(doc(db, ITEMS_COLLECTION, id));
    } catch (err) {
      console.warn('deleteItem notice:', err.message);
    }
  },

  subscribeToItems(callback) {
    try {
      const itemsRef = collection(db, ITEMS_COLLECTION);
      return onSnapshot(
        itemsRef,
        (snap) => {
          const items = snap.docs.map(d => ({
            id: d.id, ...d.data(),
            createdAt: d.data().createdAt?.toDate?.() ?? new Date(),
          }));
          items.sort((a, b) => b.createdAt - a.createdAt);
          callback(items);
        },
        () => callback(MOCK_ITEMS)
      );
    } catch {
      callback(MOCK_ITEMS);
      return () => {};
    }
  },
};
