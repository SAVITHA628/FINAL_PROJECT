class AppStrings {
  AppStrings._();

  static const appName = 'FoundIt';
  static const tagline = 'Lost & Found Smart App';

  // Tabs
  static const home = 'Home';
  static const search = 'Search';
  static const report = 'Report';
  static const saved = 'Saved';
  static const profile = 'Profile';

  // Item types
  static const lost = 'Lost';
  static const found = 'Found';
  static const all = 'All';

  // Categories
  static const List<String> categories = [
    'Electronics',
    'ID Card',
    'Keys',
    'Wallet',
    'Bag',
    'Clothing',
    'Books',
    'Jewellery',
    'Other',
  ];

  // Empty states
  static const noItems = 'No items found';
  static const noFavourites = 'No saved items yet';
  static const noNotifications = 'No notifications';

  // Error messages
  static const genericError = 'Something went wrong. Please try again.';
  static const networkError = 'No internet connection.';
}
