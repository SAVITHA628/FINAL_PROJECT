import os

class Config:
  """FoundIt AI/ML Service Configuration."""

  # Matching Thresholds (Optimized baseline threshold from benchmark evaluation)
  MATCH_THRESHOLD = float(os.getenv("MATCH_THRESHOLD", "0.55"))
  HIGH_CONFIDENCE_THRESHOLD = float(
      os.getenv("HIGH_CONFIDENCE_THRESHOLD", "0.75")
  )

  # Multimodal Feature Weights (Image + Metadata Text)
  IMAGE_WEIGHT = float(os.getenv("IMAGE_WEIGHT", "0.50"))
  TEXT_WEIGHT = float(os.getenv("TEXT_WEIGHT", "0.50"))

  # Image Embedding Model Config
  MODEL_NAME = os.getenv("MODEL_NAME", "mobilenet_v3_small")
  IMAGE_SIZE = (224, 224)

  # API Server Config
  HOST = os.getenv("HOST", "0.0.0.0")
  PORT = int(os.getenv("PORT", "8000"))

  # Firebase Project Config
  FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "foundit-6bc8a")
  FIRESTORE_ITEMS_COLLECTION = "items"
  FIRESTORE_MATCHES_COLLECTION = "matches"
  FIRESTORE_NOTIFS_COLLECTION = "notifications"

  # Logging Config
  LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
