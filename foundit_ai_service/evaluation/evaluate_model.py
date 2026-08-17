import os
import sys
import logging
import numpy as np

# Ensure parent directory is in Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from matcher.match_pipeline import MultimodalMatchPipeline
from config import Config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("evaluate_model")

# Ground-truth evaluation benchmark dataset
EVALUATION_DATASET = [
    # Positive Match 1: Same item reported lost and found
    {
        "lostItem": {
            "itemId": "eval_lost_01",
            "title": "Blue Samsung Galaxy Phone",
            "description": "Lost my blue Samsung A54 with transparent case and stickers.",
            "category": "Electronics",
            "location": "Library Cafeteria",
            "imageUrl": "https://raw.githubusercontent.com/tensorflow/models/master/research/slim/nets/mobilenet/README.md"
        },
        "foundItem": {
            "itemId": "eval_found_01",
            "title": "Found Samsung Galaxy Mobile Phone",
            "description": "Blue Samsung phone found on cafeteria table near library.",
            "category": "Electronics",
            "location": "Library Cafeteria",
            "imageUrl": "https://raw.githubusercontent.com/tensorflow/models/master/research/slim/nets/mobilenet/README.md"
        },
        "groundTruth": True # True Match
    },

    # Positive Match 2: College ID Card
    {
        "lostItem": {
            "itemId": "eval_lost_02",
            "title": "Student ID Card - Priya Sharma",
            "description": "Lost ID card with lanyard near main gate.",
            "category": "ID Card",
            "location": "Main Gate",
        },
        "foundItem": {
            "itemId": "eval_found_02",
            "title": "Priya Sharma Campus ID Card",
            "description": "Found CSE ID card near entrance.",
            "category": "ID Card",
            "location": "Main Gate",
        },
        "groundTruth": True # True Match
    },

    # Negative Match 1: Different categories
    {
        "lostItem": {
            "itemId": "eval_lost_03",
            "title": "Silver Maruti Car Keys",
            "description": "Car key ring with red keychain.",
            "category": "Keys",
            "location": "Canteen",
        },
        "foundItem": {
            "itemId": "eval_found_03",
            "title": "Black HP Laptop Charger 65W",
            "description": "Found HP charger near Lab 204.",
            "category": "Electronics",
            "location": "Lab 204",
        },
        "groundTruth": False # Non-Match
    },

    # Negative Match 2: Same category, completely different item
    {
        "lostItem": {
            "itemId": "eval_lost_04",
            "title": "Apple iPhone 14 Pro Max Gold",
            "description": "Gold iPhone lost in auditorium.",
            "category": "Electronics",
            "location": "Auditorium",
        },
        "foundItem": {
            "itemId": "eval_found_04",
            "title": "Dell Wireless Mouse Black",
            "description": "Wireless mouse found in Lab 101.",
            "category": "Electronics",
            "location": "Lab 101",
        },
        "groundTruth": False # Non-Match
    }
]

def run_evaluation():
    """Evaluate baseline MobileNetV3 + TF-IDF model on benchmark dataset."""
    pipeline = MultimodalMatchPipeline()

    logger.info("==================================================")
    logger.info("  FOUNDIT AI/ML MODEL EVALUATION PROCEDURE")
    logger.info("==================================================")
    logger.info(f"Model Baseline: {Config.MODEL_NAME}")
    logger.info(f"Configured Threshold: {Config.MATCH_THRESHOLD}")
    logger.info(f"Image Weight: {Config.IMAGE_WEIGHT}, Text Weight: {Config.TEXT_WEIGHT}")
    logger.info("--------------------------------------------------")

    true_positives = 0
    false_positives = 0
    true_negatives = 0
    false_negatives = 0

    results = []

    for idx, sample in enumerate(EVALUATION_DATASET, 1):
        lost = sample["lostItem"]
        found = sample["foundItem"]
        expected = sample["groundTruth"]

        match_res = pipeline.compare_items(lost, found)
        predicted = match_res["isMatch"]
        score = match_res["similarityScore"]

        if predicted and expected:
            true_positives += 1
            status = "PASS (TP)"
        elif predicted and not expected:
            false_positives += 1
            status = "FAIL (FP)"
        elif not predicted and not expected:
            true_negatives += 1
            status = "PASS (TN)"
        else:
            false_negatives += 1
            status = "FAIL (FN)"

        logger.info(
            f"Sample #{idx}: Score={score:.4f} | Predicted={predicted} | "
            f"Expected={expected} | Result={status}"
        )

        results.append({
            "score": score,
            "expected": expected,
            "predicted": predicted
        })

    # Metrics Calculation
    total = len(EVALUATION_DATASET)
    accuracy = (true_positives + true_negatives) / total if total > 0 else 0
    precision = true_positives / (true_positives + false_positives) if (true_positives + false_positives) > 0 else 0
    recall = true_positives / (true_positives + false_negatives) if (true_positives + false_negatives) > 0 else 0
    f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

    logger.info("--------------------------------------------------")
    logger.info("           EVALUATION METRICS REPORT")
    logger.info("--------------------------------------------------")
    logger.info(f"Total Benchmark Samples : {total}")
    logger.info(f"True Positives (TP)     : {true_positives}")
    logger.info(f"True Negatives (TN)     : {true_negatives}")
    logger.info(f"False Positives (FP)    : {false_positives}")
    logger.info(f"False Negatives (FN)    : {false_negatives}")
    logger.info(f"Accuracy                : {accuracy * 100:.2f}%")
    logger.info(f"Precision               : {precision * 100:.2f}%")
    logger.info(f"Recall                  : {recall * 100:.2f}%")
    logger.info(f"F1-Score                : {f1_score * 100:.2f}%")
    logger.info("==================================================")
    logger.info("NOTE: This baseline evaluation provides initial benchmark metrics.")
    logger.info("A full campus dataset (>500 samples) must be evaluated before production deployment.")
    logger.info("==================================================")

if __name__ == "__main__":
    run_evaluation()
