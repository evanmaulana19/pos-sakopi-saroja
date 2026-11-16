import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/local_fallback_store.dart';
import '../../../core/utils/security_audit_logger.dart';
import '../../../core/utils/security_utils.dart';
import '../domain/cashier_repository.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';
import '../domain/cart_item_model.dart';

class SupabaseCashierRepository implements CashierRepository {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  SupabaseCashierRepository(this._supabase);

  @override
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase.from('categories').select().order('id', ascending: true);
      return (response as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Category>.from(LocalFallbackStore.categories);
      }
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  @override
  Future<List<Product>> getProducts({int? categoryId}) async {
    try {
      var query = _supabase.from('products').select();
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      final response = await query.order('name', ascending: true);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final all = List<Product>.from(LocalFallbackStore.products);
        if (categoryId != null) {
          return all.where((p) => p.categoryId == categoryId).toList();
        }
        return all;
      }
      throw Exception('Gagal memuat produk: $e');
    }
  }

  @override
  Future<String> submitTransaction({
    required String cashierId,
    required List<CartItem> items,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    final currentUserId =
        _supabase.auth.currentUser?.id ?? LocalFallbackStore.currentUser?.id;
    if (currentUserId != null && currentUserId != cashierId) {
      SecurityAuditLogger.log(
        eventType: 'IDOR_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan manipulasi ID kasir (IDOR) pada transaksi diblokir!',
      );
      throw Exception('Pelanggaran Keamanan (IDOR): ID Kasir tidak sesuai dengan sesi aktif.');
    }

    if (items.isEmpty || totalAmount <= 0) {
      throw Exception('Transaksi tidak valid: Keranjang kosong atau nominal tidak valid.');
    }

    final safePaymentMethod = SecurityUtils.sanitizeInput(paymentMethod);
    if (safePaymentMethod != 'Tunai' && safePaymentMethod != 'Non-Tunai') {
      throw Exception('Metode pembayaran tidak valid.');
    }

    final transactionId = _uuid.v4();

    try {
      await _supabase.from('transactions').insert({
        'id': transactionId,
        'cashier_id': cashierId,
        'total_amount': totalAmount,
        'payment_method': safePaymentMethod,
        'status': 'Diproses',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final transactionItems = items.map((item) {
        return {
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price_at_time': item.product.price,
        };
      }).toList();

      await _supabase.from('transaction_items').insert(transactionItems);

      SecurityAuditLogger.log(
        eventType: 'POS_TRANSACTION_CREATED',
        severity: SecuritySeverity.info,
        description:
            'Transaksi baru #${transactionId.substring(0, 8)} ($safePaymentMethod - Rp ${totalAmount.toInt()}) berhasil disimpan.',
      );

      return transactionId;
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.recordTransaction(
          transactionId: transactionId,
          cashierId: cashierId,
          items: items,
          paymentMethod: safePaymentMethod,
          totalAmount: totalAmount,
        );
        SecurityAuditLogger.log(
          eventType: 'POS_TRANSACTION_CREATED',
          severity: SecuritySeverity.info,
          description:
              'Transaksi baru #${transactionId.substring(0, 8)} ($safePaymentMethod - Rp ${totalAmount.toInt()}) berhasil disimpan (Fallback Store).',
        );
        return transactionId;
      }
      throw Exception('Gagal menyimpan transaksi: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTodayQueue() async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from('transactions')
          .select('id, created_at, status, total_amount, payment_method, users_profile(name)')
          .gte('created_at', '${todayStr}T00:00:00Z')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Map<String, dynamic>>.from(LocalFallbackStore.transactions);
      }
      throw Exception('Gagal memuat antrean: $e');
    }
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    final safeStatus = SecurityUtils.sanitizeInput(status);
    if (safeStatus != 'Diproses' && safeStatus != 'Selesai') {
      throw Exception('Status transaksi tidak valid.');
    }
    try {
      await _supabase
          .from('transactions')
          .update({'status': safeStatus})
          .eq('id', transactionId);

      SecurityAuditLogger.log(
        eventType: 'POS_QUEUE_UPDATED',
        severity: SecuritySeverity.info,
        description: 'Status pesanan #${transactionId.substring(0, 8)} diubah menjadi "$safeStatus".',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        for (final tx in LocalFallbackStore.transactions) {
          if (tx['id'] == transactionId) {
            tx['status'] = safeStatus;
          }
        }
        SecurityAuditLogger.log(
          eventType: 'POS_QUEUE_UPDATED',
          severity: SecuritySeverity.info,
          description:
              'Status pesanan #${transactionId.substring(0, 8)} diubah menjadi "$safeStatus".',
        );
        return;
      }
      throw Exception('Gagal memperbarui status transaksi: $e');
    }
  }
}
