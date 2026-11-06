import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/al_zara_pill.dart';
import '../../../core/widgets/animated_price_text.dart';
import '../../../core/widgets/apple_alert.dart';
import '../../approvals/presentation/approvals_providers.dart';
import 'product_providers.dart';
import 'widgets/quick_price_edit_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogNotifierProvider);
    final pendingChanges = ref.watch(activePendingChangesProvider);

    final product = catalog.products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const Center(child: Text('Product not found')),
      );
    }

    final hasPending = pendingChanges.any((p) => p.productId == productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Product Details',
          style: AppTypography.headlineSmall.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              ),
              child: const Icon(CupertinoIcons.trash, size: 18, color: AppColors.red),
            ),
            onPressed: () => _confirmDelete(context, ref, product),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldBeigeSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: const Icon(CupertinoIcons.pencil, size: 18, color: AppColors.primaryLight),
              ),
              onPressed: () => QuickPriceEditSheet.show(context, product),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Header Banner (No placeholder box!)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.35)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardElevated,
                    AppColors.surfaceDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          AlZaraPill(
                            label: product.categoryName,
                            isSmall: true,
                            variant: PillVariant.gold,
                          ),
                          if (product.brandName.isNotEmpty)
                            AlZaraPill(
                              label: product.brandName,
                              variant: PillVariant.neutral,
                              isSmall: true,
                            ),
                        ],
                      ),
                      if (hasPending)
                        const AlZaraPill(
                          label: 'Pending Review',
                          icon: CupertinoIcons.clock_fill,
                          variant: PillVariant.warning,
                          isSmall: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    product.name,
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (product.unit.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Packaging: ${product.unit}',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── PRICING BLOCK ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRICE LADDER',
                        style: AppTypography.caption.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => QuickPriceEditSheet.show(context, product),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldBeigeSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.pencil,
                                size: 12,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // MRP
                  _PriceRow(
                    label: 'MRP (Maximum Retail Price)',
                    price: product.mrp,
                    color: AppColors.textMuted,
                    isStrikethrough: false,
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Selling Price
                  _PriceRow(
                    label: 'Selling Price',
                    price: product.sellingPrice,
                    color: AppColors.primaryLight,
                    subtitle: 'Retail Margin: ${CurrencyFormatter.formatPercent(product.marginPercent)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Al Zara Discount Price
                  _PriceRow(
                    label: 'Al Zara Discount Price',
                    price: product.alZaraDiscountPrice,
                    color: AppColors.primary,
                    subtitle: 'Trade discount: ${CurrencyFormatter.formatPercent(product.alZaraDiscountPercent)}',
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Cost Price
                  _PriceRow(
                    label: 'Cost Price (Wholesale)',
                    price: product.costPrice,
                    color: AppColors.textSecondary,
                    subtitle: 'Supplier Base Cost',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profit Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldBeigeSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfitMetric(
                    'Retail Profit',
                    product.sellingPrice - product.costPrice,
                    AppColors.primaryLight,
                  ),
                  Container(width: 1, height: 36, color: AppColors.borderGold.withValues(alpha: 0.3)),
                  _buildProfitMetric(
                    'Trade Profit',
                    product.alZaraDiscountPrice - product.costPrice,
                    AppColors.primary,
                  ),
                  Container(width: 1, height: 36, color: AppColors.borderGold.withValues(alpha: 0.3)),
                  _buildProfitMetric(
                    'MRP Discount',
                    product.mrp - product.sellingPrice,
                    AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metadata
            Text(
              'AUDIT & METADATA',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(label: 'Product ID', value: product.id),
            _InfoRow(label: 'Last Updated', value: _formatDate(product.updatedAt)),
            _InfoRow(label: 'Updated By', value: product.updatedBy.toUpperCase()),

            const SizedBox(height: 32),

            // Delete Product Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.red.withValues(alpha: 0.08),
                ),
                icon: const Icon(CupertinoIcons.trash, size: 18),
                label: const Text(
                  'Delete Product',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                onPressed: () => _confirmDelete(context, ref, product),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, dynamic product) async {
    final confirmed = await AppleAlert.showConfirmation(
      context: context,
      title: 'Delete Product',
      message: 'Are you sure you want to permanently delete "${product.name}"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(catalogNotifierProvider.notifier).deleteProduct(product.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        AppleAlert.showToast(
          context,
          message: 'Product deleted from catalog',
          icon: CupertinoIcons.trash,
          iconColor: AppColors.red,
        );
      }
    }
  }

  Widget _buildProfitMetric(String label, double amount, Color color) {
    return Column(
      children: [
        AnimatedPriceText(
          value: amount,
          prefix: '₹',
          style: AppTypography.priceMedium(color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  final String? subtitle;
  final bool isBold;
  final bool isStrikethrough;

  const _PriceRow({
    required this.label,
    required this.price,
    required this.color,
    this.subtitle,
    this.isBold = false,
    this.isStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        AnimatedPriceText(
          value: price,
          prefix: '₹',
          style: AppTypography.priceLarge(color: color).copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: color,
            fontSize: isBold ? 26 : 22,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
