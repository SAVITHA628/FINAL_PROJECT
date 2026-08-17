# FoundIt AI/ML Image & Metadata Matching Service

Standalone Python AI/ML microservice for comparing **LOST** and **FOUND** item reports to identify possible matches using multimodal deep learning image embeddings and TF-IDF metadata similarity scoring.

---

## 🏗️ Architecture & Multimodal Pipeline

```
          [Lost Item Report]                  [Found Item Report]
         (Image + Metadata)                  (Image + Metadata)
                  │                                   │
                  ├─────────────────┬─────────────────┤
                  ▼                 ▼                 ▼
          MobileNetV3 Image     TF-IDF Text    Category Exact
            Feature Vector     Vectorization       Matcher
                  │                 │                 │
                  ▼                 ▼                 ▼
          Image Cosine Sim   Text Cosine Sim   Category Match
             Score (S_img)     Score (S_txt)     Score (S_cat)
                  │                 │                 │
                  └─────────────────┼─────────────────┘
                                    ▼
                      Multimodal Score Fusion:
          S_final = 0.60 * S_img + 0.40 * (0.35*S_cat + 0.35*S_title + 0.20*S_desc + 0.10*S_loc)
                                    │
                                    ▼
                       S_final ≥ Threshold (0.75)?
                               ┌────┴────┐
                            YES│         │NO
                               ▼         ▼
                      [POSSIBLE MATCH] [NO MATCH]
                               │
                               ▼
                    Store in Firestore `matches`
                    Check Duplicate Prevention
                               │
                               ▼
                   Dispatch FCM Notification
```

---

## 🧮 Mathematical Model & Similarity Methods

### 1. Image Feature Embedding
Extracts 576-dimensional feature vectors $\mathbf{u}, \mathbf{v} \in \mathbb{R}^{576}$ using pretrained **MobileNetV3-Small** (or **ResNet-18**).
The vectors are normalized using L2 normalization:
$$\hat{\mathbf{u}} = \frac{\mathbf{u}}{\|\mathbf{u}\|_2}$$

Image similarity score $S_{\text{img}}$ is computed using **Cosine Similarity**:
$$S_{\text{img}} = \hat{\mathbf{u}} \cdot \hat{\mathbf{v}} = \frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{u}\|_2 \|\mathbf{v}\|_2}$$

### 2. Metadata Text Similarity
Computes term frequency-inverse document frequency (TF-IDF) feature vectors across title, description, category, and location strings.
$$S_{\text{text}} = 0.35 \cdot S_{\text{category}} + 0.35 \cdot S_{\text{title}} + 0.20 \cdot S_{\text{desc}} + 0.10 \cdot S_{\text{location}}$$

### 3. Feature Fusion & Decision Threshold
$$S_{\text{final}} = w_{\text{img}} \cdot S_{\text{img}} + w_{\text{text}} \cdot S_{\text{text}}$$
Default weights: $w_{\text{img}} = 0.60$, $w_{\text{text}} = 0.40$.  
Match Decision: If $S_{\text{final}} \ge 0.75$, item pair is flagged as a **POSSIBLE MATCH**.

---

## 🛡️ Key Features

1. **Standalone Microservice**: Completely decoupled from Flutter/React codebases.
2. **Configurable Thresholds**: All parameters stored cleanly in `config.py` / environment variables.
3. **Duplicate Prevention**: Checks Firestore `matches` collection before dispatching FCM notifications to prevent duplicate alerts.
4. **Structured Firestore Schema**: Stores matches in `matches` collection and payloads in `notifications`.
5. **Evaluation Suite**: Includes `evaluation/evaluate_model.py` for evaluating Accuracy, Precision, Recall, and F1-Score on benchmark datasets.

---

## 🚀 Execution Guide

### 1. Install Dependencies
```bash
cd foundit_ai_service
pip install -r requirements.txt
```

### 2. Run API Server
```bash
python main.py
```
Server runs at **http://localhost:8000** with interactive Swagger documentation at **http://localhost:8000/docs**.

### 3. Run Benchmark Model Evaluation
```bash
python evaluation/evaluate_model.py
```

---

## 📡 API Endpoints

- `GET /` — Health check & model parameters.
- `POST /api/match` — Compare 1 LOST item vs 1 FOUND item and return similarity score.
- `POST /api/scan-matches` — Batch scan all LOST items against all FOUND items in Firestore.
