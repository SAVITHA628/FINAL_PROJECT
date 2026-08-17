import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';
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

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('phone') || cat.contains('electro') || cat.contains('charger')) {
      return Icons.devices_other_rounded;
    } else if (cat.contains('card') || cat.contains('id')) {
      return Icons.badge_rounded;
    } else if (cat.contains('key')) {
      return Icons.vpn_key_rounded;
    } else if (cat.contains('wallet')) {
      return Icons.account_balance_wallet_rounded;
    } else if (cat.contains('bag') || cat.contains('pack')) {
      return Icons.backpack_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  LinearGradient _getCategoryGradient(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('phone') || cat.contains('electro')) {
      return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]);
    } else if (cat.contains('card') || cat.contains('id')) {
      return const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)]);
    } else if (cat.contains('key')) {
      return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]);
    } else if (cat.contains('wallet')) {
      return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]);
    }
    return const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]);
  }

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
                  // Image Thumbnail with Hero transition & fallback category gradient
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: _getCategoryGradient(item.category),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                _getCategoryIcon(item.category),
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                    ),
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
                          color: AppColors.primary.withValues(alpha: 0.15),
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
                          color: AppColors.success.withValues(alpha: 0.15),
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
