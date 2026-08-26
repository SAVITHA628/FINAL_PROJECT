import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/item_service_interface.dart';

class ItemRepository {
  final FirestoreService _firestoreService = FirestoreService();

  ItemRepository({ItemServiceInterface? service});

  // Pure real-time Firebase data only (zero demo/mock data)
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    try {
      return await _firestoreService.getActiveItems(typeFilter: typeFilter);
    } catch (e) {
      return [];
    }
  }

  Future<ItemModel?> getItemById(String id) async {
    try {
      return await _firestoreService.getItemById(id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ItemModel>> searchItems(String query) async {
    try {
      return await _firestoreService.searchItems(query);
    } catch (_) {
      return [];
    }
  }

  Future<List<ItemModel>> getUserItems(String userId) async {
    try {
      return await _firestoreService.getUserItems(userId);
    } catch (_) {
      return [];
    }
  }

  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    try {
      return await _firestoreService.getFavouriteItems(favouriteIds);
    } catch (_) {
      return [];
    }
  }

  Future<ItemModel> addItem(ItemModel item) async {
    return await _firestoreService.addItem(item);
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    return await _firestoreService.updateItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _firestoreService.deleteItem(id);
  }

  Future<void> markAsClaimed(String itemId, String claimantId) async {
    await _firestoreService.markAsClaimed(itemId, claimantId);
  }
}
