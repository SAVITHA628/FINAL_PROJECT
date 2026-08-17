import logging
from typing import Optional, List
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

from config import Config
from matcher.match_pipeline import MultimodalMatchPipeline
from firebase.firebase_client import FirebaseClient

# Configure Logging
logging.basicConfig(
    level=getattr(logging, Config.LOG_LEVEL),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("foundit_ai_service")

# Initialize FastAPI App
app = FastAPI(
    title="FoundIt AI/ML Matching Service",
    description="Multimodal Image & Text Feature Fusion Matching Service for Lost & Found Items",
    version="1.0.0",
)

# Initialize Services
pipeline = MultimodalMatchPipeline()
firebase_client = FirebaseClient()

# Request Data Models
class ItemSchema(BaseModel):
  itemId: str = Field(..., example="item_101")
  userId: Optional[str] = Field(default="", example="user_001")
  title: str = Field(..., example="Blue Samsung Galaxy Phone")
  description: Optional[str] = Field(default="", example="Lost blue phone in library")
  category: str = Field(..., example="Electronics")
  location: Optional[str] = Field(default="", example="Library Cafeteria")
  imageUrl: Optional[str] = Field(default=None, example="https://example.com/img.jpg")
  itemType: Optional[str] = Field(default="LOST", example="LOST")

class MatchPairRequest(BaseModel):
  lostItem: ItemSchema
  foundItem: ItemSchema

class ScanMatchesResponse(BaseModel):
  totalLostChecked: int
  totalFoundChecked: int
  totalMatchesFound: int
  matches: List[dict]

@app.get("/")
def health_check():
  return {
      "service": "FoundIt AI/ML Matching Service",
      "status": "HEALTHY",
      "config": {
          "matchThreshold": Config.MATCH_THRESHOLD,
          "imageWeight": Config.IMAGE_WEIGHT,
          "textWeight": Config.TEXT_WEIGHT,
          "model": Config.MODEL_NAME,
      },
  }

@app.post("/api/match")
def match_item_pair(request: MatchPairRequest):
  """Compare a single LOST item against a FOUND item and calculate multimodal similarity score."""
  try:
    lost_dict = request.lostItem.model_dump()
    found_dict = request.foundItem.model_dump()

    match_result = pipeline.compare_items(lost_dict, found_dict)

    if match_result["isMatch"]:
      firebase_client.save_match_result(match_result)

    return match_result
  except Exception as e:
    logger.error(f"Error executing item match: {e}")
    raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/scan-matches", response_model=ScanMatchesResponse)
def scan_all_matches(background_tasks: BackgroundTasks):
  """Scan all active LOST items against active FOUND items in Firestore database."""
  try:
    lost_items = firebase_client.fetch_items_by_type("LOST")
    found_items = firebase_client.fetch_items_by_type("FOUND")

    logger.info(f"Scanning {len(lost_items)} LOST items against {len(found_items)} FOUND items...")

    matches_found = []
    for lost in lost_items:
      for found in found_items:
        result = pipeline.compare_items(lost, found)
        if result["isMatch"]:
          matches_found.append(result)
          # Asynchronously store to Firestore
          background_tasks.add_task(firebase_client.save_match_result, result)

    return ScanMatchesResponse(
        totalLostChecked=len(lost_items),
        totalFoundChecked=len(found_items),
        totalMatchesFound=len(matches_found),
        matches=matches_found,
    )
  except Exception as e:
    logger.error(f"Error scanning matches: {e}")
    raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
  import uvicorn
  logger.info(f"Starting FoundIt AI/ML Service on port {Config.PORT}...")
  uvicorn.run("main:app", host=Config.HOST, port=Config.PORT, reload=True)
