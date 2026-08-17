import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'item_service_interface.dart';

class FirestoreService implements ItemServiceInterface {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items => _db.collection('items');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // User management
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleUserFavourite(String userId, String itemId) async {
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
  }

  // Item management
  @override
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    Query<Map<String, dynamic>> query = _items
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: ItemStatus.active.name)
        .orderBy('createdAt', descending: true);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter.name);
    }

    final snap = await query.get();
    return snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    final doc = await _items.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ItemModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<List<ItemModel>> searchItems(String queryText) async {
    final q = queryText.trim().toLowerCase();
    if (q.isEmpty) return [];

    final snap = await _items
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map((d) => ItemModel.fromMap(d.id, d.data()))
        .where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.location.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<ItemModel>> getUserItems(String userId) async {
    final snap = await _items
        .where('reportedBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    if (favouriteIds.isEmpty) return [];
    final List<ItemModel> result = [];
    
    // Chunk requests into batches of 10 for Firestore 'whereIn' limits
    for (var i = 0; i < favouriteIds.length; i += 10) {
      final end = (i + 10 < favouriteIds.length) ? i + 10 : favouriteIds.length;
      final batch = favouriteIds.sublist(i, end);
      final snap = await _items
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      result.addAll(snap.docs.map((d) => ItemModel.fromMap(d.id, d.data())));
    }
    return result;
  }

  @override
  Future<ItemModel> addItem(ItemModel item) async {
    final docRef = await _items.add(item.toMap());
    return ItemModel.fromMap(docRef.id, item.toMap());
  }

  @override
  Future<ItemModel> updateItem(ItemModel item) async {
    await _items.doc(item.id).update(item.toMap());
    return item;
  }

  @override
  Future<void> deleteItem(String id) async {
    await _items.doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAsClaimed(String itemId, String claimantId) async {
    await _items.doc(itemId).update({
      'status': ItemStatus.claimed.name,
      'claimedBy': claimantId,
      'claimedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
