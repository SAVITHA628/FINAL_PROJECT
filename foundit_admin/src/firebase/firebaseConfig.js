// FoundIt Firebase Configuration - Web Admin Dashboard
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyDoCFwz_NJzW05Tv8dDjK5QyAXRv8BZubs",
  authDomain: "foundit-6bc8a.firebaseapp.com",
  projectId: "foundit-6bc8a",
  storageBucket: "foundit-6bc8a.firebasestorage.app",
  messagingSenderId: "519371653363",
  appId: "1:519371653363:web:6091399672a73d1d957786",
  measurementId: "G-F1BG8KQYP1"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
