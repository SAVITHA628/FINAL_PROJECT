import logging
from config import Config
from matcher.image_embedding import ImageEmbeddingExtractor
from matcher.text_similarity import TextSimilarityCalculator

logger = logging.getLogger(__name__)

class MultimodalMatchPipeline:

  def __init__(self):
    self.image_extractor = ImageEmbeddingExtractor()
    self.text_calculator = TextSimilarityCalculator()
    self.image_weight = Config.IMAGE_WEIGHT
    self.text_weight = Config.TEXT_WEIGHT
    self.threshold = Config.MATCH_THRESHOLD

  def compare_items(self, lost_item: dict, found_item: dict) -> dict:
    """Compare a LOST item and a FOUND item using Image + Metadata Text feature fusion.
    
    Returns:
      dict containing match score, component scores, and boolean is_match decision.
    """
    lost_id = lost_item.get('itemId') or lost_item.get('id')
    found_id = found_item.get('itemId') or found_item.get('id')

    logger.info(f"Comparing LOST item {lost_id} vs FOUND item {found_id}...")

    # 1. Image Similarity
    img_url_1 = lost_item.get('imageUrl')
    img_url_2 = found_item.get('imageUrl')
    image_score = self.image_extractor.calculate_similarity(img_url_1, img_url_2)

    # 2. Text & Metadata Similarity
    text_results = self.text_calculator.calculate_item_metadata_similarity(lost_item, found_item)
    text_score = text_results['overall_text_score']

    # 3. Multimodal Weighted Score
    final_score = (self.image_weight * image_score) + (self.text_weight * text_score)
    final_score = round(max(0.0, min(1.0, final_score)), 4)

    is_match = final_score >= self.threshold

    logger.info(
        f"Match result for ({lost_id}, {found_id}): Score={final_score} "
        f"(Image={image_score:.2f}, Text={text_score:.2f}) -> Match={is_match}"
    )

    return {
        'lostItemId': lost_id,
        'foundItemId': found_id,
        'similarityScore': final_score,
        'imageSimilarity': round(image_score, 4),
        'textSimilarity': round(text_score, 4),
        'categoryScore': text_results['category_score'],
        'titleScore': text_results['title_score'],
        'isMatch': is_match,
        'thresholdUsed': self.threshold,
        'status': 'POSSIBLE_MATCH' if is_match else 'NO_MATCH',
    }
