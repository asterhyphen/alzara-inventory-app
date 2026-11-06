import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final IconData? icon;
  final String categoryId;
  final String categoryName;
  final String brandId;
  final String brandName;
  final String unit;
  final double costPrice;
  final double mrp;
  final double marginPercent;
  final double sellingPrice;
  final double alZaraDiscountPercent;
  final double alZaraDiscountPrice;
  final String status; // 'live'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy; // 'admin' | 'shopkeeper'

  const Product({
    required this.id,
    required this.name,
    this.icon,
    required this.categoryId,
    required this.categoryName,
    this.brandId = '',
    this.brandName = '',
    this.unit = '',
    required this.costPrice,
    required this.mrp,
    required this.marginPercent,
    required this.sellingPrice,
    required this.alZaraDiscountPercent,
    required this.alZaraDiscountPrice,
    this.status = 'live',
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy = 'admin',
  });

  Product copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? unit,
    double? costPrice,
    double? mrp,
    double? marginPercent,
    double? sellingPrice,
    double? alZaraDiscountPercent,
    double? alZaraDiscountPrice,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      mrp: mrp ?? this.mrp,
      marginPercent: marginPercent ?? this.marginPercent,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      alZaraDiscountPercent: alZaraDiscountPercent ?? this.alZaraDiscountPercent,
      alZaraDiscountPrice: alZaraDiscountPrice ?? this.alZaraDiscountPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandId': brandId,
      'brandName': brandName,
      'unit': unit,
      'costPrice': costPrice,
      'mrp': mrp,
      'marginPercent': marginPercent,
      'sellingPrice': sellingPrice,
      'alZaraDiscountPercent': alZaraDiscountPercent,
      'alZaraDiscountPrice': alZaraDiscountPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? (map['id'] as String? ?? '');
    final name = (map['name'] as String?)?.trim() ?? 'Untitled Product';
    final categoryId = map['categoryId'] as String? ?? 'general';
    final categoryName = map['categoryName'] as String? ?? 'General';
    final brandId = map['brandId'] as String? ?? '';
    final brandName = map['brandName'] as String? ?? '';
    final unit = map['unit'] as String? ?? '';

    // Price fields strictly default to 0.0 if missing, null, or invalid in DB
    final costPrice = _parsePrice(map['costPrice']);
    final mrp = _parsePrice(map['mrp']);
    final marginPercent = _parsePrice(map['marginPercent']);
    final sellingPrice = _parsePrice(map['sellingPrice']);
    final alZaraDiscountPercent = _parsePrice(map['alZaraDiscountPercent']);
    final alZaraDiscountPrice = _parsePrice(map['alZaraDiscountPrice']);

    final status = map['status'] as String? ?? 'live';
    final createdAt = _parseDateTime(map['createdAt']);
    final updatedAt = _parseDateTime(map['updatedAt']);
    final updatedBy = map['updatedBy'] as String? ?? 'admin';

    return Product(
      id: id,
      name: name.isEmpty ? 'Untitled Product' : name,
      categoryId: categoryId,
      categoryName: categoryName,
      brandId: brandId,
      brandName: brandName,
      unit: unit,
      costPrice: costPrice,
      mrp: mrp,
      marginPercent: marginPercent,
      sellingPrice: sellingPrice,
      alZaraDiscountPercent: alZaraDiscountPercent,
      alZaraDiscountPrice: alZaraDiscountPrice,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  static double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll('₹', '').replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    try {
      if ((val as dynamic).toDate != null) {
        return (val as dynamic).toDate() as DateTime;
      }
    } catch (_) {}
    return DateTime.now();
  }

  factory Product.empty() {
    final now = DateTime.now();
    return Product(
      id: '',
      name: '',
      categoryId: 'general',
      categoryName: 'General',
      brandId: '',
      brandName: '',
      unit: '',
      costPrice: 0.0,
      mrp: 0.0,
      marginPercent: 0.0,
      sellingPrice: 0.0,
      alZaraDiscountPercent: 0.0,
      alZaraDiscountPrice: 0.0,
      status: 'live',
      createdAt: now,
      updatedAt: now,
      updatedBy: 'admin',
    );
  }
}
