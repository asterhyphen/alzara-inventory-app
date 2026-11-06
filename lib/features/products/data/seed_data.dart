import 'package:flutter/cupertino.dart';
import '../domain/product.dart';
import '../domain/category.dart';

class SeedData {
  static List<Category> get defaultCategories => [
    const Category(
      id: 'all',
      name: 'All',
      icon: CupertinoIcons.square_grid_2x2_fill,
      productCount: 0,
      sortOrder: 0,
    ),
    const Category(
      id: 'general',
      name: 'General',
      icon: CupertinoIcons.cube_box_fill,
      productCount: 0,
      sortOrder: 1,
    ),
  ];

  static List<Category> get categories => defaultCategories;

  static List<Product> get initialProducts => [];
}
