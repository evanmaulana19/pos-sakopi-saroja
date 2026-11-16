import 'category_model.dart';
import 'product_model.dart';
import 'cart_item_model.dart';

abstract class CashierRepository {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts({int? categoryId});
  Future<String> submitTransaction({
    required String cashierId,
    required List<CartItem> items,
    required String paymentMethod,
    required double totalAmount,
  });
  Future<List<Map<String, dynamic>>> getTodayQueue();
  Future<void> updateTransactionStatus(String transactionId, String status);
}
