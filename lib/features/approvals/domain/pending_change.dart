import 'package:flutter/material.dart';
import '../../products/domain/product.dart';

class FieldDiff {
  final String fieldName;
  final String label;
  final dynamic oldValue;
  final dynamic newValue;
  final String formatType; // 'currency', 'percent', 'number', 'text'

  const FieldDiff({
    required this.fieldName,
    required this.label,
    required this.oldValue,
    required this.newValue,
    this.formatType = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'label': label,
      'oldValue': oldValue,
      'newValue': newValue,
      'formatType': formatType,
    };
  }

  factory FieldDiff.fromMap(Map<String, dynamic> map) {
    return FieldDiff(
      fieldName: map['fieldName'] as String? ?? '',
      label: map['label'] as String? ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      formatType: map['formatType'] as String? ?? 'text',
    );
  }
}

class PendingChange {
  final String id;
  final String? productId;
  final String productName;
  final String categoryName;
  final IconData? productIcon;
  final String type; // 'new_product' | 'edit'
  final List<FieldDiff> diffs;
  final Product proposedProduct;
  final String submittedBy; // 'shopkeeper'
  final DateTime submittedAt;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewedBy; // 'admin'
  final DateTime? reviewedAt;
  final String? rejectReason;

  const PendingChange({
    required this.id,
    this.productId,
    required this.productName,
    required this.categoryName,
    this.productIcon,
    required this.type,
    required this.diffs,
    required this.proposedProduct,
    this.submittedBy = 'shopkeeper',
    required this.submittedAt,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  PendingChange copyWith({
    String? id,
    String? productId,
    String? productName,
    String? categoryName,
    IconData? productIcon,
    String? type,
    List<FieldDiff>? diffs,
    Product? proposedProduct,
    String? submittedBy,
    DateTime? submittedAt,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectReason,
  }) {
    return PendingChange(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      productIcon: productIcon ?? this.productIcon,
      type: type ?? this.type,
      diffs: diffs ?? this.diffs,
      proposedProduct: proposedProduct ?? this.proposedProduct,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'type': type,
      'diffs': diffs.map((d) => d.toMap()).toList(),
      'proposedProduct': proposedProduct.toMap(),
      'submittedBy': submittedBy,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectReason': rejectReason,
    };
  }

  factory PendingChange.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? (map['id'] as String? ?? '');
    final diffsList = (map['diffs'] as List<dynamic>?)
            ?.map((d) => FieldDiff.fromMap(Map<String, dynamic>.from(d as Map)))
            .toList() ??
        [];

    final propMap = map['proposedProduct'] != null
        ? Map<String, dynamic>.from(map['proposedProduct'] as Map)
        : <String, dynamic>{};
    final proposedProduct = Product.fromMap(propMap, map['productId'] as String?);

    return PendingChange(
      id: id,
      productId: map['productId'] as String?,
      productName: map['productName'] as String? ?? 'Product',
      categoryName: map['categoryName'] as String? ?? 'General',
      type: map['type'] as String? ?? 'edit',
      diffs: diffsList,
      proposedProduct: proposedProduct,
      submittedBy: map['submittedBy'] as String? ?? 'shopkeeper',
      submittedAt: _parseDateTime(map['submittedAt']),
      status: map['status'] as String? ?? 'pending',
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] != null ? _parseDateTime(map['reviewedAt']) : null,
      rejectReason: map['rejectReason'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    try {
      if ((val as dynamic).toDate != null) {
        return (val as dynamic).toDate() as DateTime;
      }
    } catch (_) {}
    return DateTime.now();
  }
}
