import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/app_providers.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/item_card.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favItemsAsync = ref.watch(favouriteItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
      ),
      body: favItemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading favourites: $err'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No saved items',
              message: 'Tap the heart icon on any item card to save it for quick reference.',
            );
          }

          return ListView.builder(
            padding: AppSpacing.paddingMd,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemCard(
                item: item,
                onTap: () => context.push('/item/${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
