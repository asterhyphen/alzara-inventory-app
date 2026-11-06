import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_zara_app/features/auth/domain/user_role.dart';
import 'package:al_zara_app/features/products/domain/product.dart';
import 'package:al_zara_app/features/products/presentation/product_providers.dart';
import 'package:al_zara_app/features/approvals/presentation/approvals_providers.dart';

/// These tests exercise the in-memory (offline) path of the Supabase-backed
/// providers. Supabase is NOT initialized in the test environment — the repos
/// fall back to their local StreamController cache, so all state starts empty.
void main() {
  group('Catalog & Approvals Workflow Tests (offline / local-cache mode)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ── helpers ────────────────────────────────────────────────────────────
    Product makeProduct({String id = 'test_1', String name = 'Test Bulb', double sellingPrice = 100.0}) {
      return Product(
        id: id,
        name: name,
        categoryId: 'general',
        categoryName: 'General',
        icon: CupertinoIcons.lightbulb_fill,
        costPrice: 60.0,
        mrp: 120.0,
        marginPercent: 40.0,
        sellingPrice: sellingPrice,
        alZaraDiscountPercent: 5.0,
        alZaraDiscountPrice: 95.0,
        status: 'live',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        updatedBy: 'admin',
      );
    }

    // ── 1. Empty initial state ──────────────────────────────────────────────
    test('Initial catalog is empty and has no pending changes', () {
      final products = container.read(productsListProvider);
      final categories = container.read(categoriesProvider);
      final pendingCount = container.read(pendingCountProvider);

      expect(products, isEmpty);
      // At least the virtual "All" + "General" categories exist
      expect(categories, isNotEmpty);
      expect(pendingCount, 0);
    });

    // ── 2. Admin save goes live immediately ────────────────────────────────
    test('Admin saves product directly without queueing', () async {
      final product = makeProduct();
      final initialPending = container.read(pendingCountProvider);

      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: product, role: UserRole.admin);

      final found = container
          .read(catalogNotifierProvider.notifier)
          .getProductById(product.id);
      expect(found?.sellingPrice, product.sellingPrice);
      expect(container.read(pendingCountProvider), initialPending);
    });

    // ── 3. Shopkeeper edit queues a pending change ─────────────────────────
    test('Shopkeeper creates a pending change without mutating live product', () async {
      // First, admin adds the base product
      final product = makeProduct(sellingPrice: 100.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: product, role: UserRole.admin);

      final initialPending = container.read(pendingCountProvider);

      // Shopkeeper proposes a price change
      final updated = product.copyWith(sellingPrice: 888.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: updated, role: UserRole.shopkeeper);

      // Live product should remain untouched
      final found = container
          .read(catalogNotifierProvider.notifier)
          .getProductById(product.id);
      expect(found?.sellingPrice, 100.0);

      // Pending count should have incremented
      expect(container.read(pendingCountProvider), initialPending + 1);

      // The diff should reference the correct product and field
      final pending = container.read(activePendingChangesProvider).first;
      expect(pending.productId, product.id);
      expect(pending.diffs.any((d) => d.fieldName == 'sellingPrice'), true);
    });

    // ── 4. Admin approves a pending change ─────────────────────────────────
    test('Admin approves single pending change and updates live product', () async {
      // Setup: admin adds product, shopkeeper queues change
      final product = makeProduct(sellingPrice: 100.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: product, role: UserRole.admin);
      final updated = product.copyWith(sellingPrice: 777.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: updated, role: UserRole.shopkeeper);

      final before = container.read(pendingCountProvider);
      final pending = container.read(activePendingChangesProvider).first;

      await container
          .read(approvalsNotifierProvider.notifier)
          .approvePendingChange(pending.id);

      expect(container.read(pendingCountProvider), before - 1);
      final live = container
          .read(catalogNotifierProvider.notifier)
          .getProductById(pending.productId!);
      expect(live?.sellingPrice, pending.proposedProduct.sellingPrice);
    });

    // ── 5. Admin rejects a pending change ──────────────────────────────────
    test('Admin rejects pending change without modifying live product', () async {
      final product = makeProduct(sellingPrice: 100.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: product, role: UserRole.admin);
      final updated = product.copyWith(sellingPrice: 555.0);
      await container
          .read(catalogNotifierProvider.notifier)
          .saveProduct(product: updated, role: UserRole.shopkeeper);

      final before = container.read(pendingCountProvider);
      final pending = container.read(activePendingChangesProvider).first;
      final originalPrice = container
          .read(catalogNotifierProvider.notifier)
          .getProductById(pending.productId!)
          ?.sellingPrice;

      await container
          .read(approvalsNotifierProvider.notifier)
          .rejectPendingChange(pending.id, reason: 'Margin too low');

      expect(container.read(pendingCountProvider), before - 1);
      final live = container
          .read(catalogNotifierProvider.notifier)
          .getProductById(pending.productId!);
      expect(live?.sellingPrice, originalPrice);
    });

    // ── 6. Admin batch-approves all pending changes ─────────────────────────
    test('Admin batch approves all pending changes', () async {
      final p1 = makeProduct(id: 'b1', name: 'Bulb 1', sellingPrice: 100.0);
      final p2 = makeProduct(id: 'b2', name: 'Bulb 2', sellingPrice: 200.0);
      await container.read(catalogNotifierProvider.notifier).saveProduct(product: p1, role: UserRole.admin);
      await container.read(catalogNotifierProvider.notifier).saveProduct(product: p2, role: UserRole.admin);

      await container.read(catalogNotifierProvider.notifier).saveProduct(product: p1.copyWith(sellingPrice: 111.0), role: UserRole.shopkeeper);
      await container.read(catalogNotifierProvider.notifier).saveProduct(product: p2.copyWith(sellingPrice: 222.0), role: UserRole.shopkeeper);

      // Verify via repo cache (synchronous in offline mode)
      final repo = container.read(approvalsRepositoryProvider);
      expect(repo.currentPending.where((p) => p.status == 'pending').length, 2);

      final count = await container
          .read(approvalsNotifierProvider.notifier)
          .approveAllPending();

      // Verify count returned and that repo cache reflects all active pending were approved
      expect(count, 2);
      expect(repo.currentPending.where((p) => p.status == 'pending').isEmpty, true);
    });

    // ── 7. Category management ─────────────────────────────────────────────
    test('Admin can add and delete a category', () async {
      final catRepo = container.read(categoryRepositoryProvider);
      final initialCount = catRepo.currentCategories.length;

      await container
          .read(catalogNotifierProvider.notifier)
          .addCategory('Power Tools');

      // Verify via repo cache (synchronous in offline mode)
      expect(catRepo.currentCategories.length, initialCount + 1);
      expect(catRepo.currentCategories.any((c) => c.name == 'Power Tools'), true);

      final newCat = catRepo.currentCategories.firstWhere((c) => c.name == 'Power Tools');
      await container
          .read(catalogNotifierProvider.notifier)
          .deleteCategory(newCat.id);

      expect(catRepo.currentCategories.any((c) => c.name == 'Power Tools'), false);
      expect(catRepo.currentCategories.length, initialCount);
    });
  });
}
