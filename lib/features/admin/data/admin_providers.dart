import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/admin_repository.dart';
import 'supabase_admin_repository.dart';
import '../../cashier/domain/product_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return SupabaseAdminRepository(Supabase.instance.client);
});

final adminSummaryProvider = FutureProvider<AdminSummary>((ref) async {
  return await ref.watch(adminRepositoryProvider).getOperationalSummary();
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return await ref.watch(adminRepositoryProvider).getAllProducts();
});

final recentTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(adminRepositoryProvider).getRecentTransactions();
});
