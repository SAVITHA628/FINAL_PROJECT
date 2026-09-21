# MATCHING_AUDIT.md — FoundIt Matching Implementation Audit

## 1. Executive Summary

- **Is AI used?**: YES (Standalone Python Microservice `foundit_ai_service`)
- **Is ML used?**: YES (PyTorch MobileNetV3-Small Deep Learning Feature Embedding & TF-IDF Vectorization)
- **Client-Side Fallback**: YES (Client-side token similarity algorithm in `foundit_app` for offline/mobile execution without localhost server dependency)

---

## 2. Technical Matching Architecture

```
[Lost Item Report] + [Found Item Report]
                    │
   ┌────────────────┴────────────────┐
   ▼                                 ▼
[Python AI Microservice]    [Mobile Client Fallback]
 (foundit_ai_service)             (foundit_app)
   │                                 │
   ├─ PyTorch MobileNetV3            ├─ Token Jaccard Overlap
   ├─ Scikit-Learn TF-IDF            └─ Category Strict Filter
   └─ Multimodal Fusion (0.50/0.50)  └─ Weighted Score (0.40/0.60)
```

---

## 3. Python AI Microservice Implementation (`foundit_ai_service`)

- **Actual Algorithm**: Multimodal Image + Metadata Text Feature Fusion
- **Actual Models**:
  - Image: `torchvision.models.mobilenet_v3_small` (Pre-trained PyTorch weights)
  - Text: `sklearn.feature_extraction.text.TfidfVectorizer`
- **Image Processing**: Resized to 224×224, normalized via ImageNet mean/std (`[0.485, 0.456, 0.406]`, `[0.229, 0.224, 0.225]`), extracted L2-normalized 576-dimensional feature embeddings.
- **Text Processing**: Standardized tokenization, English stop-words removal, TF-IDF vector matrix transformation.
- **Similarity Calculation**: Cosine Similarity ($\mathbf{a} \cdot \mathbf{b} / \|\mathbf{a}\| \|\mathbf{b}\|$)
- **Multimodal Formula**:
  $$S_{\text{multimodal}} = 0.50 \cdot S_{\text{image}} + 0.50 \cdot S_{\text{text}}$$
  $$S_{\text{text}} = 0.35 \cdot S_{\text{category}} + 0.35 \cdot S_{\text{title}} + 0.20 \cdot S_{\text{description}} + 0.10 \cdot S_{\text{location}}$$
- **Decision Threshold**: $S_{\text{multimodal}} \ge 0.55 \implies \text{POSSIBLE\_MATCH}$
- **Python FastAPI Endpoint**: `POST http://localhost:8000/api/match` and `POST http://localhost:8000/api/scan-matches`

---

## 4. Mobile App Matching Algorithm (`foundit_app`)

- **Implementation File**: `foundit_app/lib/data/services/ai_match_service.dart`
- **Client-Side Formula**:
  $$S_{\text{client}} = 0.40 \cdot S_{\text{category}} + 0.60 \cdot S_{\text{text\_tokens}}$$
- **Decision Criteria**:
  $$S_{\text{category}} = 1.0 \land S_{\text{client}} \ge 0.45 \implies \text{POSSIBLE\_MATCH}$$

---

## 5. Source Code Evidence

- `foundit_ai_service/matcher/image_embedding.py` (PyTorch MobileNetV3-Small feature extraction & L2 norm cosine dot product)
- `foundit_ai_service/matcher/text_similarity.py` (Scikit-Learn TF-IDF & pairwise cosine similarity)
- `foundit_ai_service/matcher/match_pipeline.py` (Multimodal score calculation)
- `foundit_app/lib/data/services/ai_match_service.dart` (Client-side token similarity fallback)

---

## 6. Important System Distinctions

- **Match Decision Output**: System produces **"POSSIBLE MATCH"** (Never "VERIFIED OWNER").
- **Human-in-the-loop**: Admin verification via React Admin Dashboard (`foundit_admin`) is strictly required before marking an item as `CLAIMED` or `RETURNED`.
