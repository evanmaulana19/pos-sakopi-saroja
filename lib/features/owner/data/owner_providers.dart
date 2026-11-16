import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/owner_repository.dart';
import 'supabase_owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return SupabaseOwnerRepository(Supabase.instance.client);
});

enum DateFilter { hariIni, mingguIni, bulanIni }

class DateFilterNotifier extends Notifier<DateFilter> {
  @override
  DateFilter build() => DateFilter.bulanIni;

  void setFilter(DateFilter filter) {
    state = filter;
  }
}

final dateFilterProvider = NotifierProvider<DateFilterNotifier, DateFilter>(() => DateFilterNotifier());

class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  DateRange(this.startDate, this.endDate);
}

final dateRangeProvider = Provider<DateRange>((ref) {
  final filter = ref.watch(dateFilterProvider);
  final now = DateTime.now();
  
  DateTime startDate;
  DateTime endDate;
  
  switch (filter) {
    case DateFilter.hariIni:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case DateFilter.mingguIni:
      // Start of week (Monday)
      final diff = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
      endDate = startDate.add(const Duration(days: 7));
      break;
    case DateFilter.bulanIni:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
  }
  return DateRange(startDate, endDate);
});

final financialReportProvider = FutureProvider<FinancialReport>((ref) async {
  final range = ref.watch(dateRangeProvider);
  return await ref.watch(ownerRepositoryProvider).getFinancialReport(range.startDate, range.endDate);
});

final top5MenusProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final range = ref.watch(dateRangeProvider);
  return await ref.watch(ownerRepositoryProvider).getTop5Menus(range.startDate, range.endDate);
});

final dailyRevenueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final range = ref.watch(dateRangeProvider);
  return await ref.watch(ownerRepositoryProvider).getDailyRevenue(range.startDate, range.endDate);
});

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final range = ref.watch(dateRangeProvider);
  return await ref.watch(ownerRepositoryProvider).getExpenses(range.startDate, range.endDate);
});

final staffAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(ownerRepositoryProvider).getStaffAccounts();
});
