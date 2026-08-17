import logging
import datetime
from config import Config

logger = logging.getLogger(__name__)

try:
  import firebase_admin
  from firebase_admin import credentials, firestore
  HAS_FIREBASE = True
except ImportError:
  HAS_FIREBASE = False


class FirebaseClient:
  """Firebase Firestore client for Python AI service."""

  def __init__(self):
    self.db = None
    self._init_firebase()

  def _init_firebase(self):
    if not HAS_FIREBASE:
      logger.info("firebase-admin module not installed. Running in standalone mode.")
      return

    try:
      if not firebase_admin._apps:
        firebase_admin.initialize_app(options={'projectId': Config.FIREBASE_PROJECT_ID})
      self.db = firestore.client()
      logger.info(f"Firebase Firestore initialized for project '{Config.FIREBASE_PROJECT_ID}'.")
    except Exception as e:
      logger.warning(f"Could not initialize firebase-admin SDK: {e}. Running in standalone mode.")

  def fetch_items_by_type(self, item_type: str) -> list:
    """Fetch active items from Firestore filtered by itemType ('LOST' or 'FOUND')."""
    if not self.db:
      return []

    try:
      items_ref = self.db.collection(Config.FIRESTORE_ITEMS_COLLECTION)
      query = items_ref.where('isActive', '==', True)
      docs = query.stream()

      result = []
      target_type = item_type.upper()
      for d in docs:
        data = d.to_dict()
        data['id'] = d.id
        itype = str(data.get('itemType') or data.get('type') or '').upper()
        istatus = str(data.get('itemStatus') or data.get('status') or '').upper()
        if itype == target_type and istatus == 'ACTIVE':
          result.append(data)
      return result
    except Exception as e:
      logger.error(f"Error fetching {item_type} items from Firestore: {e}")
      return []

  def is_duplicate_match(self, lost_item_id: str, found_item_id: str) -> bool:
    """Prevent duplicate match notifications by checking Firestore 'matches' collection."""
    if not self.db:
      return False

    try:
      matches_ref = self.db.collection(Config.FIRESTORE_MATCHES_COLLECTION)
      q = matches_ref.where('lostItemId', '==', lost_item_id).where('foundItemId', '==', found_item_id)
      docs = list(q.stream())
      return len(docs) > 0
    except Exception as e:
      logger.error(f"Error checking duplicate match in Firestore: {e}")
      return False

  def save_match_result(self, match_data: dict) -> str:
    """Store possible match result in Firestore 'matches' collection."""
    lost_id = match_data['lostItemId']
    found_id = match_data['foundItemId']

    if self.is_duplicate_match(lost_id, found_id):
      logger.info(f"Match record ({lost_id}, {found_id}) already exists. Skipping duplicate save.")
      return "DUPLICATE"

    if not self.db:
      logger.info(f"Standalone mode: Match result generated: {match_data}")
      return "LOCAL_SAVED"

    try:
      matches_ref = self.db.collection(Config.FIRESTORE_MATCHES_COLLECTION)
      doc_data = {
          'matchId': f"match_{lost_id}_{found_id}",
          'lostItemId': lost_id,
          'foundItemId': found_id,
          'similarityScore': match_data['similarityScore'],
          'imageSimilarity': match_data['imageSimilarity'],
          'textSimilarity': match_data['textSimilarity'],
          'categoryScore': match_data['categoryScore'],
          'status': 'POSSIBLE_MATCH',
          'createdAt': firestore.SERVER_TIMESTAMP,
      }
      doc_ref = matches_ref.add(doc_data)
      logger.info(f"Saved possible match to Firestore: {doc_ref[1].id}")
      return doc_ref[1].id
    except Exception as e:
      logger.error(f"Error saving match to Firestore: {e}")
      return None
