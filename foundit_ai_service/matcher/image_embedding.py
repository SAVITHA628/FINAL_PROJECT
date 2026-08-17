import io
import logging
import numpy as np

logger = logging.getLogger(__name__)

try:
  import requests
  HAS_REQUESTS = True
except ImportError:
  HAS_REQUESTS = False

try:
  from PIL import Image
  HAS_PIL = True
except ImportError:
  HAS_PIL = False

try:
  import torch
  import torchvision.transforms as transforms
  import torchvision.models as models
  HAS_TORCH = True
except ImportError:
  HAS_TORCH = False


class ImageEmbeddingExtractor:

  def __init__(self):
    self.has_requests = HAS_REQUESTS
    self.has_pil = HAS_PIL
    self.has_torch = HAS_TORCH and HAS_PIL
    if self.has_torch:
      logger.info("Initializing MobileNetV3 Image Feature Extractor...")
      try:
        model = models.mobilenet_v3_small(
            weights=models.MobileNet_V3_Small_Weights.DEFAULT
        )
        model.eval()
        self.feature_extractor = torch.nn.Sequential(
            *list(model.children())[:-1]
        )
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
            ),
        ])
      except Exception as e:
        logger.warning(f"Could not load PyTorch model: {e}. Using fallback.")
        self.has_torch = False

  def download_image(self, image_url: str):
    """Download image from URL or return placeholder."""
    if not self.has_requests or not self.has_pil or not image_url:
      return None
    try:
      response = requests.get(image_url, timeout=5)
      response.raise_for_status()
      return Image.open(io.BytesIO(response.content)).convert("RGB")
    except Exception as e:
      logger.error(f"Failed to download image from {image_url}: {e}")
      return None

  def extract_embedding(self, image) -> np.ndarray:
    """Extract L2-normalized feature vector embedding."""
    if image is None:
      return None

    if self.has_torch:
      try:
        tensor = self.transform(image).unsqueeze(0)
        with torch.no_grad():
          features = self.feature_extractor(tensor).squeeze()
          features = features.view(-1).numpy()
          norm = np.linalg.norm(features)
          return features / norm if norm > 0 else features
      except Exception as e:
        logger.error(f"PyTorch embedding extraction failed: {e}")

    if self.has_pil and image:
      img_resized = image.resize((64, 64))
      hist = np.array(img_resized.histogram(), dtype=np.float32)
      norm = np.linalg.norm(hist)
      return hist / norm if norm > 0 else hist

    return None

  def calculate_similarity(
      self, image_url_1: str, image_url_2: str
  ) -> float:
    """Download two images and calculate Cosine Similarity score (0.0 to 1.0)."""
    if not image_url_1 or not image_url_2:
      return 0.5

    img1 = self.download_image(image_url_1)
    img2 = self.download_image(image_url_2)

    if img1 is None or img2 is None:
      return 0.5

    emb1 = self.extract_embedding(img1)
    emb2 = self.extract_embedding(img2)

    if emb1 is None or emb2 is None:
      return 0.5

    similarity = float(np.dot(emb1, emb2))
    return max(0.0, min(1.0, (similarity + 1.0) / 2.0 if self.has_torch else similarity))
