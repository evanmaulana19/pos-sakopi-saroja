import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/local_fallback_store.dart';
import '../../../core/utils/security_audit_logger.dart';
import '../../../core/utils/security_utils.dart';
import '../../auth/domain/user_profile_model.dart';
import '../domain/owner_repository.dart';

class SupabaseOwnerRepository implements OwnerRepository {
  final SupabaseClient _supabase;

  SupabaseOwnerRepository(this._supabase);

  @override
  Future<FinancialReport> getFinancialReport(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _supabase
          .from('transactions')
          .select('total_amount, payment_method')
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String())
          .eq('status', 'Selesai');

      double gross = 0.0;
      double tunai = 0.0;
      double midtrans = 0.0;

      for (var tx in transactions) {
        final amount = (tx['total_amount'] as num).toDouble();
        gross += amount;
        if (tx['payment_method'] == 'Tunai') tunai += amount;
        if (tx['payment_method'] == 'Non-Tunai') midtrans += amount;
      }

      final expensesData = await _supabase
          .from('expenses')
          .select('amount')
          .gte('expense_date', startDate.toIso8601String())
          .lt('expense_date', endDate.toIso8601String());

      double expenses = 0.0;
      for (var ex in expensesData) {
        expenses += (ex['amount'] as num).toDouble();
      }

      return FinancialReport(
        grossRevenue: gross,
        totalExpenses: expenses,
        netProfit: gross - expenses,
        midtransTotal: midtrans,
        tunaiTotal: tunai,
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        double gross = 0.0;
        double tunai = 0.0;
        double midtrans = 0.0;
        for (final tx in LocalFallbackStore.transactions) {
          if (tx['status'] == 'Selesai') {
            final amount = (tx['total_amount'] as num).toDouble();
            gross += amount;
            if (tx['payment_method'] == 'Tunai') tunai += amount;
            if (tx['payment_method'] == 'Non-Tunai') midtrans += amount;
          }
        }
        double expenses = 0.0;
        for (final ex in LocalFallbackStore.expenses) {
          expenses += ex.amount;
        }
        return FinancialReport(
          grossRevenue: gross,
          totalExpenses: expenses,
          netProfit: gross - expenses,
          midtransTotal: midtrans,
          tunaiTotal: tunai,
        );
      }
      throw Exception('Failed to load financial report: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyRevenue(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _supabase
          .from('transactions')
          .select('created_at, total_amount')
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String())
          .eq('status', 'Selesai')
          .order('created_at', ascending: true);

      Map<String, double> dailyTotals = {};
      for (var tx in transactions) {
        String dateStr = (tx['created_at'] as String).split('T')[0];
        double amount = (tx['total_amount'] as num).toDouble();
        dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0.0) + amount;
      }

      List<Map<String, dynamic>> result = [];
      dailyTotals.forEach((key, value) {
        result.add({
          'date': key,
          'revenue': value,
        });
      });

      return result;
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final Map<String, double> dailyTotals = {};
        for (final tx in LocalFallbackStore.transactions) {
          if (tx['status'] == 'Selesai') {
            final dateStr = (tx['created_at'] as String).split('T')[0];
            final amount = (tx['total_amount'] as num).toDouble();
            dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0.0) + amount;
          }
        }
        return dailyTotals.entries
            .map((entry) => {'date': entry.key, 'revenue': entry.value})
            .toList();
      }
      throw Exception('Failed to load daily revenue: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTop5Menus(DateTime startDate, DateTime endDate) async {
    try {
      final txList = await _supabase
          .from('transactions')
          .select('id')
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String())
          .eq('status', 'Selesai');

      if ((txList as List).isEmpty) {
        return [];
      }

      final txIds = txList.map((e) => e['id'].toString()).toList();

      final itemsResponse = await _supabase
          .from('transaction_items')
          .select('quantity, products(name)')
          .inFilter('transaction_id', txIds);

      final Map<String, int> counts = {};
      for (final item in (itemsResponse as List)) {
        final productObj = item['products'];
        final productName = productObj != null && productObj['name'] != null
            ? productObj['name'].toString()
            : 'Produk Terhapus';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        counts[productName] = (counts[productName] ?? 0) + qty;
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(5)
          .map((entry) => {'name': entry.key, 'qty': entry.value})
          .toList();
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final Map<String, int> counts = {};
        for (final tx in LocalFallbackStore.transactions) {
          if (tx['status'] == 'Selesai') {
            final items = LocalFallbackStore.transactionItemsByTxId[tx['id']] ?? [];
            for (final item in items) {
              final productName = item['products']?['name']?.toString() ?? 'Menu';
              final qty = (item['quantity'] as num?)?.toInt() ?? 0;
              counts[productName] = (counts[productName] ?? 0) + qty;
            }
          }
        }
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sorted
            .take(5)
            .map((entry) => {'name': entry.key, 'qty': entry.value})
            .toList();
      }
      return [];
    }
  }

  @override
  Future<List<Expense>> getExpenses(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .gte('expense_date', startDate.toIso8601String())
          .lt('expense_date', endDate.toIso8601String())
          .order('expense_date', ascending: false);

      return (response as List).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return List<Expense>.from(LocalFallbackStore.expenses);
      }
      throw Exception('Failed to load expenses: $e');
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    final descErr = SecurityUtils.validateSafeText(
      expense.description,
      fieldName: 'Deskripsi Pengeluaran',
      minLength: 3,
      maxLength: 150,
    );
    if (descErr != null) throw Exception(descErr);
    if (expense.amount <= 0) throw Exception('Nominal pengeluaran harus lebih dari Rp 0');

    final cleanDesc = SecurityUtils.sanitizeInput(expense.description);

    try {
      await _supabase.from('expenses').insert({
        'amount': expense.amount,
        'description': cleanDesc,
        'expense_date': expense.expenseDate.toUtc().toIso8601String(),
      });
      SecurityAuditLogger.log(
        eventType: 'OWNER_EXPENSE_ADDED',
        severity: SecuritySeverity.info,
        description: 'Pengeluaran "$cleanDesc" (Rp ${expense.amount.toInt()}) berhasil dicatat.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final nextId = LocalFallbackStore.expenses.isEmpty
            ? 1
            : LocalFallbackStore.expenses
                    .map((ex) => ex.id ?? 0)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        LocalFallbackStore.expenses.insert(
          0,
          Expense(
            id: nextId,
            amount: expense.amount,
            description: cleanDesc,
            expenseDate: expense.expenseDate,
          ),
        );
        SecurityAuditLogger.log(
          eventType: 'OWNER_EXPENSE_ADDED',
          severity: SecuritySeverity.info,
          description: 'Pengeluaran "$cleanDesc" (Rp ${expense.amount.toInt()}) berhasil dicatat.',
        );
        return;
      }
      throw Exception('Failed to add expense: $e');
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) throw Exception('ID Pengeluaran tidak ditemukan.');
    final descErr = SecurityUtils.validateSafeText(
      expense.description,
      fieldName: 'Deskripsi Pengeluaran',
      minLength: 3,
      maxLength: 150,
    );
    if (descErr != null) throw Exception(descErr);
    if (expense.amount <= 0) throw Exception('Nominal pengeluaran harus lebih dari Rp 0');

    final cleanDesc = SecurityUtils.sanitizeInput(expense.description);

    try {
      await _supabase.from('expenses').update({
        'amount': expense.amount,
        'description': cleanDesc,
      }).eq('id', expense.id!);

      SecurityAuditLogger.log(
        eventType: 'OWNER_EXPENSE_UPDATED',
        severity: SecuritySeverity.info,
        description: 'Pengeluaran ID #${expense.id} ("$cleanDesc") diperbarui.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final idx = LocalFallbackStore.expenses.indexWhere((ex) => ex.id == expense.id);
        if (idx >= 0) {
          LocalFallbackStore.expenses[idx] = Expense(
            id: expense.id,
            amount: expense.amount,
            description: cleanDesc,
            expenseDate: expense.expenseDate,
          );
        }
        SecurityAuditLogger.log(
          eventType: 'OWNER_EXPENSE_UPDATED',
          severity: SecuritySeverity.info,
          description: 'Pengeluaran ID #${expense.id} ("$cleanDesc") diperbarui.',
        );
        return;
      }
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(int id) async {
    try {
      await _supabase.from('expenses').delete().eq('id', id);
      SecurityAuditLogger.log(
        eventType: 'OWNER_EXPENSE_DELETED',
        severity: SecuritySeverity.warning,
        description: 'Pengeluaran ID #$id dihapus oleh Owner.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.expenses.removeWhere((ex) => ex.id == id);
        SecurityAuditLogger.log(
          eventType: 'OWNER_EXPENSE_DELETED',
          severity: SecuritySeverity.warning,
          description: 'Pengeluaran ID #$id dihapus oleh Owner.',
        );
        return;
      }
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffAccounts() async {
    try {
      final response = await _supabase.from('users_profile').select().order('role');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        return LocalFallbackStore.users.map((u) => u.toJson()).toList();
      }
      throw Exception('Failed to load staff accounts: $e');
    }
  }

  @override
  Future<void> addStaff(String id, String email, String name, String role) async {
    final nameErr = SecurityUtils.validateSafeText(
      name,
      fieldName: 'Nama Staf',
      minLength: 2,
      maxLength: 80,
    );
    if (nameErr != null) throw Exception(nameErr);

    final emailErr = SecurityUtils.validateEmail(email);
    if (emailErr != null) throw Exception(emailErr);

    final normalizedRole = role == 'cashier' ? 'kasir' : role.toLowerCase();
    if (!['kasir', 'admin', 'owner'].contains(normalizedRole)) {
      throw Exception('Role tidak valid. Gunakan kasir, admin, atau owner.');
    }

    final cleanName = SecurityUtils.sanitizeInput(name);
    final cleanEmail = SecurityUtils.sanitizeInput(email).toLowerCase();
    final cleanId = SecurityUtils.sanitizeInput(id);

    try {
      await _supabase.from('users_profile').insert({
        'id': cleanId,
        'email': cleanEmail,
        'name': cleanName,
        'role': normalizedRole,
      });
      SecurityAuditLogger.log(
        eventType: 'OWNER_STAFF_ADDED',
        severity: SecuritySeverity.info,
        description: 'Staf baru "$cleanName" ($cleanEmail) ditambahkan dengan role "$normalizedRole".',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.users.add(
          UserProfile(
            id: cleanId,
            email: cleanEmail,
            role: normalizedRole,
            name: cleanName,
          ),
        );
        SecurityAuditLogger.log(
          eventType: 'OWNER_STAFF_ADDED',
          severity: SecuritySeverity.info,
          description:
              'Staf baru "$cleanName" ($cleanEmail) ditambahkan dengan role "$normalizedRole".',
        );
        return;
      }
      throw Exception('Failed to add staff profile: $e');
    }
  }

  @override
  Future<void> updateStaff(String id, String name, String role) async {
    final nameErr = SecurityUtils.validateSafeText(
      name,
      fieldName: 'Nama Staf',
      minLength: 2,
      maxLength: 80,
    );
    if (nameErr != null) throw Exception(nameErr);

    final normalizedRole = role == 'cashier' ? 'kasir' : role.toLowerCase();
    if (!['kasir', 'admin', 'owner'].contains(normalizedRole)) {
      throw Exception('Role tidak valid. Gunakan kasir, admin, atau owner.');
    }

    final cleanName = SecurityUtils.sanitizeInput(name);

    try {
      await _supabase.from('users_profile').update({
        'name': cleanName,
        'role': normalizedRole,
      }).eq('id', id);

      SecurityAuditLogger.log(
        eventType: 'OWNER_STAFF_UPDATED',
        severity: SecuritySeverity.warning,
        description: 'Hak akses/profil staf "$cleanName" diperbarui menjadi role "$normalizedRole".',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final idx = LocalFallbackStore.users.indexWhere((u) => u.id == id);
        if (idx >= 0) {
          LocalFallbackStore.users[idx] = LocalFallbackStore.users[idx].copyWith(
            name: cleanName,
            role: normalizedRole,
          );
        }
        SecurityAuditLogger.log(
          eventType: 'OWNER_STAFF_UPDATED',
          severity: SecuritySeverity.warning,
          description:
              'Hak akses/profil staf "$cleanName" diperbarui menjadi role "$normalizedRole".',
        );
        return;
      }
      throw Exception('Failed to update staff profile: $e');
    }
  }

  @override
  Future<void> deleteStaff(String id) async {
    final currentUserId =
        _supabase.auth.currentUser?.id ?? LocalFallbackStore.currentUser?.id;
    if (currentUserId != null && currentUserId == id) {
      throw Exception('Anda tidak dapat menghapus akun Owner yang sedang digunakan saat ini.');
    }
    try {
      await _supabase.from('users_profile').delete().eq('id', id);
      SecurityAuditLogger.log(
        eventType: 'OWNER_STAFF_DELETED',
        severity: SecuritySeverity.warning,
        description: 'Profil staf dengan ID $id telah dihapus.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.users.removeWhere((u) => u.id == id);
        SecurityAuditLogger.log(
          eventType: 'OWNER_STAFF_DELETED',
          severity: SecuritySeverity.warning,
          description: 'Profil staf dengan ID $id telah dihapus.',
        );
        return;
      }
      throw Exception('Failed to delete staff profile: $e');
    }
  }

  @override
  Future<void> resetTransactions(DateTime startDate, DateTime endDate) async {
    try {
      await _supabase
          .from('transactions')
          .delete()
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String());

      SecurityAuditLogger.log(
        eventType: 'OWNER_TRANSACTIONS_RESET',
        severity: SecuritySeverity.critical,
        description: 'Transaksi pada periode terpilih telah di-reset oleh Owner.',
      );
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        LocalFallbackStore.transactions.clear();
        LocalFallbackStore.transactionItemsByTxId.clear();
        SecurityAuditLogger.log(
          eventType: 'OWNER_TRANSACTIONS_RESET',
          severity: SecuritySeverity.critical,
          description: 'Transaksi pada periode terpilih telah di-reset oleh Owner.',
        );
        return;
      }
      throw Exception('Failed to reset transactions: $e');
    }
  }
}
