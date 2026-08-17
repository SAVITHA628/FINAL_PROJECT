# FoundIt – Lost & Found Smart App

> A centralized Lost & Found platform for college/community environments.

---

## Project Structure

```
FOUNDIT/
├── foundit_app/          ← Flutter mobile app (Android / iOS)
├── foundit_admin/        ← React.js admin dashboard
├── firestore.rules       ← Firestore Security Rules
└── storage.rules         ← Firebase Storage Security Rules
```

---

## 🚀 Quick Start

### 1. Firebase Setup (REQUIRED FIRST)

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Enable **Authentication** → Email/Password
3. Enable **Firestore Database** → Start in production mode
4. Enable **Storage** → Start in production mode
5. Enable **Cloud Messaging**

### 2. React Admin Dashboard

```bash
cd foundit_admin
npm install
```

Edit `src/firebase/firebaseConfig.js` and replace the placeholder values with your Firebase project config.

```bash
npm run dev
# Opens at http://localhost:5173
```

**Creating the first admin user:**
1. Register via Firebase Console → Authentication → Add user
2. In Firestore Console, create a document in `users/{userId}` with `role: "admin"`

### 3. Flutter Mobile App

**Prerequisites:**
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Install [Android Studio](https://developer.android.com/studio) with Android emulator
- Install Firebase CLI: `npm install -g firebase-tools`
- Install FlutterFire CLI: `dart pub global activate flutterfire_cli`

```bash
cd foundit_app

# Configure Firebase for Flutter (generates firebase_options.dart)
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run
```

---

## 📱 Flutter App Features

| Feature | Status |
|---|---|
| User Registration & Login | ✅ |
| Splash Screen with animation | ✅ |
| Home Screen with real-time item stream | ✅ |
| Filter by Lost / Found / All | ✅ |
| Search items | ✅ |
| Add item with image upload | ✅ |
| Edit item | ✅ |
| Delete item (soft-delete) | ✅ |
| Item detail view | ✅ |
| Call reporter | ✅ |
| WhatsApp contact | ✅ |
| Favourite items | ✅ |
| Claim item | ✅ |
| Status tracking (active/claimed/returned) | ✅ |
| Push notifications (FCM) | ✅ |
| My profile & reported items | ✅ |
| Notifications screen | ✅ |

---

## 🖥️ Admin Dashboard Features

| Feature | Status |
|---|---|
| Admin login | ✅ |
| Dashboard with charts (bar + donut) | ✅ |
| Items management (search, filter, paginate) | ✅ |
| Item detail modal (status update, verify, notes) | ✅ |
| Users management (search, activate/deactivate, promote) | ✅ |
| Claims & Returns tracker | ✅ |
| TAT Report with date filter + CSV export | ✅ |
| Role-protected routes | ✅ |
| Collapsible sidebar | ✅ |
| Dark mode glassmorphism UI | ✅ |

---

## 🔥 Firebase Security Rules

Deploy the security rules:

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## 📦 Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter + Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Admin Dashboard | React.js (Vite) |
| Charts | Recharts |

---

## 🔮 Future: AI/ML Image Matching

The architecture is designed to connect a Python FastAPI microservice later:

```
Flutter App → POST /api/match-image → Python FastAPI → Firestore query → Ranked matches
```

No architectural changes are needed in Phase 1 to support this.

---

## 👥 User Roles

| Role | Capabilities |
|---|---|
| `user` | Report items, search, favourite, contact, claim |
| `admin` | All user actions + manage all items, verify, update status, view dashboard |

---

## 📊 Item Lifecycle

```
active → claimed → returned
              ↘ disputed
active → expired
```
