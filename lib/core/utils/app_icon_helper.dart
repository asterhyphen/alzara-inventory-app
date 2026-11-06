import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized registry for all icons used dynamically (in Supabase, Categories, Activity Logs).
/// All icons are compile-time constants so Flutter's icon font tree shaker works flawlessly for release & web builds.
class AppIconHelper {
  static const List<IconData> _registeredIcons = [
    CupertinoIcons.square_grid_2x2_fill,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.lightbulb_fill,
    CupertinoIcons.tv_fill,
    CupertinoIcons.phone_fill,
    CupertinoIcons.wifi,
    CupertinoIcons.battery_100,
    CupertinoIcons.wrench_fill,
    CupertinoIcons.house_fill,
    CupertinoIcons.cube_box_fill,
    CupertinoIcons.star_fill,
    CupertinoIcons.tag_fill,
    CupertinoIcons.cart_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.antenna_radiowaves_left_right,
    CupertinoIcons.speaker_2_fill,
    CupertinoIcons.pencil,
    CupertinoIcons.checkmark_seal_fill,
    CupertinoIcons.xmark_seal_fill,
    CupertinoIcons.clock_fill,
    CupertinoIcons.checkmark_alt_circle_fill,
    CupertinoIcons.xmark_circle_fill,
    CupertinoIcons.info_circle_fill,
    CupertinoIcons.lock_fill,
    CupertinoIcons.gear_solid,
    Icons.category_rounded,
    Icons.info_outline,
    Icons.shopping_bag_outlined,
    Icons.shield_outlined,
  ];

  static final Map<int, IconData> _map = {
    for (final icon in _registeredIcons) icon.codePoint: icon,
  };

  static IconData fromCodePoint(int? codePoint, {IconData fallback = CupertinoIcons.cube_box_fill}) {
    if (codePoint == null) return fallback;
    return _map[codePoint] ?? fallback;
  }
}
