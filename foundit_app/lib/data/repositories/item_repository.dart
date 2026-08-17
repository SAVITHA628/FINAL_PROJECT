import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../services/item_service_interface.dart';
import '../services/mock_item_service.dart';

class ItemRepository {
  final ItemServiceInterface _service;

  ItemRepository({ItemServiceInterface? service})
      : _service = service ?? MockItemService();

  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) =>
      _service.getActiveItems(typeFilter: typeFilter);

  Future<ItemModel?> getItemById(String id) => _service.getItemById(id);

  Future<List<ItemModel>> searchItems(String query) =>
      _service.searchItems(query);

  Future<List<ItemModel>> getUserItems(String userId) =>
      _service.getUserItems(userId);

  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) =>
      _service.getFavouriteItems(favouriteIds);

  Future<ItemModel> addItem(ItemModel item) => _service.addItem(item);

  Future<ItemModel> updateItem(ItemModel item) => _service.updateItem(item);

  Future<void> deleteItem(String id) => _service.deleteItem(id);

  Future<void> markAsClaimed(String itemId, String claimantId) =>
      _service.markAsClaimed(itemId, claimantId);
}
