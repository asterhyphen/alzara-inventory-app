import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/product.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../product_providers.dart';
import '../../../pricing/domain/pricing_calculator.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/widgets/al_zara_pill.dart';
import '../../../../core/widgets/apple_alert.dart';

class QuickPriceEditSheet extends ConsumerStatefulWidget {
  final Product product;

  const QuickPriceEditSheet({
    super.key,
    required this.product,
  });

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickPriceEditSheet(product: product),
    );
  }

  @override
  ConsumerState<QuickPriceEditSheet> createState() => _QuickPriceEditSheetState();
}

class _QuickPriceEditSheetState extends ConsumerState<QuickPriceEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _mrpController;
  late TextEditingController _marginPercentController;
  late TextEditingController _alZaraDiscountController;

  late double _marginPercent;
  late double _alZaraDiscountPercent;
  late double _costPrice;
  late double _mrp;
  late String _selectedCategoryId;
  late String _selectedBrandId;
  late String _selectedBrandName;

  @override
  void initState() {
    super.initState();
    _costPrice = widget.product.costPrice;
    _mrp = widget.product.mrp;
    _marginPercent = widget.product.marginPercent;
    _alZaraDiscountPercent = widget.product.alZaraDiscountPercent;
    _selectedCategoryId = widget.product.categoryId;
    _selectedBrandId = widget.product.brandId;
    _selectedBrandName = widget.product.brandName;

    _nameController = TextEditingController(text: widget.product.name);
    _costPriceController = TextEditingController(text: _costPrice.toStringAsFixed(0));
    _mrpController = TextEditingController(text: _mrp.toStringAsFixed(0));
    _marginPercentController = TextEditingController(text: _marginPercent.toStringAsFixed(0));
    _alZaraDiscountController = TextEditingController(text: _alZaraDiscountPercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _mrpController.dispose();
    _marginPercentController.dispose();
    _alZaraDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final categories = ref.watch(categoriesProvider).where((c) => c.id != 'all').toList();

    // Ensure category selection is valid
    if (categories.isNotEmpty && !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.first.id;
    }

    final calcResult = PricingCalculator.calculate(
      costPrice: _costPrice,
      mrp: _mrp,
      marginPercent: _marginPercent,
      alZaraDiscountPercent: _alZaraDiscountPercent,
      settings: settings,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      decoration: const BoxDecoration(
        color: AppColors.modalSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGold, width: 1.5)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Bar
            Row(
              children: [
                Expanded(
                  child: Text('Edit Product & Pricing', style: AppTypography.headlineSmall),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(CupertinoIcons.xmark, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Editable Product Name
            Text('Product Name', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Product Name',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text('CATEGORY', style: AppTypography.caption.copyWith(letterSpacing: 1.2, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AlZaraPill(
                      label: cat.name,
                      icon: cat.icon,
                      isSelected: _selectedCategoryId == cat.id,
                      onTap: () => setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedBrandId = '';
                        _selectedBrandName = '';
                      }),
                      variant: PillVariant.gold,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Brand / Subcategory Selector
            if (_selectedCategoryId.isNotEmpty) ..._buildBrandPicker(context, ref),
            const SizedBox(height: 20),

            // 2. 3-Tier Price Ladder Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriceColumn('MRP', _mrp, AppColors.textMuted),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  _buildPriceColumn('Selling Price', calcResult.sellingPrice, AppColors.primaryLight, isBold: true),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  _buildPriceColumn('AZ Trade', calcResult.alZaraDiscountPrice, AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Editable Base Prices: Cost Price & MRP
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cost Price (CP)', style: AppTypography.titleMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0;
                          setState(() => _costPrice = parsed);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MRP', style: AppTypography.titleMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _mrpController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0;
                          setState(() => _mrp = parsed);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Margin % Textbox
            Text('Profit Margin % (for SP)', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _marginPercentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                suffixText: '%',
                hintText: 'e.g. 20',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0;
                setState(() => _marginPercent = parsed);
              },
            ),
            if (calcResult.exceedsMrp) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 14, color: AppColors.red),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Warning: Selling price exceeds MRP!',
                        style: TextStyle(color: AppColors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // 5. Al Zara Discount % Textbox
            Text('Al Zara Discount %', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _alZaraDiscountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                suffixText: '%',
                hintText: 'e.g. 10',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0;
                setState(() => _alZaraDiscountPercent = parsed);
              },
            ),
            const SizedBox(height: 28),

            // Save / Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    AppleAlert.showToast(
                      context,
                      message: 'Product name is required',
                      icon: CupertinoIcons.exclamationmark_circle_fill,
                      iconColor: AppColors.red,
                    );
                    return;
                  }

                  final nav = Navigator.of(context);
                  final cats = ref.read(categoriesProvider);
                  final cat = cats.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => cats.first);

                  final updated = widget.product.copyWith(
                    name: name,
                    categoryId: _selectedCategoryId,
                    categoryName: cat.name,
                    icon: cat.icon,
                    brandId: _selectedBrandId,
                    brandName: _selectedBrandName,
                    costPrice: _costPrice,
                    mrp: _mrp,
                    marginPercent: _marginPercent,
                    sellingPrice: calcResult.sellingPrice,
                    alZaraDiscountPercent: _alZaraDiscountPercent,
                    alZaraDiscountPrice: calcResult.alZaraDiscountPrice,
                  );

                  await ref.read(catalogNotifierProvider.notifier).saveProduct(
                        product: updated,
                        role: authState.role,
                      );

                  if (!mounted) return;
                  nav.pop();
                  AppleAlert.showToast(
                    nav.context,
                    message: authState.role.isAdmin
                        ? 'Product details updated successfully'
                        : 'Changes sent for Admin approval',
                    icon: CupertinoIcons.checkmark_circle_fill,
                  );
                },
                child: Text(
                  authState.role.isAdmin ? 'Save Product & Prices' : 'Submit for Admin Approval',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Delete Product Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.red.withValues(alpha: 0.06),
                ),
                icon: const Icon(CupertinoIcons.trash, size: 16),
                label: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onPressed: () async {
                  final confirmed = await AppleAlert.showConfirmation(
                    context: context,
                    title: 'Delete Product',
                    message: 'Are you sure you want to permanently delete "${widget.product.name}"?',
                    confirmText: 'Delete',
                    isDestructive: true,
                  );

                  if (confirmed == true && context.mounted) {
                    final nav = Navigator.of(context);
                    await ref.read(catalogNotifierProvider.notifier).deleteProduct(widget.product.id);
                    if (mounted) {
                      nav.pop();
                      AppleAlert.showToast(
                        nav.context,
                        message: 'Product deleted from catalog',
                        icon: CupertinoIcons.trash,
                        iconColor: AppColors.red,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBrandPicker(BuildContext context, WidgetRef ref) {
    final allBrands = ref.watch(brandsProvider);
    final brands = allBrands.where((b) => b.categoryId == _selectedCategoryId).toList();

    return [
      Text(
        'BRAND / SUBCATEGORY',
        style: AppTypography.caption.copyWith(
          letterSpacing: 1.2,
          color: AppColors.textMuted,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...brands.map((b) => _SheetBrandChip(
                label: b.name,
                isSelected: _selectedBrandId == b.id,
                onTap: () => setState(() {
                  if (_selectedBrandId == b.id) {
                    _selectedBrandId = '';
                    _selectedBrandName = '';
                  } else {
                    _selectedBrandId = b.id;
                    _selectedBrandName = b.name;
                  }
                }),
                onDelete: () async {
                  final confirm = await AppleAlert.showConfirmation(
                    context: context,
                    title: 'Delete Brand',
                    message: 'Are you sure you want to delete "${b.name}"?',
                    confirmText: 'Delete',
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    await ref.read(brandsProvider.notifier).deleteBrand(b.id);
                    if (_selectedBrandId == b.id && mounted) {
                      setState(() {
                        _selectedBrandId = '';
                        _selectedBrandName = '';
                      });
                    }
                    if (context.mounted) {
                      AppleAlert.showToast(
                        context,
                        message: 'Brand "${b.name}" deleted',
                        icon: CupertinoIcons.trash,
                        iconColor: AppColors.red,
                      );
                    }
                  }
                },
              )),
          _SheetBrandChip(
            label: '+ Add Brand',
            isSelected: false,
            isAdd: true,
            onTap: () => _showAddBrandDialog(context, ref),
          ),
        ],
      ),
    ];
  }

  void _showAddBrandDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Brand', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'e.g. Asian Paints',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final brand = await ref.read(brandsProvider.notifier).addBrand(name, _selectedCategoryId);
              if (mounted) {
                setState(() {
                  _selectedBrandId = brand.id;
                  _selectedBrandName = brand.name;
                });
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppleAlert.showToast(
                  ctx,
                  message: 'Brand "$name" created',
                  icon: CupertinoIcons.checkmark_circle_fill,
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(String title, double price, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(title, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        AnimatedPriceText(
          value: price,
          prefix: '₹',
          style: AppTypography.priceMedium(color: color).copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SheetBrandChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAdd;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SheetBrandChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAdd = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isAdd ? AppColors.goldBeigeSubtle : AppColors.cardElevated),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderGold.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : (isAdd ? AppColors.primary : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (onDelete != null && !isAdd) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black26 : AppColors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 10,
                    color: isSelected ? Colors.black87 : AppColors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
