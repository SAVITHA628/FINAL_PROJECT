import {
  collection, getDocs, getDoc, doc, updateDoc, deleteDoc,
  query, where, orderBy, Timestamp, onSnapshot
} from 'firebase/firestore';
import { db } from '../firebase/firebaseConfig';

const MOCK_ITEMS = [
  {
    id: 'item_001',
    type: 'lost',
    itemType: 'LOST',
    title: 'Blue Samsung Galaxy A54',
    description: 'Lost my blue Samsung phone near the library cafeteria with stickers.',
    category: 'Electronics',
    location: 'Library Cafeteria',
    status: 'active',
    itemStatus: 'ACTIVE',
    verificationStatus: 'PENDING',
    reportedBy: 'user_001',
    reporterName: 'Jash',
    reporterPhone: '+919876543210',
    createdAt: new Date(Date.now() - 86400000 * 2),
  },
  {
    id: 'item_002',
    type: 'found',
    itemType: 'FOUND',
    title: 'College ID Card - Priya Sharma',
    description: 'Found an ID card near the parking lot. Roll: CSE-2024-042.',
    category: 'ID Card',
    location: 'Main Parking Lot',
    status: 'active',
    itemStatus: 'ACTIVE',
    verificationStatus: 'VERIFIED',
    verifiedByAdmin: true,
    reportedBy: 'user_002',
    reporterName: 'Rohan Kumar',
    reporterPhone: '+919876543211',
    createdAt: new Date(Date.now() - 86400000),
  },
  {
    id: 'item_003',
    type: 'lost',
    itemType: 'LOST',
    title: 'Silver Car Keys with Red Keychain',
    description: 'Maruti Suzuki keys with red keychain in canteen.',
    category: 'Keys',
    location: 'Central Canteen',
    status: 'active',
    itemStatus: 'ACTIVE',
    verificationStatus: 'PENDING',
    reportedBy: 'user_003',
    reporterName: 'Anita Desai',
    reporterPhone: '+919876543212',
    createdAt: new Date(Date.now() - 3600000 * 6),
  },
  {
    id: 'item_004',
    type: 'found',
    itemType: 'FOUND',
    title: 'Black Leather Wallet',
    description: 'Found black leather wallet on football ground.',
    category: 'Wallet',
    location: 'Football Ground',
    status: 'claimed',
    itemStatus: 'CLAIMED',
    verificationStatus: 'VERIFIED',
    verifiedByAdmin: true,
    reportedBy: 'user_004',
    reporterName: 'Vikram Singh',
    reporterPhone: '+919876543213',
    claimedBy: 'user_005',
    claimedAt: new Date(Date.now() - 86400000),
    createdAt: new Date(Date.now() - 86400000 * 3),
  },
  {
    id: 'item_005',
    type: 'lost',
    itemType: 'LOST',
    title: 'HP Laptop Charger - 65W',
    description: 'Lost HP charger in Lab 204 with red tape.',
    category: 'Electronics',
    location: 'Lab 204',
    status: 'returned',
    itemStatus: 'RETURNED',
    verificationStatus: 'VERIFIED',
    verifiedByAdmin: true,
    reportedBy: 'user_005',
    reporterName: 'Meena Patel',
    reporterPhone: '+919876543214',
    returnedAt: new Date(Date.now() - 86400000 * 2),
    createdAt: new Date(Date.now() - 86400000 * 5),
  },
];

function calculateStats(items) {
  const getItemType = (i) => (i.itemType || i.type || 'lost').toString().toLowerCase();
  const getItemStatus = (i) => (i.itemStatus || i.status || 'active').toString().toLowerCase();
  const getVerifStatus = (i) => (i.verificationStatus || 'pending').toString().toLowerCase();

  return {
    total: items.length,
    lost: items.filter((i) => getItemType(i) === 'lost').length,
    found: items.filter((i) => getItemType(i) === 'found').length,
    active: items.filter((i) => getItemStatus(i) === 'active').length,
    pending: items.filter((i) => getVerifStatus(i) === 'pending').length,
    claimed: items.filter((i) => getItemStatus(i) === 'claimed').length,
    returned: items.filter((i) => getItemStatus(i) === 'returned').length,
    expired: items.filter((i) => getItemStatus(i) === 'expired' || getItemStatus(i) === 'closed').length,
  };
}

export const itemService = {
  subscribeToItems(callback) {
    try {
      const q = query(collection(db, 'items'), orderBy('createdAt', 'desc'));
      return onSnapshot(q, (snap) => {
        if (snap.empty) {
          callback(MOCK_ITEMS);
        } else {
          const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
          callback(items);
        }
      }, () => callback(MOCK_ITEMS));
    } catch (_) {
      callback(MOCK_ITEMS);
      return () => {};
    }
  },

  async getAllItems() {
    try {
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), 1500)
      );
      const q = query(collection(db, 'items'), orderBy('createdAt', 'desc'));
      const snap = await Promise.race([getDocs(q), timeoutPromise]);
      if (snap.empty) return MOCK_ITEMS;
      return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch (_) {
      return MOCK_ITEMS;
    }
  },

  async getPendingVerificationItems() {
    const all = await this.getAllItems();
    return all.filter((i) => {
      const v = (i.verificationStatus || 'pending').toString().toLowerCase();
      return v === 'pending' || i.verifiedByAdmin === false;
    });
  },

  async getReturnedItems() {
    const all = await this.getAllItems();
    return all.filter((i) => {
      const s = (i.itemStatus || i.status || '').toString().toLowerCase();
      return s === 'returned';
    });
  },

  async getItemById(itemId) {
    try {
      const snap = await getDoc(doc(db, 'items', itemId));
      return snap.exists() ? { id: snap.id, ...snap.data() } : MOCK_ITEMS.find((i) => i.id === itemId) || null;
    } catch (_) {
      return MOCK_ITEMS.find((i) => i.id === itemId) || null;
    }
  },

  async updateItemStatus(itemId, status, adminNotes = '') {
    try {
      const ref = doc(db, 'items', itemId);
      const upperStatus = status.toUpperCase();
      const lowerStatus = status.toLowerCase();
      const update = {
        status: lowerStatus,
        itemStatus: upperStatus,
        updatedAt: Timestamp.now(),
      };
      if (adminNotes) update.adminNotes = adminNotes;
      if (lowerStatus === 'returned') update.returnedAt = Timestamp.now();
      await updateDoc(ref, update);
    } catch (_) {}
  },

  async markAsClaimed(itemId) {
    return this.updateItemStatus(itemId, 'claimed', 'Marked as claimed by admin');
  },

  async markAsReturned(itemId) {
    return this.updateItemStatus(itemId, 'returned', 'Marked as returned by admin');
  },

  async verifyOwnership(itemId, verified = true) {
    try {
      await updateDoc(doc(db, 'items', itemId), {
        verificationStatus: verified ? 'VERIFIED' : 'REJECTED',
        verifiedByAdmin: verified,
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },

  async rejectVerification(itemId, adminNotes = 'Verification rejected by admin') {
    try {
      await updateDoc(doc(db, 'items', itemId), {
        verificationStatus: 'REJECTED',
        verifiedByAdmin: false,
        adminNotes: adminNotes,
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },

  async deleteItem(itemId) {
    try {
      await updateDoc(doc(db, 'items', itemId), {
        isActive: false,
        itemStatus: 'CLOSED',
        status: 'closed',
        updatedAt: Timestamp.now(),
      });
    } catch (_) {}
  },

  async hardDeleteItem(itemId) {
    try {
      await deleteDoc(doc(db, 'items', itemId));
    } catch (_) {}
  },

  async getStats() {
    try {
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), 1500)
      );
      const snap = await Promise.race([getDocs(collection(db, 'items')), timeoutPromise]);
      if (snap.empty) return calculateStats(MOCK_ITEMS);
      const items = snap.docs.map((d) => d.data());
      return calculateStats(items);
    } catch (_) {
      return calculateStats(MOCK_ITEMS);
    }
  },

  async getClaimedItems() {
    const all = await this.getAllItems();
    return all.filter((i) => {
      const s = (i.itemStatus || i.status || '').toString().toLowerCase();
      return s === 'claimed' || s === 'returned';
    });
  },
};
