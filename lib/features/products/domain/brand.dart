class Brand {
  final String id;
  final String name;
  final String categoryId;
  final int sortOrder;

  const Brand({
    required this.id,
    required this.name,
    required this.categoryId,
    this.sortOrder = 0,
  });

  Brand copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? sortOrder,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'sortOrder': sortOrder,
  };

  factory Brand.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Brand(
      id: docId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? 'general',
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}
