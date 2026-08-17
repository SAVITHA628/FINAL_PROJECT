import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../mock/mock_data.dart';
import '../models/item_model.dart';
import 'item_service_interface.dart';

class MockItemService implements ItemServiceInterface {
  final List<ItemModel> _items = List.from(MockData.items);

  @override
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _items.where((item) {
      final matchesActive = item.isActive && item.status == ItemStatus.active;
      final matchesType = typeFilter == null || item.type == typeFilter;
      return matchesActive && matchesType;
    }).toList();
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ItemModel>> searchItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return _items.where((i) {
      return i.isActive &&
          (i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.location.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Future<List<ItemModel>> getUserItems(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.where((i) => i.reportedBy == userId && i.isActive).toList();
  }

  @override
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.where((i) => favouriteIds.contains(i.id) && i.isActive).toList();
  }

  @override
  Future<ItemModel> addItem(ItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newItem = ItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      type: item.type,
      title: item.title,
      description: item.description,
      category: item.category,
      location: item.location,
      dateLostOrFound: item.dateLostOrFound ?? DateTime.now(),
      imageUrl: item.imageUrl,
      status: ItemStatus.active,
      reportedBy: item.reportedBy,
      reporterName: item.reporterName,
      reporterPhone: item.reporterPhone,
      createdAt: DateTime.now(),
    );
    _items.insert(0, newItem);
    return newItem;
  }

  @override
  Future<ItemModel> updateItem(ItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      return item;
    }
    throw Exception('Item not found');
  }

  @override
  Future<void> deleteItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isActive: false);
    }
  }

  @override
  Future<void> markAsClaimed(String itemId, String claimantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(status: ItemStatus.claimed);
    }
  }
}
