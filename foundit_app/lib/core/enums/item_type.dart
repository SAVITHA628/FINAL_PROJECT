enum ItemType {
  lost,
  found;

  String get label {
    switch (this) {
      case ItemType.lost: return 'Lost';
      case ItemType.found: return 'Found';
    }
  }

  String get displayName => label;
  bool get isLost => this == ItemType.lost;

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemType.lost,
    );
  }
}
