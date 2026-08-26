import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../../core/enums/verification_status.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'item_service_interface.dart';

class FirestoreService implements ItemServiceInterface {
  static const String projectId = 'foundit-6bc8a';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // ── Helper to parse Firestore REST field format ──────────────────────
  String _parseString(Map<String, dynamic>? field) {
    if (field == null) return '';
    return field['stringValue'] ?? field['integerValue']?.toString() ?? '';
  }

  bool _parseBool(Map<String, dynamic>? field) {
    if (field == null) return false;
    return field['booleanValue'] ?? false;
  }

  DateTime? _parseDate(Map<String, dynamic>? field) {
    if (field == null) return null;
    final val = field['timestampValue'] ?? field['stringValue'];
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  ItemModel _docToItemModel(Map<String, dynamic> docJson) {
    final namePath = docJson['name'] as String? ?? '';
    final id = namePath.split('/').last;
    final fields = (docJson['fields'] as Map<String, dynamic>?) ?? {};

    final rawType = _parseString(fields['type']).isEmpty
        ? _parseString(fields['itemType'])
        : _parseString(fields['type']);
    final rawStatus = _parseString(fields['status']).isEmpty
        ? _parseString(fields['itemStatus'])
        : _parseString(fields['status']);
    final rawVerif = _parseString(fields['verificationStatus']);

    return ItemModel(
      id: id,
      type: ItemType.fromString(rawType.toLowerCase()),
      title: _parseString(fields['title']),
      description: _parseString(fields['description']),
      category: _parseString(fields['category']),
      location: _parseString(fields['location']),
      dateLostOrFound: _parseDate(fields['dateLostOrFound']),
      imageUrl: _parseString(fields['imageUrl']).isEmpty
          ? null
          : _parseString(fields['imageUrl']),
      status: ItemStatus.fromString(rawStatus.toLowerCase()),
      verificationStatus: VerificationStatus.fromString(rawVerif.toLowerCase()),
      reportedBy: _parseString(fields['reportedBy']).isEmpty
          ? _parseString(fields['userId'])
          : _parseString(fields['reportedBy']),
      reporterName: _parseString(fields['reporterName']),
      reporterPhone: _parseString(fields['reporterPhone']),
      claimedBy: _parseString(fields['claimedBy']).isEmpty
          ? null
          : _parseString(fields['claimedBy']),
      claimedAt: _parseDate(fields['claimedAt']),
      returnedAt: _parseDate(fields['returnedAt']),
      verifiedByAdmin: _parseBool(fields['verifiedByAdmin']),
      adminNotes: _parseString(fields['adminNotes']).isEmpty
          ? null
          : _parseString(fields['adminNotes']),
      isActive: fields['isActive'] != null ? _parseBool(fields['isActive']) : true,
      createdAt: _parseDate(fields['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(fields['updatedAt']),
    );
  }

  // ── Item Service Interface Implementation ────────────────────────────
  @override
  Future<List<ItemModel>> getActiveItems({ItemType? typeFilter}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/items'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = (data['documents'] as List<dynamic>?) ?? [];
        final items = docs
            .map((d) => _docToItemModel(d as Map<String, dynamic>))
            .where((i) => i.isActive)
            .toList();

        if (typeFilter != null) {
          return items.where((i) => i.type == typeFilter).toList();
        }
        return items;
      }
    } catch (e) {
      // Fallback handled safely by Repository
    }
    return [];
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/items/$id'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return _docToItemModel(data);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<ItemModel>> searchItems(String queryText) async {
    final all = await getActiveItems();
    final q = queryText.toLowerCase().trim();
    if (q.isEmpty) return [];

    return all.where((i) {
      return i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<ItemModel>> getUserItems(String userId) async {
    final all = await getActiveItems();
    return all.where((i) => i.reportedBy == userId).toList();
  }

  @override
  Future<List<ItemModel>> getFavouriteItems(List<String> favouriteIds) async {
    final all = await getActiveItems();
    return all.where((i) => favouriteIds.contains(i.id)).toList();
  }

  @override
  Future<ItemModel> addItem(ItemModel item) async {
    final payload = {
      'fields': {
        'title': {'stringValue': item.title},
        'description': {'stringValue': item.description},
        'category': {'stringValue': item.category},
        'location': {'stringValue': item.location},
        'type': {'stringValue': item.type.name.toUpperCase()},
        'status': {'stringValue': item.status.name.toUpperCase()},
        'verificationStatus': {'stringValue': item.verificationStatus.name.toUpperCase()},
        'reportedBy': {'stringValue': item.reportedBy},
        'reporterName': {'stringValue': item.reporterName},
        'reporterPhone': {'stringValue': item.reporterPhone},
        'imageUrl': {'stringValue': item.imageUrl ?? ''},
        'isActive': {'booleanValue': true},
        'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      }
    };

    final res = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return _docToItemModel(data);
    } else {
      final err = jsonDecode(res.body);
      final errMsg = err['error']?['message'] ?? 'Firestore HTTP error (${res.statusCode})';
      throw Exception(errMsg);
    }
  }

  @override
  Future<ItemModel> updateItem(ItemModel item) async {
    final payload = {
      'fields': {
        'title': {'stringValue': item.title},
        'description': {'stringValue': item.description},
        'category': {'stringValue': item.category},
        'location': {'stringValue': item.location},
        'type': {'stringValue': item.type.name.toUpperCase()},
        'status': {'stringValue': item.status.name.toUpperCase()},
        'verificationStatus': {'stringValue': item.verificationStatus.name.toUpperCase()},
        'verifiedByAdmin': {'booleanValue': item.verifiedByAdmin},
        'reportedBy': {'stringValue': item.reportedBy},
        'reporterName': {'stringValue': item.reporterName},
        'reporterPhone': {'stringValue': item.reporterPhone},
        'imageUrl': {'stringValue': item.imageUrl ?? ''},
        'isActive': {'booleanValue': item.isActive},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      }
    };

    try {
      await http.patch(
        Uri.parse('$baseUrl/items/${item.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {}
    return item;
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/items/$id'));
    } catch (_) {}
  }

  @override
  Future<void> markAsClaimed(String itemId, String claimantId) async {
    final item = await getItemById(itemId);
    if (item != null) {
      await updateItem(item.copyWith(
        status: ItemStatus.claimed,
        claimedBy: claimantId,
        claimedAt: DateTime.now(),
      ));
    }
  }
}
