import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';
import '../domain/cart_item_model.dart';
import '../data/cashier_providers.dart';

// Provider for fetching Categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(cashierRepositoryProvider);
  return await repo.getCategories();
});

// Notifier for currently selected category filter (null means All)
class SelectedCategoryNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void selectCategory(int? categoryId) {
    state = categoryId;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, int?>(() {
  return SelectedCategoryNotifier();
});

// Notifier for search query filter
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Provider for fetching Products based on selected category and search query
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(cashierRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  final products = await repo.getProducts(categoryId: selectedCategory);
  if (searchQuery.isEmpty) {
    return products;
  }
  return products.where((p) => p.name.toLowerCase().contains(searchQuery)).toList();
});

// Notifier for Cart Management
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addProduct(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) state[i].copyWith(quantity: state[i].quantity + 1)
          else state[i]
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void decreaseQuantity(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      if (state[existingIndex].quantity > 1) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == existingIndex) state[i].copyWith(quantity: state[i].quantity - 1)
            else state[i]
        ];
      } else {
        removeProduct(product);
      }
    }
  }

  void removeProduct(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

// Provider for fetching today's queue
final queueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(cashierRepositoryProvider);
  return await repo.getTodayQueue();
});
