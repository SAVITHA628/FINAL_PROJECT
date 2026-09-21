import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../providers/app_providers.dart';
import '../../common/widgets/app_image.dart';

class AiMatchesScreen extends ConsumerWidget {
  const AiMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiMatchesAsync = ref.watch(aiMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
            SizedBox(width: 8),
            Text('Possible Item Matches'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Matches',
            onPressed: () => ref.invalidate(aiMatchesProvider),
          ),
        ],
      ),
      body: aiMatchesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Running image & item feature similarity scan...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Text('Error scanning matches: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Conflicts or Matches Found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The matching service continuously scans active items in real time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final lost = match.lostItem;
              final found = match.foundItem;

              if (lost == null || found == null) return const SizedBox.shrink();

              final isHighMatch = match.similarityScore >= 0.7;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHighMatch ? AppColors.success.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isHighMatch
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: isHighMatch ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHighMatch ? 'HIGH PROBABILITY MATCH' : 'POSSIBLE MATCH DETECTED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isHighMatch ? AppColors.success : AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHighMatch ? AppColors.success : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${match.matchPercentage}% Match',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pair Comparison Row
                          Row(
                            children: [
                              // LOST Item Box
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.push('/item/${lost.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      children: [
                                        AppImage(
                                          imageUrl: lost.imageUrl,
                                          height: 80,
                                          width: double.infinity,
                                          borderRadius: BorderRadius.circular(10),
                                          category: lost.category,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'LOST: ${lost.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.error,
                                          ),
                                        ),
                                        Text(
                                          lost.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted, size: 24),
                              ),
                              // FOUND Item Box
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.push('/item/${found.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      children: [
                                        AppImage(
                                          imageUrl: found.imageUrl,
                                          height: 80,
                                          width: double.infinity,
                                          borderRadius: BorderRadius.circular(10),
                                          category: found.category,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'FOUND: ${found.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success,
                                          ),
                                        ),
                                        Text(
                                          found.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // AI Score Breakdown
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetric('Category', '${(match.categoryScore * 100).round()}%'),
                                _buildMetric('Text Match', '${(match.textSimilarity * 100).round()}%'),
                                _buildMetric('Image Feature', '${(match.imageSimilarity * 100).round()}%'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => LauncherUtils.callPhone(found.reporterPhone),
                                  icon: const Icon(Icons.call_rounded, size: 16),
                                  label: const Text('Call Finder'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/item/${found.id}'),
                                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                                  label: const Text('Claim Found Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
