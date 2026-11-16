import '../../cashier/domain/product_model.dart';

class AdminSummary {
  final int totalActiveMenu;
  final int totalOutOfStock;
  final int todayTransactions;

  AdminSummary({
    required this.totalActiveMenu,
    required this.totalOutOfStock,
    required this.todayTransactions,
  });
}

abstract class AdminRepository {
  Future<AdminSummary> getOperationalSummary();
  Future<List<Product>> getAllProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int productId);
  Future<void> toggleProductAvailability(int productId, bool isAvailable);
  // Returns generic maps for transactions to avoid complex relational mapping here
  Future<List<Map<String, dynamic>>> getRecentTransactions();
  Future<List<Map<String, dynamic>>> getTransactionItems(String transactionId);
}
