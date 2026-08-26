import {
  collection, getDocs, getDoc, doc, updateDoc, deleteDoc,
  query, where, Timestamp, onSnapshot, addDoc
} from 'firebase/firestore';
import { db } from '../firebase/firebaseConfig';

// Pure Real-Time Firebase items only (zero demo/mock data)
const MOCK_ITEMS = [];

const ITEMS_COLLECTION = 'items';

export const itemService = {

  // Fetch all real items from Firestore database
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
      console.warn('Firestore getAllItems notice:', err.message);
      return [];
    }
  },

  async getItemById(id) {
    try {
      const snap = await getDoc(doc(db, ITEMS_COLLECTION, id));
      if (snap.exists()) {
        const data = snap.data();
        return { id: snap.id, ...data, createdAt: data.createdAt?.toDate?.() ?? new Date() };
      }
      return null;
    } catch {
      return null;
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
        () => callback([])
      );
    } catch {
      callback([]);
      return () => {};
    }
  },
};
