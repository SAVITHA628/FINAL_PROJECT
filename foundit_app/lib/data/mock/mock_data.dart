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
    favouriteItemIds: [],
    createdAt: DateTime.now(),
  );

  // Pure empty real-time data - zero demo items
  static final List<ItemModel> items = [];

  static final List<NotificationModel> notifications = [];
}
