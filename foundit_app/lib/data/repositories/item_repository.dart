import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/item_service_interface.dart';
import '../services/mock_item_service.dart';

class ItemRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final MockItemService _mockService = MockItemService();

  ItemRepository({ItemServiceInterface? service});

  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    try {
      final firestoreItems = await _firestoreService.getActiveItems(typeFilter: typeFilter);
      if (firestoreItems.isNotEmpty) {
        return firestoreItems;
      }
    } catch (_) {}
    return _mockService.getActiveItems(typeFilter: typeFilter);
  }

  Future<ItemModel?> getItemById(String id) async {
    try {
      final item = await _firestoreService.getItemById(id);
      if (item != null) return item;
    } catch (_) {}
    return _mockService.getItemById(id);
  }

  Future<List<ItemModel>> searchItems(String query) async {
    try {
      final res = await _firestoreService.searchItems(query);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _mockService.searchItems(query);
  }

  Future<List<ItemModel>> getUserItems(String userId) async {
    try {
      final res = await _firestoreService.getUserItems(userId);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _mockService.getUserItems(userId);
  }

  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    try {
      final res = await _firestoreService.getFavouriteItems(favouriteIds);
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return _mockService.getFavouriteItems(favouriteIds);
  }

  Future<ItemModel> addItem(ItemModel item) async {
    try {
      return await _firestoreService.addItem(item);
    } catch (_) {
      return await _mockService.addItem(item);
    }
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    try {
      return await _firestoreService.updateItem(item);
    } catch (_) {
      return await _mockService.updateItem(item);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _firestoreService.deleteItem(id);
    } catch (_) {}
    await _mockService.deleteItem(id);
  }

  Future<void> markAsClaimed(String itemId, String claimantId) async {
    try {
      await _firestoreService.markAsClaimed(itemId, claimantId);
    } catch (_) {}
    await _mockService.markAsClaimed(itemId, claimantId);
  }
}
