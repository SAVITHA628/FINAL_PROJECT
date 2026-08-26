import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../../core/enums/verification_status.dart';

class ItemModel {
  final String id;
  final ItemType type;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime? dateLostOrFound;
  final String? imageUrl;
  final ItemStatus status;
  final VerificationStatus verificationStatus;
  final String reportedBy;
  final String reporterName;
  final String reporterPhone;
  final String? contactPhone;
  final String? contactWhatsApp;
  final String? claimedBy;
  final DateTime? claimedAt;
  final DateTime? returnedAt;
  final bool verifiedByAdmin;
  final String? adminNotes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.dateLostOrFound,
    this.imageUrl,
    this.status = ItemStatus.active,
    this.verificationStatus = VerificationStatus.pending,
    required this.reportedBy,
    required this.reporterName,
    required this.reporterPhone,
    this.contactPhone,
    this.contactWhatsApp,
    this.claimedBy,
    this.claimedAt,
    this.returnedAt,
    this.verifiedByAdmin = false,
    this.adminNotes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final effectiveContactPhone = contactPhone ?? reporterPhone;
    final effectiveWhatsApp = contactWhatsApp ?? effectiveContactPhone;

    return {
      'itemId': id,
      'userId': reportedBy,
      'type': type.name.toUpperCase(),
      'itemType': type.name.toUpperCase(),
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'dateLostOrFound': dateLostOrFound?.toIso8601String(),
      'imageUrl': imageUrl,
      'status': status.name.toUpperCase(),
      'itemStatus': status.name.toUpperCase(),
      'verificationStatus': verificationStatus.name.toUpperCase(),
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'contactPhone': effectiveContactPhone,
      'contactWhatsApp': effectiveWhatsApp,
      'claimedBy': claimedBy,
      'claimedAt': claimedAt?.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'verifiedByAdmin': verifiedByAdmin,
      'adminNotes': adminNotes,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory ItemModel.fromMap(String docId, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawType = (map['itemType'] ?? map['type'] ?? 'lost').toString();
    final rawStatus = (map['itemStatus'] ?? map['status'] ?? 'active').toString();
    final rawVerif = (map['verificationStatus'] ?? 'pending').toString();
    final rawUserId = (map['userId'] ?? map['reportedBy'] ?? '').toString();
    final rawReporterPhone = (map['reporterPhone'] ?? map['contactPhone'] ?? '').toString();
    final rawContactPhone = (map['contactPhone'] ?? rawReporterPhone).toString();
    final rawWhatsApp = (map['contactWhatsApp'] ?? rawContactPhone).toString();

    return ItemModel(
      id: docId,
      type: ItemType.fromString(rawType.toLowerCase()),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      dateLostOrFound: parseDate(map['dateLostOrFound']),
      imageUrl: map['imageUrl'],
      status: ItemStatus.fromString(rawStatus.toLowerCase()),
      verificationStatus: VerificationStatus.fromString(rawVerif.toLowerCase()),
      reportedBy: rawUserId,
      reporterName: map['reporterName'] ?? '',
      reporterPhone: rawReporterPhone,
      contactPhone: rawContactPhone,
      contactWhatsApp: rawWhatsApp,
      claimedBy: map['claimedBy'],
      claimedAt: parseDate(map['claimedAt']),
      returnedAt: parseDate(map['returnedAt']),
      verifiedByAdmin: map['verifiedByAdmin'] ?? false,
      adminNotes: map['adminNotes'],
      isActive: map['isActive'] ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ItemModel copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    ItemStatus? status,
    VerificationStatus? verificationStatus,
    bool? isActive,
    bool? verifiedByAdmin,
    String? adminNotes,
    String? claimedBy,
    DateTime? claimedAt,
    String? contactPhone,
    String? contactWhatsApp,
  }) {
    return ItemModel(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      dateLostOrFound: dateLostOrFound,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reportedBy: reportedBy,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWhatsApp: contactWhatsApp ?? this.contactWhatsApp,
      claimedBy: claimedBy ?? this.claimedBy,
      claimedAt: claimedAt ?? this.claimedAt,
      returnedAt: returnedAt,
      verifiedByAdmin: verifiedByAdmin ?? this.verifiedByAdmin,
      adminNotes: adminNotes ?? this.adminNotes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
