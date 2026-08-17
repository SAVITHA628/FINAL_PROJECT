import '../../core/enums/item_status.dart';
import '../../core/enums/item_type.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class MockData {
  MockData._();

  static final currentUser = UserModel(
    uid: 'user_001',
    name: 'Jash',
    email: 'jash@college.edu',
    phone: '+919876543210',
    role: 'user',
    isActive: true,
    favouriteItemIds: ['item_002', 'item_004'],
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final List<ItemModel> items = [
    ItemModel(
      id: 'item_001',
      type: ItemType.lost,
      title: 'Blue Samsung Galaxy A54',
      description:
          'Lost my blue Samsung phone near the library cafeteria. It has a transparent case with stickers on the back.',
      category: 'Electronics',
      location: 'Library Cafeteria, Block B',
      dateLostOrFound: DateTime.now().subtract(const Duration(days: 2)),
      imageUrl:
          'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.active,
      reportedBy: 'user_001',
      reporterName: 'Jash',
      reporterPhone: '+919876543210',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ItemModel(
      id: 'item_002',
      type: ItemType.found,
      title: 'College ID Card - Priya Sharma',
      description:
          'Found an ID card near the parking lot. Name on card: Priya Sharma, Roll: CSE-2024-042.',
      category: 'ID Card',
      location: 'Main Parking Lot',
      dateLostOrFound: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl:
          'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.active,
      reportedBy: 'user_002',
      reporterName: 'Rohan Kumar',
      reporterPhone: '+919876543211',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ItemModel(
      id: 'item_003',
      type: ItemType.lost,
      title: 'Silver Car Keys with Red Keychain',
      description:
          'A set of Maruti Suzuki car keys with a red rubber keychain. Last seen in the canteen area.',
      category: 'Keys',
      location: 'Central Canteen',
      dateLostOrFound: DateTime.now().subtract(const Duration(hours: 6)),
      imageUrl:
          'https://images.unsplash.com/photo-1583473848882-f9a5bc7fd2ee?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.active,
      reportedBy: 'user_003',
      reporterName: 'Anita Desai',
      reporterPhone: '+919876543212',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ItemModel(
      id: 'item_004',
      type: ItemType.found,
      title: 'Black Leather Wallet',
      description:
          'Found a black leather wallet with some cash and cards inside. Found on the football ground.',
      category: 'Wallet',
      location: 'Football Ground',
      dateLostOrFound: DateTime.now().subtract(const Duration(days: 3)),
      imageUrl:
          'https://images.unsplash.com/photo-1627123424574-724758594e93?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.claimed,
      reportedBy: 'user_004',
      reporterName: 'Vikram Singh',
      reporterPhone: '+919876543213',
      claimedBy: 'user_005',
      claimedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ItemModel(
      id: 'item_005',
      type: ItemType.lost,
      title: 'HP Laptop Charger - 65W',
      description:
          'Lost my HP laptop charger (65W, black) in Lab 204. It has a small red tape mark on the wire.',
      category: 'Electronics',
      location: 'Computer Lab 204, Block A',
      dateLostOrFound: DateTime.now().subtract(const Duration(hours: 12)),
      imageUrl:
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.active,
      reportedBy: 'user_005',
      reporterName: 'Meena Patel',
      reporterPhone: '+919876543214',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    ItemModel(
      id: 'item_006',
      type: ItemType.found,
      title: 'Blue Backpack - Wildcraft',
      description:
          'Found a blue Wildcraft backpack near the auditorium entrance. Contains some notebooks.',
      category: 'Bag',
      location: 'Auditorium Entrance',
      dateLostOrFound: DateTime.now().subtract(const Duration(days: 5)),
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500&auto=format&fit=crop&q=80',
      status: ItemStatus.returned,
      reportedBy: 'user_002',
      reporterName: 'Rohan Kumar',
      reporterPhone: '+919876543211',
      verifiedByAdmin: true,
      returnedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'notif_001',
      recipientId: 'user_001',
      title: 'Item Claimed',
      body: 'Someone has claimed your "Blue Samsung Galaxy A54".',
      type: 'status_update',
      itemId: 'item_001',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'notif_002',
      recipientId: 'user_001',
      title: 'Item Returned',
      body: 'Your favourite item "Blue Backpack" was returned to its owner.',
      type: 'status_update',
      itemId: 'item_006',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
