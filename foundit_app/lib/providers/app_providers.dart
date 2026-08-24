import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums/item_type.dart';
import '../data/models/item_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/ai_match_service.dart';
import '../data/services/mock_auth_service.dart';
import '../data/services/mock_item_service.dart';

// Always use mock services (Firebase removed for stability)
final isFirebaseInitializedProvider = Provider<bool>((ref) => false);

// AI Match Service Provider
final aiMatchServiceProvider = Provider<AiMatchService>((ref) => AiMatchService());

// AI Match Scan Results Provider
final aiMatchesProvider = FutureProvider<List<AiMatchResult>>((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  final aiService = ref.watch(aiMatchServiceProvider);
  final allItems = await repo.getActiveItems();
  return aiService.scanMatches(allItems);
});

// Always use Mock services
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(service: MockItemService());
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(service: MockAuthService());
});

// User state
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(userRepositoryProvider).getCurrentUser();
});

// Selected Type Filter
final itemTypeFilterProvider = StateProvider<ItemType?>((ref) => null);

// Active items list provider
final activeItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  final filter = ref.watch(itemTypeFilterProvider);
  return repo.getActiveItems(typeFilter: filter);
});

// Single Item provider
final itemDetailProvider =
    FutureProvider.family<ItemModel?, String>((ref, itemId) async {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getItemById(itemId);
});

// Favourites provider
final favouriteIdsProvider = StreamProvider<List<String>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  yield user?.favouriteItemIds ?? [];
});

final favouriteItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getFavouriteItems(user.favouriteItemIds);
});

final favouritesNotifierProvider =
    StateNotifierProvider<FavouritesNotifier, List<String>>((ref) {
  return FavouritesNotifier(ref);
});

class FavouritesNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  FavouritesNotifier(this._ref) : super([]);

  Future<void> toggleFavourite(String itemId) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) return;
    await _ref.read(userRepositoryProvider).toggleFavourite(user.uid, itemId);
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(favouriteItemsProvider);
  }
}

// User items provider
final myReportedItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getUserItems(user.uid);
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchResultsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(itemRepositoryProvider);
  return repo.searchItems(query);
});
