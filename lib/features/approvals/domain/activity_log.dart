import 'package:flutter/material.dart';
import '../../../core/utils/app_icon_helper.dart';

class ActivityLog {
  final String id;
  final String title;
  final String description;
  final String actorRole; // 'admin' | 'shopkeeper'
  final String type; // 'price_change', 'approved', 'rejected', etc.
  final IconData icon;
  final Color iconColor;
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.actorRole,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
  });

  ActivityLog copyWith({
    String? id,
    String? title,
    String? description,
    String? actorRole,
    String? type,
    IconData? icon,
    Color? iconColor,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      actorRole: actorRole ?? this.actorRole,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actorRole': actorRole,
      'type': type,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconColor': iconColor.toARGB32(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? (map['id'] as String? ?? '');
    final icon = AppIconHelper.fromCodePoint(
      map['iconCodePoint'] as int?,
      fallback: Icons.info_outline,
    );
    final iconColor = map['iconColor'] != null ? Color(map['iconColor'] as int) : const Color(0xFFDEBA7E);

    DateTime timestamp = DateTime.now();
    final ts = map['timestamp'];
    if (ts is String) {
      timestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else if (ts != null) {
      try {
        if ((ts as dynamic).toDate != null) {
          timestamp = (ts as dynamic).toDate() as DateTime;
        }
      } catch (_) {}
    }

    return ActivityLog(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? 'admin',
      type: map['type'] as String? ?? 'general',
      icon: icon,
      iconColor: iconColor,
      timestamp: timestamp,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
