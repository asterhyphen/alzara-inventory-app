import 'package:flutter/material.dart';
import '../../../core/utils/app_icon_helper.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int productCount;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
    this.sortOrder = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? productCount,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      productCount: productCount ?? this.productCount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'productCount': productCount,
      'sortOrder': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? (map['id'] as String? ?? '');
    final name = (map['name'] as String?)?.trim() ?? 'General';
    final productCount = (map['productCount'] as num?)?.toInt() ?? 0;
    final sortOrder = (map['sortOrder'] as num?)?.toInt() ?? 0;

    final icon = AppIconHelper.fromCodePoint(
      map['iconCodePoint'] as int?,
      fallback: Icons.category_rounded,
    );

    return Category(
      id: id,
      name: name.isEmpty ? 'General' : name,
      icon: icon,
      productCount: productCount,
      sortOrder: sortOrder,
    );
  }
}
