import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';
import 'app_image.dart';
import 'status_badge.dart';
import 'type_badge.dart';
import 'verification_badge.dart';

class ItemCard extends ConsumerWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouritesAsync = ref.watch(favouriteIdsProvider);
    final favouriteIds = favouritesAsync.valueOrNull ?? [];
    final isFav = favouriteIds.contains(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppImage handles base64, network, file, and fallback gracefully
                  AppImage(
                    imageUrl: item.imageUrl,
                    width: 96,
                    height: 96,
                    borderRadius: BorderRadius.circular(14),
                    category: item.category,
                  ),
                  const SizedBox(width: 14),

                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TypeBadge(type: item.type),
                            const SizedBox(width: 6),
                            StatusBadge(status: item.status),
                            const Spacer(),
                            // Favourite Button
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                              onPressed: () {
                                ref
                                    .read(favouritesNotifierProvider.notifier)
                                    .toggleFavourite(item.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Bottom Actions & Metadata Row
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Verification Status Badge
                  VerificationBadge(status: item.verificationStatus),
                  const SizedBox(width: 8),

                  // Call Button
                  if (item.reporterPhone.isNotEmpty) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => LauncherUtils.callPhone(item.reporterPhone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Call',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // WhatsApp Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => LauncherUtils.openWhatsApp(
                        item.reporterPhone,
                        message:
                            'Hi ${item.reporterName}, regarding your item: ${item.title} on FoundIt',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded,
                                size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
