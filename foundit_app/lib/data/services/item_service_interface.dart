import '../models/item_model.dart';
import '../../core/enums/item_type.dart';

abstract class ItemServiceInterface {
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter});
  Future<ItemModel?> getItemById(String id);
  Future<List<ItemModel>> searchItems(String query);
  Future<List<ItemModel>> getUserItems(String userId);
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds);
  Future<ItemModel> addItem(ItemModel item);
  Future<ItemModel> updateItem(ItemModel item);
  Future<void> deleteItem(String id);
  Future<void> markAsClaimed(String itemId, String claimantId);
}
