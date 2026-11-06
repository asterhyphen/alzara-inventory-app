import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/al_zara_pill.dart';
import '../../../core/widgets/animated_price_text.dart';
import '../domain/product.dart';
import 'product_providers.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/widgets/apple_alert.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../pricing/domain/pricing_calculator.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product; // null = new product

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _nameController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _marginPercentController = TextEditingController();
  final _alZaraDiscountController = TextEditingController();

  String _selectedCategoryId = 'general';
  String _selectedBrandId = '';
  String _selectedBrandName = '';
  double _marginPercent = 20.0;
  double _alZaraDiscountPercent = 10.0;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _costPriceController.text = p.costPrice.toStringAsFixed(0);
      _mrpController.text = p.mrp.toStringAsFixed(0);
      _selectedCategoryId = p.categoryId;
      _selectedBrandId = p.brandId;
      _selectedBrandName = p.brandName;
      _marginPercent = p.marginPercent;
      _alZaraDiscountPercent = p.alZaraDiscountPercent;
      _marginPercentController.text = p.marginPercent.toStringAsFixed(0);
      _alZaraDiscountController.text = p.alZaraDiscountPercent.toStringAsFixed(0);
    } else {
      _marginPercentController.text = '20';
      _alZaraDiscountController.text = '10';
    }
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

  double get _costPrice => double.tryParse(_costPriceController.text) ?? 0;
  double get _mrp => double.tryParse(_mrpController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final categories = ref.watch(categoriesProvider).where((c) => c.id != 'all').toList();

    // Ensure valid default category selection if not set
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isEditing ? 'Edit Product & Pricing' : 'Add New Product',
          style: AppTypography.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PRODUCT INFO ───
            Text(
              'PRODUCT INFORMATION',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            // Name
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Premium Emulsion 4L'),
            ),
            const SizedBox(height: 16),

            // Category Pills
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

            // ─── BRAND / SUBCATEGORY PICKER ───
            if (_selectedCategoryId.isNotEmpty) ..._buildBrandPicker(context, ref),

            const SizedBox(height: 24),

            // ─── PRICING ───
            Text(
              'PRICING CONFIGURATION',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Cost Price (₹)', prefixText: '₹ '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _mrpController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'MRP (₹)', prefixText: '₹ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profit Margin % Textbox
            TextField(
              controller: _marginPercentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Profit Margin % (to calculate Selling Price)',
                suffixText: '%',
                hintText: 'e.g. 20',
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() => _marginPercent = parsed);
              },
            ),

            // Live SP readout
            if (_costPrice > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Computed Selling Price:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    AnimatedPriceText(
                      value: calcResult.sellingPrice,
                      prefix: '₹',
                      style: AppTypography.priceMedium(
                        color: calcResult.exceedsMrp ? AppColors.red : AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (calcResult.exceedsMrp) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 14, color: AppColors.red),
                      SizedBox(width: 6),
                      Text('Selling price exceeds MRP', style: TextStyle(color: AppColors.red, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Al Zara Discount % Textbox
            TextField(
              controller: _alZaraDiscountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Al Zara Discount % (from Selling Price)',
                suffixText: '%',
                hintText: 'e.g. 10',
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() => _alZaraDiscountPercent = parsed);
              },
            ),

            if (_costPrice > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AZ Trade Price:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    AnimatedPriceText(
                      value: calcResult.alZaraDiscountPrice,
                      prefix: '₹',
                      style: AppTypography.priceMedium(
                        color: calcResult.isFloorClamped ? AppColors.yellow : AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => _onSave(context, ref, authState.role, calcResult),
                child: Text(
                  authState.role.isAdmin
                      ? (isEditing ? 'Save Changes' : 'Add Product')
                      : 'Submit for Admin Approval',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBrandPicker(BuildContext context, WidgetRef ref) {
    final allBrands = ref.watch(brandsProvider);
    final brands = allBrands.where((b) => b.categoryId == _selectedCategoryId).toList();

    return [
      const SizedBox(height: 16),
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
          ...brands.map((b) => _BrandChip(
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
          _BrandChip(
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

  Future<void> _onSave(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    PricingCalculationResult calc,
  ) async {
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

    final categories = ref.read(categoriesProvider);
    final category = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    final product = Product(
      id: isEditing ? widget.product!.id : 'p_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: category.icon,
      categoryId: _selectedCategoryId,
      categoryName: category.name,
      brandId: _selectedBrandId,
      brandName: _selectedBrandName,
      costPrice: _costPrice,
      mrp: _mrp,
      marginPercent: _marginPercent,
      sellingPrice: calc.sellingPrice,
      alZaraDiscountPercent: _alZaraDiscountPercent,
      alZaraDiscountPrice: calc.alZaraDiscountPrice,
      createdAt: isEditing ? widget.product!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: role.name,
    );

    await ref.read(catalogNotifierProvider.notifier).saveProduct(product: product, role: role);

    if (context.mounted) {
      Navigator.pop(context);
      AppleAlert.showToast(
        context,
        message: role.isAdmin
            ? (isEditing ? 'Product updated' : 'Product added to catalog')
            : 'Submitted for Admin approval',
        icon: CupertinoIcons.checkmark_circle_fill,
      );
    }
  }
}

class _BrandChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAdd;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _BrandChip({
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
