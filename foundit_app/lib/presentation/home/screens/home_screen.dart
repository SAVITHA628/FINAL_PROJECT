import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/app_providers.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/filter_chips_row.dart';
import '../../common/widgets/item_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeItemsAsync = ref.watch(activeItemsProvider);
    final selectedFilter = ref.watch(itemTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: AppColors.brandGradient,
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
            ),
            AppSpacing.gapSm,
            ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              child: const Text(
                'FoundIt',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(activeItemsProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: FilterChipsRow(
                  selectedType: selectedFilter,
                  onChanged: (type) {
                    ref.read(itemTypeFilterProvider.notifier).state = type;
                  },
                ),
              ),
            ),
            activeItemsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load items: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No items reported',
                      message: selectedFilter == null
                          ? 'Be the first to report a lost or found item!'
                          : 'No ${selectedFilter.isLost ? "lost" : "found"} items reported yet.',
                      action: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.addItem),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Report Item'),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
