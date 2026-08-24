import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'item_service_interface.dart';

class FirestoreService implements ItemServiceInterface {
  // User management
  Future<UserModel?> getUserById(String uid) async {
    return null;
  }

  Future<void> saveUser(UserModel user) async {}

  Future<void> toggleUserFavourite(String userId, String itemId) async {}

  // Item management
  @override
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    return [];
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    return null;
  }

  @override
  Future<List<ItemModel>> searchItems(String queryText) async {
    return [];
  }

  @override
  Future<List<ItemModel>> getUserItems(String userId) async {
    return [];
  }

  @override
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    return [];
  }

  @override
  Future<ItemModel> addItem(ItemModel item) async {
    throw UnimplementedError('No Firestore');
  }

  @override
  Future<ItemModel> updateItem(ItemModel item) async {
    throw UnimplementedError('No Firestore');
  }

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<void> markAsClaimed(String itemId, String claimantId) async {}
}
