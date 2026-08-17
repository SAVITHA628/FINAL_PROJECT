import logging
import re

logger = logging.getLogger(__name__)

try:
  from sklearn.feature_extraction.text import TfidfVectorizer
  from sklearn.metrics.pairwise import cosine_similarity
  HAS_SKLEARN = True
except ImportError:
  HAS_SKLEARN = False


class TextSimilarityCalculator:

  def __init__(self):
    self.has_sklearn = HAS_SKLEARN
    if self.has_sklearn:
      self.vectorizer = TfidfVectorizer(stop_words='english')

  def calculate_text_similarity(self, text1: str, text2: str) -> float:
    """Calculate Cosine Similarity between two text strings."""
    if not text1 or not text2:
      return 0.0

    t1 = text1.strip().lower()
    t2 = text2.strip().lower()

    if t1 == t2:
      return 1.0

    if self.has_sklearn:
      try:
        tfidf_matrix = self.vectorizer.fit_transform([t1, t2])
        sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
        return float(sim)
      except Exception as e:
        logger.debug(f"TF-IDF similarity calculation fallback: {e}")

    # Fallback: Jaccard Word Token Overlap
    words1 = set(re.findall(r'\w+', t1))
    words2 = set(re.findall(r'\w+', t2))
    if not words1 or not words2:
      return 0.0
    intersection = words1.intersection(words2)
    union = words1.union(words2)
    return len(intersection) / len(union) if union else 0.0

  def calculate_item_metadata_similarity(
      self, lost_item: dict, found_item: dict
  ) -> dict:
    """Calculate structured metadata similarity across Category, Title, Description, and Location."""
    cat1 = str(lost_item.get('category', '')).strip().lower()
    cat2 = str(found_item.get('category', '')).strip().lower()
    category_score = 1.0 if cat1 == cat2 and cat1 != '' else (0.5 if cat1 in cat2 or cat2 in cat1 else 0.0)

    title_score = self.calculate_text_similarity(
        lost_item.get('title', ''), found_item.get('title', '')
    )

    desc_score = self.calculate_text_similarity(
        lost_item.get('description', ''), found_item.get('description', '')
    )

    loc_score = self.calculate_text_similarity(
        lost_item.get('location', ''), found_item.get('location', '')
    )

    weighted_text_score = (
        0.35 * category_score +
        0.35 * title_score +
        0.20 * desc_score +
        0.10 * loc_score
    )

    return {
        'category_score': round(category_score, 4),
        'title_score': round(title_score, 4),
        'desc_score': round(desc_score, 4),
        'loc_score': round(loc_score, 4),
        'overall_text_score': round(weighted_text_score, 4),
    }
