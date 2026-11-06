enum UserRole {
  admin,
  shopkeeper;

  String get displayName => this == UserRole.admin ? 'Admin' : 'Shopkeeper';
  bool get isAdmin => this == UserRole.admin;
  bool get isShopkeeper => this == UserRole.shopkeeper;
}
