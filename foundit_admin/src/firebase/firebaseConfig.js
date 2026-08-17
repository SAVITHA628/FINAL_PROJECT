// FoundIt Firebase Configuration

import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyA7MHJYcieASePHk34v_XzbQHFt6o1C8gY",
  authDomain: "foundit-6bc8a.firebaseapp.com",
  projectId: "foundit-6bc8a",
  storageBucket: "foundit-6bc8a.firebasestorage.app",
  messagingSenderId: "519371653363",
  appId: "1:519371653363:android:bd6d850a26e553d1957786",
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
