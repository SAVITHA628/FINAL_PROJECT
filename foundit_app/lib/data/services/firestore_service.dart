import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'item_service_interface.dart';
import 'mock_item_service.dart';

class FirestoreService implements ItemServiceInterface {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MockItemService _mockService = MockItemService();

  CollectionReference<Map<String, dynamic>> get _items => _db.collection('items');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // User management
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> toggleUserFavourite(String userId, String itemId) async {
    try {
      final userRef = _users.doc(userId);
      final doc = await userRef.get();
      if (!doc.exists) return;

      final currentFavs = List<String>.from(doc.data()?['favouriteItemIds'] ?? []);
      if (currentFavs.contains(itemId)) {
        await userRef.update({
          'favouriteItemIds': FieldValue.arrayRemove([itemId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'favouriteItemIds': FieldValue.arrayUnion([itemId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  // Item management
  @override
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    try {
      final timeoutPromise = Future.delayed(const Duration(milliseconds: 1200));
      Query<Map<String, dynamic>> query = _items.where('isActive', isEqualTo: true);

      final fetchFuture = query.get();
      final result = await Future.any([fetchFuture, timeoutPromise]);

      if (result is QuerySnapshot<Map<String, dynamic>> && result.docs.isNotEmpty) {
        var items = result.docs.map((d) => ItemModel.fromMap(d.id, d.data())).toList();

        if (typeFilter != null) {
          items = items.where((i) => i.type == typeFilter).toList();
        }

        return items;
      }
    } catch (e) {
      // Fallback if index missing or Firestore error
    }

    return _mockService.getActiveItems(typeFilter: typeFilter);
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    try {
      final doc = await _items.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ItemModel.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}
    return _mockService.getItemById(id);
  }

  @override
  Future<List<ItemModel>> searchItems(String queryText) async {
    final q = queryText.trim().toLowerCase();
    if (q.isEmpty) return [];

    try {
      final snap = await _items.get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())).toList();
        return items.where((item) {
          return item.title.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.location.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q);
        }).toList();
      }
    } catch (_) {}

    return _mockService.searchItems(queryText);
  }

  @override
  Future<List<ItemModel>> getUserItems(String userId) async {
    try {
      final snap = await _items.where('reportedBy', isEqualTo: userId).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())).toList();
      }
    } catch (_) {}

    return _mockService.getUserItems(userId);
  }

  @override
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    if (favouriteIds.isEmpty) return [];
    try {
      final List<ItemModel> result = [];
      for (var i = 0; i < favouriteIds.length; i += 10) {
        final end = (i + 10 < favouriteIds.length) ? i + 10 : favouriteIds.length;
        final batch = favouriteIds.sublist(i, end);
        final snap = await _items.where(FieldPath.documentId, whereIn: batch).get();
        result.addAll(snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())));
      }
      if (result.isNotEmpty) return result;
    } catch (_) {}

    return _mockService.getFavouriteItems(favouriteIds);
  }

  @override
  Future<ItemModel> addItem(ItemModel item) async {
    try {
      final docRef = await _items.add(item.toMap());
      return ItemModel.fromMap(docRef.id, item.toMap());
    } catch (_) {
      return _mockService.addItem(item);
    }
  }

  @override
  Future<ItemModel> updateItem(ItemModel item) async {
    try {
      await _items.doc(item.id).update(item.toMap());
      return item;
    } catch (_) {
      return _mockService.updateItem(item);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _items.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _mockService.deleteItem(id);
    }
  }

  @override
  Future<void> markAsClaimed(String itemId, String claimantId) async {
    try {
      await _items.doc(itemId).update({
        'status': ItemStatus.claimed.name,
        'itemStatus': 'CLAIMED',
        'claimedBy': claimantId,
        'claimedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _mockService.markAsClaimed(itemId, claimantId);
    }
  }
}
