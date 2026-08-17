import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums/item_type.dart';
import '../data/models/item_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/services/firebase_storage_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/mock_auth_service.dart';
import '../data/services/mock_item_service.dart';

// Firebase initialization flag provider
final isFirebaseInitializedProvider = Provider<bool>((ref) => false);

// Storage service provider
final firebaseStorageServiceProvider =
    Provider<FirebaseStorageService>((ref) => FirebaseStorageService());

// Repository instances with automatic service selection (Firebase vs Mock)
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final isFirebase = ref.watch(isFirebaseInitializedProvider);
  return ItemRepository(
    service: isFirebase ? FirestoreService() : MockItemService(),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final isFirebase = ref.watch(isFirebaseInitializedProvider);
  return UserRepository(
    service: isFirebase ? FirebaseAuthService() : MockAuthService(),
  );
});

// User state
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(userRepositoryProvider).getCurrentUser();
});

// Selected Type Filter (all, lost, found)
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
