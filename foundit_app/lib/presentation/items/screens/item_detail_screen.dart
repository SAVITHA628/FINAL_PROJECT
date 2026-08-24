import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_status.dart';
import '../../../core/enums/item_type.dart';
import '../../../core/utils/launcher_utils.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/status_badge.dart';
import '../../common/widgets/type_badge.dart';
import '../../common/widgets/verification_badge.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isClaiming = false;

  Future<void> _claimItem(ItemModel item) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to claim an item.')),
        );
      }
      return;
    }

    setState(() => _isClaiming = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.markAsClaimed(item.id, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(activeItemsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error claiming item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeItemsAsync = ref.watch(activeItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: activeItemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (items) {
          final item = items.firstWhere(
            (i) => i.id == widget.itemId,
            orElse: () => ItemModel(
              id: widget.itemId,
              type: ItemType.lost,
              title: 'Item Detail View',
              description: 'Detailed description of the lost or found item.',
              category: 'General',
              location: 'Campus Ground',
              reportedBy: 'user_001',
              reporterName: 'Reporter Contact',
              reporterPhone: '+919876543210',
              status: ItemStatus.active,
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Robust Image Display box with AppImage
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AppImage(
                    imageUrl: item.imageUrl,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    category: item.category,
                  ),
                ),
                const SizedBox(height: 20),

                // Badges Row
                Row(
                  children: [
                    TypeBadge(type: item.type),
                    const SizedBox(width: 8),
                    StatusBadge(status: item.status),
                    const SizedBox(width: 8),
                    VerificationBadge(status: item.verificationStatus),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Description Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.category_rounded,
                        'Category',
                        item.category,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.location_on_rounded,
                        'Location',
                        item.location,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.calendar_today_rounded,
                        'Date Reported',
                        item.dateLostOrFound != null
                            ? DateFormat('dd MMM yyyy')
                                .format(item.dateLostOrFound!)
                            : 'Recent',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reporter Contact Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REPORTER CONTACT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.brandGradient,
                            ),
                            child: Center(
                              child: Text(
                                item.reporterName.isNotEmpty
                                    ? item.reporterName[0].toUpperCase()
                                    : 'R',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.reporterName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                item.reporterPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  LauncherUtils.callPhone(item.reporterPhone),
                              icon: const Icon(Icons.call_rounded, size: 18),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              onPressed: () => LauncherUtils.openWhatsApp(
                                item.reporterPhone,
                                message:
                                    'Hi ${item.reporterName}, regarding item: ${item.title} on FoundIt.',
                              ),
                              icon: const Icon(Icons.chat_bubble_rounded,
                                  size: 18),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Claim Item Button
                if (item.status == ItemStatus.active) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isClaiming ? null : () => _claimItem(item),
                      child: _isClaiming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Claim This Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
