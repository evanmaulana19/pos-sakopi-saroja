import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/local_fallback_store.dart';
import '../../../core/utils/security_audit_logger.dart';
import '../../../core/utils/security_utils.dart';
import '../domain/admin_repository.dart';
import '../../cashier/domain/product_model.dart';

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient _supabase;

  SupabaseAdminRepository(this._supabase);

  @override
  Future<AdminSummary> getOperationalSummary() async {
    try {
      final products = await _supabase.from('products').select('is_available');
      final active = products.where((p) => p['is_available'] == true).length;
      final outOfStock = products.where((p) => p['is_available'] == false).length;

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final tx = await _supabase
          .from('transactions')
          .select('id')
          .gte('created_at', '${todayStr}T00:00:00Z');

      return AdminSummary(
        totalActiveMenu: active,
        totalOutOfStock: outOfStock,
        todayTransactions: tx.length,
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final active = LocalFallbackStore.products.where((p) => p.isAvailable).length;
        final outOfStock = LocalFallbackStore.products.where((p) => !p.isAvailable).length;
        return AdminSummary(
          totalActiveMenu: active,
          totalOutOfStock: outOfStock,
          todayTransactions: LocalFallbackStore.transactions.length,
        );
      }
      throw Exception('Failed to load summary: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _supabase.from('products').select().order('name', ascending: true);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Product>.from(LocalFallbackStore.products);
      }
      throw Exception('Failed to load products: $e');
    }
  }

  @override
  Future<void> addProduct(Product product) async {
    final nameErr = SecurityUtils.validateSafeText(
      product.name,
      fieldName: 'Nama Produk',
      minLength: 2,
      maxLength: 100,
    );
    if (nameErr != null) throw Exception(nameErr);

    final urlErr = SecurityUtils.validateSafeUrl(product.imageUrl, fieldName: 'URL Gambar');
    if (urlErr != null) throw Exception(urlErr);

    if (product.price <= 0) {
      throw Exception('Harga produk harus lebih dari Rp 0');
    }

    final cleanName = SecurityUtils.sanitizeInput(product.name);
    final cleanUrl = product.imageUrl.trim();

    try {
      await _supabase.from('products').insert({
        'category_id': product.categoryId,
        'name': cleanName,
        'price': product.price,
        'image_url': cleanUrl,
        'is_available': product.isAvailable,
      });

      SecurityAuditLogger.log(
        eventType: 'ADMIN_PRODUCT_CREATED',
        severity: SecuritySeverity.info,
        description: 'Produk baru "$cleanName" (Rp ${product.price.toInt()}) berhasil ditambahkan.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final nextId = LocalFallbackStore.products.isEmpty
            ? 1
            : LocalFallbackStore.products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
        LocalFallbackStore.products.add(
          Product(
            id: nextId,
            categoryId: product.categoryId,
            name: cleanName,
            price: product.price,
            imageUrl: cleanUrl,
            isAvailable: product.isAvailable,
          ),
        );
        SecurityAuditLogger.log(
          eventType: 'ADMIN_PRODUCT_CREATED',
          severity: SecuritySeverity.info,
          description: 'Produk baru "$cleanName" (Rp ${product.price.toInt()}) berhasil ditambahkan.',
        );
        return;
      }
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    final nameErr = SecurityUtils.validateSafeText(
      product.name,
      fieldName: 'Nama Produk',
      minLength: 2,
      maxLength: 100,
    );
    if (nameErr != null) throw Exception(nameErr);

    final urlErr = SecurityUtils.validateSafeUrl(product.imageUrl, fieldName: 'URL Gambar');
    if (urlErr != null) throw Exception(urlErr);

    if (product.price <= 0) {
      throw Exception('Harga produk harus lebih dari Rp 0');
    }

    final cleanName = SecurityUtils.sanitizeInput(product.name);
    final cleanUrl = product.imageUrl.trim();

    try {
      await _supabase.from('products').update({
        'category_id': product.categoryId,
        'name': cleanName,
        'price': product.price,
        'image_url': cleanUrl,
        'is_available': product.isAvailable,
      }).eq('id', product.id);

      SecurityAuditLogger.log(
        eventType: 'ADMIN_PRODUCT_UPDATED',
        severity: SecuritySeverity.info,
        description: 'Produk ID #${product.id} ("$cleanName") berhasil diperbarui.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final idx = LocalFallbackStore.products.indexWhere((p) => p.id == product.id);
        if (idx >= 0) {
          LocalFallbackStore.products[idx] = Product(
            id: product.id,
            categoryId: product.categoryId,
            name: cleanName,
            price: product.price,
            imageUrl: cleanUrl,
            isAvailable: product.isAvailable,
          );
        }
        SecurityAuditLogger.log(
          eventType: 'ADMIN_PRODUCT_UPDATED',
          severity: SecuritySeverity.info,
          description: 'Produk ID #${product.id} ("$cleanName") berhasil diperbarui.',
        );
        return;
      }
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(int productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      SecurityAuditLogger.log(
        eventType: 'ADMIN_PRODUCT_DELETED',
        severity: SecuritySeverity.warning,
        description: 'Produk ID #$productId telah dihapus dari database.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.products.removeWhere((p) => p.id == productId);
        SecurityAuditLogger.log(
          eventType: 'ADMIN_PRODUCT_DELETED',
          severity: SecuritySeverity.warning,
          description: 'Produk ID #$productId telah dihapus.',
        );
        return;
      }
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<void> toggleProductAvailability(int productId, bool isAvailable) async {
    try {
      await _supabase.from('products').update({'is_available': isAvailable}).eq('id', productId);
      SecurityAuditLogger.log(
        eventType: 'ADMIN_PRODUCT_AVAILABILITY',
        severity: SecuritySeverity.info,
        description:
            'Status ketersediaan produk ID #$productId diubah menjadi ${isAvailable ? "Tersedia" : "Habis"}.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final idx = LocalFallbackStore.products.indexWhere((p) => p.id == productId);
        if (idx >= 0) {
          LocalFallbackStore.products[idx] = LocalFallbackStore.products[idx].copyWith(
            isAvailable: isAvailable,
          );
        }
        SecurityAuditLogger.log(
          eventType: 'ADMIN_PRODUCT_AVAILABILITY',
          severity: SecuritySeverity.info,
          description:
              'Status ketersediaan produk ID #$productId diubah menjadi ${isAvailable ? "Tersedia" : "Habis"}.',
        );
        return;
      }
      throw Exception('Failed to toggle availability: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('id, created_at, status, total_amount, payment_method, users_profile(name)')
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Map<String, dynamic>>.from(LocalFallbackStore.transactions);
      }
      throw Exception('Failed to load recent transactions: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_items')
          .select('quantity, price_at_time, products(name)')
          .eq('transaction_id', transactionId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Map<String, dynamic>>.from(
          LocalFallbackStore.transactionItemsByTxId[transactionId] ?? [],
        );
      }
      throw Exception('Failed to load transaction items: $e');
    }
  }
}
