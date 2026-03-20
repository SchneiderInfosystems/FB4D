# FB4D – Backlog & Pending Features

This document tracks open items and planned enhancements for the FB4D library.

---

## 🔥 High Priority

(No high priority items currently)

---

## 🟡 Medium Priority

(No medium priority items currently)

---

## 🟢 Low Priority

### 1. Firestore: Implement `partitionQuery`
- **Firebase API:** `POST /documents:partitionQuery`
- **Purpose:** Split large queries into cursors for parallel reading
- **Effort:** Medium
- **Relevance:** Only meaningful for very large datasets

### 2. Realtime Database: Add `writeSizeLimit` query parameter constant
- **Firebase feature:** `writeSizeLimit=tiny|small|medium|large|unlimited` — protects against accidental large deletes
- **Effort:** Tiny — add a typed constant or helper to the existing `QueryParams` mechanism

### 3. Storage: Resumable (multipart) uploads for large files
- **GCS API:** `POST /upload/storage/v1/b/{bucket}/o?uploadType=resumable`
- **Purpose:** Upload large files reliably with progress tracking and pause/resume capability
- **Effort:** Medium — FB4D currently only supports simple (single-request) uploads

### 4. Storage: List objects with prefix/delimiter filtering
- **GCS API:** `GET /storage/v1/b/{bucket}/o?prefix=...&delimiter=...`
- **Purpose:** Browse "folders" in a bucket by simulating a directory structure
- **Effort:** Small — the API call exists, just needs query param support in `IFirebaseStorage`

### 5. Storage: Copy / Move object
- **GCS API:** `POST /storage/v1/b/{srcBucket}/o/{srcObject}/copyTo/b/{dstBucket}/o/{dstObject}`
- **Purpose:** Server-side copy without re-uploading the file content
- **Effort:** Small

### 6. Storage: Update object metadata without re-upload
- **GCS API:** `PATCH /storage/v1/b/{bucket}/o/{object}` with only metadata fields
- **Purpose:** Change content-type, custom metadata, cache-control etc. without re-uploading the file
- **Effort:** Small — `TStorageObject` already has metadata fields; needs a `PATCH` implementation

### 7. Cloud Functions: Support 2nd generation / Cloud Run URLs
- **Firebase feature:** 2nd gen functions are deployed as Cloud Run services with URL pattern `https://{functionName}-{hash}-{region}.a.run.app`
- **Current:** `FB4D.Functions.pas` uses the 1st gen `cloudfunctions.net` URL pattern only
- **Effort:** Small — allow passing a custom base URL or auto-detect gen2 URL format

### 8. Cloud Functions: Support HTTP-triggered (non-callable) functions
- **Firebase feature:** HTTP-triggered functions accept any HTTP method/body, not just the `{"data": ...}` callable wrapper
- **Current:** FB4D wraps everything in `{"data": ...}` and expects `{"result": ...}` — only works for Callable Functions
- **Effort:** Medium — new method variants that send raw bodies and receive raw responses

### 9. Gemini AI: Implement `embedContent` / `batchEmbedContents`
- **Gemini API:** `POST /v1beta/models/{model}:embedContent` and `:batchEmbedContents`
- **Purpose:** Generate text embedding vectors for semantic search, RAG pipelines, clustering
- **Effort:** Medium — new interface + implementation; no UI needed, pure data

### 10. Gemini AI: Implement Context Caching API (`cachedContent`)
- **Gemini API:** `POST /v1beta/cachedContents`, `GET`, `PATCH`, `DELETE`
- **Purpose:** Cache large, reusable context (system prompts, docs) server-side to reduce cost & latency (new in 2024)
- **Effort:** Medium — needs new `IGeminiCachedContent` interface

### 11. Gemini AI: Implement Files API
- **Gemini API:** `POST /upload/v1beta/files`, `GET /v1beta/files/{name}`, `DELETE /v1beta/files/{name}`
- **Purpose:** Upload audio/video/PDF files to Gemini for use in multimodal prompts without base64 encoding
- **Effort:** Medium — currently only base64 inline is supported for media

### 12. Vision ML: Implement async batch annotation
- **Cloud Vision API:** `POST /v1/images:asyncBatchAnnotate` and `POST /v1/files:asyncBatchAnnotate`
- **Purpose:** Process large sets of images or multi-page PDFs (>20 pages) asynchronously; results written to GCS
- **Effort:** Medium — needs polling or callback for long-running operation status

---

## 🔧 Technical Debt

(No technical debt items currently)

---

## ✅ Completed

| Date | Change |
|---|---|
| 2026-03-18 | Authentication: Fixed bugs in `fetchProvidersForEmail` and added unit tests for `unlinkProvider` |
| 2026-03-18 | Authentication: Implemented `signInWithCustomToken` |
| 2026-02-27 | Updated OAuth token endpoint from deprecated `googleapis.com/oauth2/v4/token` to `oauth2.googleapis.com/token` |
| 2026-02-27 | Upgraded Firestore REST API base URL from deprecated `v1beta1` to stable `v1` |
| 2026-02-27 | Initialized submodules `delphi-jose-jwt` and `delphi-markdown` |
| 2026-02-27 | Added `DUnitX/FBConfig.inc` to `.gitignore` to prevent accidental credential exposure |
| 2026-03-03 | Firestore: Implemented `runAggregationQuery` with COUNT, SUM, AVG support |
| 2026-03-03 | Resolved Dependabot security alerts for submodules |
| 2026-03-03 | Improved DUnitX test setup process and instructions |
| 2026-03-03 | Firestore: Implemented `batchGet` API Support for single-request document retrieval |
