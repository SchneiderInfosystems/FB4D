# FB4D – Backlog & Pending Features

This document tracks open items and planned enhancements for the FB4D library.

---

## 🔥 High Priority

### 1. Firestore: Implement `runAggregationQuery`
- **Firebase API:** `POST /documents:runAggregationQuery`
- **Purpose:** Execute `COUNT`, `SUM`, `AVG` server-side without downloading documents
- **Available since:** Firestore REST API v1 (stable since 2023)
- **Effort:** Medium — new interface methods in `IFirestoreDatabase`, implementation in `FB4D.Firestore.pas`
- **Relevance:** Frequently needed in production applications to avoid unnecessary data transfer

---

## 🟡 Medium Priority

### 2. Authentication: Implement `signInWithCustomToken`
- **Firebase API:** `POST /accounts:signInWithCustomToken`
- **Purpose:** Sign in with a custom backend-generated JWT token (for apps with their own authentication server)
- **Effort:** Small — new method in `TFirebaseAuthentication`

### 3. Firestore: Implement `batchGet`
- **Firebase API:** `POST /documents:batchGet`
- **Purpose:** Retrieve multiple documents (even from different collections) in a **single** HTTP request
- **Effort:** Medium
- **Relevance:** Useful for performance optimization in data-heavy scenarios

### 4. Firestore: Implement `batchWrite`
- **Firebase API:** `POST /documents:batchWrite`
- **Purpose:** Multiple write operations in a single request (without rollback guarantee, unlike transactions)
- **Effort:** Medium

---

## 🟢 Low Priority

### 5. Authentication: Implement `fetchProvidersForEmail` (`createAuthUri`)
- **Firebase API:** `POST /accounts:createAuthUri`
- **Purpose:** Query which auth providers (google.com, password, etc.) are registered for a given email address
- **Effort:** Small

### 6. Authentication: Implement `unlinkProvider`
- **Firebase API:** `POST /accounts:update` with `deleteProvider`
- **Purpose:** Detach an OAuth provider from a user account
- **Effort:** Small

### 7. Firestore: Implement `listCollectionIds`
- **Firebase API:** `POST /documents:listCollectionIds`
- **Purpose:** List all sub-collections of a document
- **Effort:** Small

### 8. Firestore: Implement `partitionQuery`
- **Firebase API:** `POST /documents:partitionQuery`
- **Purpose:** Split large queries into cursors for parallel reading
- **Effort:** Medium
- **Relevance:** Only meaningful for very large datasets

---

## 🔧 Technical Debt

### 9. Review GitHub Security Alerts
- GitHub Dependabot reports 5 vulnerabilities (1 critical, 2 high, 1 moderate, 1 low)
- Likely affects submodules (`delphi-jose-jwt`, `delphi-markdown`)
- **Action:** Review at https://github.com/SchneiderInfosystems/FB4D/security/dependabot

### 10. Make Integration Tests easier to run
- Improve `DUnitX/FBConfig.inc` template with clear setup instructions
- Evaluate whether some tests can run without real Firebase credentials (mock/stub)

---

## ✅ Completed

| Date | Change |
|---|---|
| 2026-02-27 | Updated OAuth token endpoint from deprecated `googleapis.com/oauth2/v4/token` to `oauth2.googleapis.com/token` |
| 2026-02-27 | Upgraded Firestore REST API base URL from deprecated `v1beta1` to stable `v1` |
| 2026-02-27 | Initialized submodules `delphi-jose-jwt` and `delphi-markdown` |
| 2026-02-27 | Added `DUnitX/FBConfig.inc` to `.gitignore` to prevent accidental credential exposure |
