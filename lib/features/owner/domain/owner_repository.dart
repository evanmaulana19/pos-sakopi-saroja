class Expense {
  final int? id;
  final double amount;
  final String description;
  final DateTime expenseDate;

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.expenseDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      expenseDate: DateTime.parse(json['expense_date']),
    );
  }
}

class FinancialReport {
  final double grossRevenue;
  final double totalExpenses;
  final double netProfit;
  final double midtransTotal;
  final double tunaiTotal;

  FinancialReport({
    required this.grossRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.midtransTotal,
    required this.tunaiTotal,
  });
}

abstract class OwnerRepository {
  Future<FinancialReport> getFinancialReport(DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getTop5Menus(DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getDailyRevenue(DateTime startDate, DateTime endDate);

  Future<List<Expense>> getExpenses(DateTime startDate, DateTime endDate);
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(int id);

  // Managing staff
  Future<List<Map<String, dynamic>>> getStaffAccounts();
  Future<void> addStaff(String id, String email, String name, String role);
  Future<void> updateStaff(String id, String name, String role);
  Future<void> deleteStaff(String id);

  Future<void> resetTransactions(DateTime startDate, DateTime endDate);
}
