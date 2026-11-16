import '../../features/auth/domain/user_profile_model.dart';
import '../../features/cashier/domain/category_model.dart';
import '../../features/cashier/domain/product_model.dart';
import '../../features/cashier/domain/cart_item_model.dart';
import '../../features/owner/domain/owner_repository.dart';

/// Penyimpanan Cadangan Lokal (Resilient Fallback Store)
/// Digunakan secara otomatis apabila server Supabase Cloud sedang dalam status
/// Paused (Free Tier Inactivity) atau mengalami gangguan jaringan ("Failed to fetch").
class LocalFallbackStore {
  static UserProfile? currentUser;

  static final Map<String, String> _passwordsByEmail = {
    'kasir@sakopi.com': 'Sakopi@2026!',
    'admin@sakopi.com': 'Sakopi@2026!',
    'owner@sakopi.com': 'Sakopi@2026!',
  };

  static final List<UserProfile> users = [
    UserProfile(
      id: '11111111-1111-1111-1111-111111111111',
      email: 'owner@sakopi.com',
      role: 'owner',
      name: 'Evan Maulana (Owner)',
    ),
    UserProfile(
      id: '22222222-2222-2222-2222-222222222222',
      email: 'admin@sakopi.com',
      role: 'admin',
      name: 'Admin Operasional',
    ),
    UserProfile(
      id: '33333333-3333-3333-3333-333333333333',
      email: 'kasir@sakopi.com',
      role: 'kasir',
      name: 'Kasir Sakopi',
    ),
  ];

  static final List<Category> categories = [
    Category(id: 1, name: 'Kopi'),
    Category(id: 2, name: 'Non-Kopi'),
    Category(id: 3, name: 'Makanan'),
  ];

  static final List<Product> products = [
    Product(
      id: 1,
      categoryId: 1,
      name: 'Kopi Susu Gula Aren',
      price: 18000,
      imageUrl: 'https://placehold.co/150/155e75/FFFFFF?text=Kopi+Susu',
      isAvailable: true,
    ),
    Product(
      id: 2,
      categoryId: 1,
      name: 'Americano',
      price: 15000,
      imageUrl: 'https://placehold.co/150/155e75/FFFFFF?text=Americano',
      isAvailable: true,
    ),
    Product(
      id: 3,
      categoryId: 2,
      name: 'Red Velvet Latte',
      price: 20000,
      imageUrl: 'https://placehold.co/150/991b1b/FFFFFF?text=Red+Velvet',
      isAvailable: true,
    ),
    Product(
      id: 4,
      categoryId: 2,
      name: 'Matcha Latte',
      price: 22000,
      imageUrl: 'https://placehold.co/150/166534/FFFFFF?text=Matcha',
      isAvailable: true,
    ),
    Product(
      id: 5,
      categoryId: 3,
      name: 'Roti Panggang Coklat',
      price: 12000,
      imageUrl: 'https://placehold.co/150/854d0e/FFFFFF?text=Ropang',
      isAvailable: true,
    ),
  ];

  static final List<Map<String, dynamic>> transactions = [
    {
      'id': 'a1b2c3d4-1111-4444-8888-000000000001',
      'cashier_id': '33333333-3333-3333-3333-333333333333',
      'total_amount': 54000.0,
      'payment_method': 'Tunai',
      'status': 'Selesai',
      'created_at': DateTime.now().subtract(const Duration(hours: 3)).toUtc().toIso8601String(),
      'users_profile': {'name': 'Kasir Sakopi'},
    },
    {
      'id': 'b2c3d4e5-2222-4444-8888-000000000002',
      'cashier_id': '33333333-3333-3333-3333-333333333333',
      'total_amount': 42000.0,
      'payment_method': 'Non-Tunai',
      'status': 'Selesai',
      'created_at': DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String(),
      'users_profile': {'name': 'Kasir Sakopi'},
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> transactionItemsByTxId = {
    'a1b2c3d4-1111-4444-8888-000000000001': [
      {
        'quantity': 2,
        'price_at_time': 18000.0,
        'products': {'name': 'Kopi Susu Gula Aren'},
      },
      {
        'quantity': 1,
        'price_at_time': 18000.0,
        'products': {'name': 'Americano'},
      },
    ],
    'b2c3d4e5-2222-4444-8888-000000000002': [
      {
        'quantity': 1,
        'price_at_time': 22000.0,
        'products': {'name': 'Matcha Latte'},
      },
      {
        'quantity': 1,
        'price_at_time': 20000.0,
        'products': {'name': 'Red Velvet Latte'},
      },
    ],
  };

  static final List<Expense> expenses = [
    Expense(
      id: 1,
      amount: 25000,
      description: 'Pembelian Susu UHT & Gula Aren',
      expenseDate: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static bool isNetworkOrFetchError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('failed to fetch') ||
        msg.contains('clientexception') ||
        msg.contains('socketexception') ||
        msg.contains('xmlhttprequest error') ||
        msg.contains('network');
  }

  static UserProfile authenticate(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final idx = users.indexWhere((u) => u.email.toLowerCase() == cleanEmail);
    if (idx < 0) {
      throw Exception('Email belum terdaftar. Silakan daftar melalui menu Daftar Sekarang.');
    }

    final expectedPwd = _passwordsByEmail[cleanEmail];
    // Izinkan password terdaftar atau password demo standar ('password123' / 'Sakopi@2026!')
    if (password != expectedPwd && password != 'password123' && password != 'Sakopi@2026!') {
      throw Exception('Email atau password salah.');
    }

    currentUser = users[idx];
    return currentUser!;
  }

  static UserProfile registerUser({
    required String name,
    required String email,
    required String password,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final existing = users.any((u) => u.email.toLowerCase() == cleanEmail);
    if (existing) {
      throw Exception('Email "$cleanEmail" sudah terdaftar. Silakan langsung masuk.');
    }

    final newProfile = UserProfile(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      role: 'kasir',
      name: name.trim(),
    );

    users.add(newProfile);
    _passwordsByEmail[cleanEmail] = password;
    currentUser = newProfile;
    return newProfile;
  }

  static void recordTransaction({
    required String transactionId,
    required String cashierId,
    required List<CartItem> items,
    required String paymentMethod,
    required double totalAmount,
  }) {
    final cashier = users.firstWhere(
      (u) => u.id == cashierId,
      orElse: () => currentUser ?? users.last,
    );

    transactions.insert(0, {
      'id': transactionId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': 'Diproses',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'users_profile': {'name': cashier.name},
    });

    transactionItemsByTxId[transactionId] = items
        .map((item) => {
              'quantity': item.quantity,
              'price_at_time': item.product.price,
              'products': {'name': item.product.name},
            })
        .toList();
  }
}
