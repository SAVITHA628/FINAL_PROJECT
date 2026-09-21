# PROJECT_TECHNICAL_AUDIT.md — FoundIt Complete Technical Audit & Architecture

## 1. System Architecture Overview

```
 ┌─────────────────────────────────────────────────────────┐
 │               FoundIt Mobile App (Flutter)              │
 └──────────┬──────────────────┬──────────────────┬────────┘
            │                  │                  │
            ▼                  ▼                  ▼
  ┌──────────────────┐┌──────────────────┐┌───────────────┐
  │  Firebase Auth   ││ Cloud Firestore  ││ Firebase FCM  │
  │ (User Identity)  ││ (NoSQL Database) ││(Notifications)│
  └──────────────────┘└────────┬─────────┘└───────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
  ┌──────────────────┐                  ┌──────────────────┐
  │ Firebase Storage │                  │ React Admin Web  │
  │  (Item Images)   │                  │ (foundit_admin)  │
  └──────────────────┘                  └──────────────────┘
```

---

## 2. Component Inventory

| Component | Stack | Purpose |
| :--- | :--- | :--- |
| **Mobile App** | Flutter 3.3.0+ / Dart | Cross-platform user application for reporting lost/found items, searching, and managing claims |
| **Backend Database** | Cloud Firestore | NoSQL collections: `users`, `items`, `notifications`, `matches` |
| **Authentication** | Firebase Auth / REST API | Password hashing (XOR-base64), session management, role verification |
| **Storage** | Firebase Storage | Image binary storage with mime-type & 5MB file-size limits |
| **Notifications** | FCM & In-app Firestore | Real-time notification document creation and streaming |
| **Admin Dashboard** | React.js / Vite | Web interface for item verification, claim review, user management, and statistics |
| **AI Service** | Python FastAPI / PyTorch | Standalone microservice for PyTorch MobileNetV3 + TF-IDF multimodal matching |

---

## 3. Data Schema & Collections

### `users/{uid}`
- `uid` (string)
- `name` (string)
- `email` (string)
- `registrationPhone` (string — strictly Profile phone number)
- `role` (string: `user` | `admin`)
- `passwordHash` (string)
- `favouriteItemIds` (array of strings — persisted favorites)
- `createdAt` (timestamp)

### `items/{itemId}`
- `id` (string)
- `type` (string: `LOST` | `FOUND`)
- `title` (string)
- `description` (string)
- `category` (string)
- `location` (string)
- `contactPhone` (string — item contact for calls)
- `contactWhatsApp` (string — item contact for WhatsApp)
- `imageUrl` (string)
- `status` (string: `active` | `claimed` | `returned` | `closed`)
- `verificationStatus` (string: `pending` | `verified` | `rejected`)
- `reportedBy` (string — owner UID)
- `createdAt` (timestamp)

### `notifications/{notifId}`
- `recipientId` (string — target user UID)
- `title` (string)
- `body` (string)
- `type` (string: `WELCOME` | `CLAIM` | `VERIFICATION` | `MATCH`)
- `isRead` (boolean)
- `createdAt` (timestamp)

---

## 4. Key Workflows & Verification

1. **Phone Separation**: User registration phone (`registrationPhone`) is stored on `users/{uid}` and displayed on the Profile screen. Item contact phone numbers (`contactPhone` & `contactWhatsApp`) are stored on `items/{itemId}` and displayed on item detail cards.
2. **Persistent Favorites**: Toggling a favorite writes the updated `favouriteItemIds` array to Cloud Firestore `users/{uid}`.
3. **Password Reset**: Validates the email against Firestore registered accounts before completing password reset requests.
4. **Ownership Claim Verification**: Matching engine generates **POSSIBLE MATCH** alerts. Claimants submit claim evidence, which must be reviewed and approved by an admin via the React Admin Dashboard before handover.

---

## 5. Security Rules Overview

- `firestore.rules`: Scoped permissions for `users`, `items`, `notifications`, `matches`.
- `storage.rules`: Scoped rules enforcing 5MB max upload size, `image/*` MIME type validation, and user ID folder isolation.
