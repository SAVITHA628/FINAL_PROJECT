enum ItemStatus {
  active,
  claimed,
  returned,
  closed,
  expired,
  disputed;

  String get label {
    switch (this) {
      case ItemStatus.active:
        return 'Active';
      case ItemStatus.claimed:
        return 'Claimed';
      case ItemStatus.returned:
        return 'Returned';
      case ItemStatus.closed:
        return 'Closed';
      case ItemStatus.expired:
        return 'Expired';
      case ItemStatus.disputed:
        return 'Disputed';
    }
  }

  String get displayName => label;

  static ItemStatus fromString(String value) {
    return ItemStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ItemStatus.active,
    );
  }
}
