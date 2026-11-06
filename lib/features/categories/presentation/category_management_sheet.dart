import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/apple_alert.dart';
import '../../products/presentation/product_providers.dart';

// Curated icon set for categories
const List<_IconOption> _kCategoryIcons = [
  _IconOption(CupertinoIcons.square_grid_2x2_fill, 'Grid'),
  _IconOption(CupertinoIcons.bolt_fill, 'Electric'),
  _IconOption(CupertinoIcons.lightbulb_fill, 'Lighting'),
  _IconOption(CupertinoIcons.tv_fill, 'Electronics'),
  _IconOption(CupertinoIcons.phone_fill, 'Mobile'),
  _IconOption(CupertinoIcons.wifi, 'Networking'),
  _IconOption(CupertinoIcons.battery_100, 'Batteries'),
  _IconOption(CupertinoIcons.wrench_fill, 'Tools'),
  _IconOption(CupertinoIcons.house_fill, 'Home'),
  _IconOption(CupertinoIcons.cube_box_fill, 'General'),
  _IconOption(CupertinoIcons.star_fill, 'Featured'),
  _IconOption(CupertinoIcons.tag_fill, 'Offers'),
  _IconOption(CupertinoIcons.cart_fill, 'Market'),
  _IconOption(CupertinoIcons.flame_fill, 'Hot'),
  _IconOption(CupertinoIcons.antenna_radiowaves_left_right, 'Wireless'),
  _IconOption(CupertinoIcons.speaker_2_fill, 'Audio'),
];

class _IconOption {
  final IconData icon;
  final String label;
  const _IconOption(this.icon, this.label);
}

class CategoryManagementSheet extends ConsumerStatefulWidget {
  const CategoryManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryManagementSheet(),
    );
  }

  @override
  ConsumerState<CategoryManagementSheet> createState() => _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends ConsumerState<CategoryManagementSheet> {
  final TextEditingController _nameController = TextEditingController();
  IconData _selectedIcon = CupertinoIcons.cube_box_fill;
  bool _isAdding = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(catalogNotifierProvider.notifier).addCategory(name, icon: _selectedIcon);
      _nameController.clear();
      setState(() {
        _isAdding = false;
        _selectedIcon = CupertinoIcons.cube_box_fill;
      });
      if (mounted) {
        AppleAlert.showToast(
          context,
          message: 'Category "$name" added',
          icon: CupertinoIcons.plus_circle_fill,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCategory(String id, String name) async {
    final confirmed = await AppleAlert.showConfirmation(
      context: context,
      title: 'Delete Category',
      message: 'Products in "$name" will be moved to General.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(catalogNotifierProvider.notifier).deleteCategory(id);
      if (mounted) {
        AppleAlert.showToast(
          context,
          message: 'Category "$name" deleted',
          icon: CupertinoIcons.trash,
          iconColor: AppColors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).where((c) => c.id != 'all').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manage Categories', style: AppTypography.headlineSmall),
                    if (!_isAdding)
                      GestureDetector(
                        onTap: () => setState(() => _isAdding = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.plus, size: 14, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Text('Add', style: AppTypography.caption.copyWith(color: AppColors.primaryLight)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(color: AppColors.divider, height: 1),

              // Add Category Inline Form
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _isAdding
                    ? _buildAddForm()
                    : const SizedBox.shrink(),
              ),

              // Category List
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.square_grid_2x2, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No categories yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            Text('Tap Add to create your first category', style: AppTypography.caption),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const Divider(color: AppColors.divider, height: 1, indent: 58),
                        itemBuilder: (_, i) {
                          final cat = categories[i];
                          final isDeletable = cat.id != 'general';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.goldBeigeSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.icon, size: 18, color: AppColors.primaryLight),
                            ),
                            title: Text(cat.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                            subtitle: Text(
                              '${cat.productCount} item${cat.productCount == 1 ? '' : 's'}',
                              style: AppTypography.caption,
                            ),
                            trailing: isDeletable
                                ? GestureDetector(
                                    onTap: () => _deleteCategory(cat.id, cat.name),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(CupertinoIcons.trash, size: 16, color: AppColors.red),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldBeigeSubtle,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Default', style: AppTypography.caption.copyWith(color: AppColors.primaryLight)),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardElevated.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Category', style: AppTypography.titleMedium),
          const SizedBox(height: 12),

          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Category name…',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Icon picker
          Text('Choose icon', style: AppTypography.caption),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kCategoryIcons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final opt = _kCategoryIcons[i];
                final isSelected = _selectedIcon == opt.icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = opt.icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGlow : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderGold.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Tooltip(
                      message: opt.label,
                      child: Icon(
                        opt.icon,
                        size: 22,
                        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Save / Cancel
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isAdding = false;
                    _nameController.clear();
                    _selectedIcon = CupertinoIcons.cube_box_fill;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isSaving ? null : _saveCategory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const CupertinoActivityIndicator(radius: 10, color: AppColors.background)
                        : Text('Save Category', style: AppTypography.bodyMedium.copyWith(color: AppColors.background, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
