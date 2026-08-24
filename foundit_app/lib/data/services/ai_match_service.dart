import '../models/item_model.dart';
import '../../core/enums/item_type.dart';


class AiMatchResult {
  final String lostItemId;
  final String foundItemId;
  final double similarityScore;
  final double imageSimilarity;
  final double textSimilarity;
  final double categoryScore;
  final double titleScore;
  final bool isMatch;
  final double thresholdUsed;
  final String status;
  final ItemModel? lostItem;
  final ItemModel? foundItem;

  AiMatchResult({
    required this.lostItemId,
    required this.foundItemId,
    required this.similarityScore,
    required this.imageSimilarity,
    required this.textSimilarity,
    required this.categoryScore,
    required this.titleScore,
    required this.isMatch,
    required this.thresholdUsed,
    required this.status,
    this.lostItem,
    this.foundItem,
  });

  int get matchPercentage => (similarityScore * 100).round();

  factory AiMatchResult.fromJson(Map<String, dynamic> json, {ItemModel? lostItem, ItemModel? foundItem}) {
    return AiMatchResult(
      lostItemId: json['lostItemId'] ?? '',
      foundItemId: json['foundItemId'] ?? '',
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
      imageSimilarity: (json['imageSimilarity'] as num?)?.toDouble() ?? 0.0,
      textSimilarity: (json['textSimilarity'] as num?)?.toDouble() ?? 0.0,
      categoryScore: (json['categoryScore'] as num?)?.toDouble() ?? 0.0,
      titleScore: (json['titleScore'] as num?)?.toDouble() ?? 0.0,
      isMatch: json['isMatch'] ?? false,
      thresholdUsed: (json['thresholdUsed'] as num?)?.toDouble() ?? 0.55,
      status: json['status'] ?? 'NO_MATCH',
      lostItem: lostItem,
      foundItem: foundItem,
    );
  }
}

class AiMatchService {
  /// Uses client-side similarity only on mobile (no HTTP to prevent ANR freeze)
  Future<List<AiMatchResult>> scanMatches(List<ItemModel> allItems) async {
    final lostItems = allItems.where((i) => i.type == ItemType.lost).toList();
    final foundItems = allItems.where((i) => i.type == ItemType.found).toList();

    final List<AiMatchResult> results = [];
    for (final lost in lostItems) {
      for (final found in foundItems) {
        final res = _calculateClientSimilarity(lost, found);
        if (res.isMatch) results.add(res);
      }
    }

    results.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return results;
  }

  AiMatchResult _calculateClientSimilarity(ItemModel lost, ItemModel found) {
    double catScore = (lost.category.toLowerCase() == found.category.toLowerCase()) ? 1.0 : 0.0;

    final lostTokens = '${lost.title} ${lost.description}'.toLowerCase().split(RegExp(r'\s+'));
    final foundTokens = '${found.title} ${found.description}'.toLowerCase().split(RegExp(r'\s+'));

    int commonTokens = 0;
    for (final token in lostTokens) {
      if (token.length > 2 && foundTokens.contains(token)) commonTokens++;
    }

    final textSimilarity = lostTokens.isEmpty ? 0.0 : (commonTokens / lostTokens.length).clamp(0.0, 1.0);
    final score = (catScore * 0.4) + (textSimilarity * 0.6);
    final isMatch = catScore > 0 && score >= 0.45;

    return AiMatchResult(
      lostItemId: lost.id,
      foundItemId: found.id,
      similarityScore: score,
      imageSimilarity: 0.5,
      textSimilarity: textSimilarity,
      categoryScore: catScore,
      titleScore: textSimilarity,
      isMatch: isMatch,
      thresholdUsed: 0.45,
      status: isMatch ? 'POSSIBLE_MATCH' : 'NO_MATCH',
      lostItem: lost,
      foundItem: found,
    );
  }
}
