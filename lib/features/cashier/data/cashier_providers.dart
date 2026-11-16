import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/cashier_repository.dart';
import 'supabase_cashier_repository.dart';

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  return SupabaseCashierRepository(Supabase.instance.client);
});
