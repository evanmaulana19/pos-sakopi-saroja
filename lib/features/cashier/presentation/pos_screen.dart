import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/security_audit_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/cart_item_model.dart';
import '../data/cashier_providers.dart';
import 'cashier_controller.dart';

class PosScreen extends ConsumerStatefulWidget {
  final String initialSearchQuery;

  const PosScreen({super.key, this.initialSearchQuery = ''});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  int _currentIndex = 0;
  String _paymentMethod = 'Tunai';
  late final TextEditingController _searchController;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    if (widget.initialSearchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).setQuery(widget.initialSearchQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String rawValue) {
    final validationErr = SecurityUtils.validateSafeText(
      rawValue,
      fieldName: 'Pencarian Menu',
      maxLength: 80,
      allowEmpty: true,
    );
    if (validationErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErr),
          backgroundColor: AppColors.softRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      final cleaned = SecurityUtils.sanitizeInput(rawValue);
      _searchController.text = cleaned;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
      ref.read(searchQueryProvider.notifier).setQuery(cleaned);
      setState(() {});
      return;
    }
    ref.read(searchQueryProvider.notifier).setQuery(rawValue.trim());
    setState(() {});
  }

  Future<Uint8List> _generateReceiptPdf({
    required String transactionId,
    required List<CartItem> items,
    required double totalAmount,
    required String paymentMethod,
    required String cashierName,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SAKOPI SAROJA',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Struk Pembayaran Resmi',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Text(
                'Order ID : #${transactionId.substring(0, 8)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text('Tanggal  : $dateStr', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Kasir    : $cashierName', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Metode   : $paymentMethod', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}x ${item.product.name}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Text(
                        currencyFormatter.format(item.totalPrice),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    currencyFormatter.format(totalAmount),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Terima kasih atas kunjungan Anda!',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final cart = ref.watch(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.lightBeige,
        body: Row(
          children: [
            _buildDesktopSidebar(),
            Expanded(
              child: _currentIndex == 0
                  ? _buildPosBody(isDesktop: true)
                  : _buildQueueBody(isDesktop: true),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildPosBody(isDesktop: false)
            : _buildQueueBody(isDesktop: false),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showMobileCart,
              backgroundColor: AppColors.darkGreen,
              foregroundColor: AppColors.goldenTan,
              elevation: 4,
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text(
                '${cart.length} Item • ${currencyFormatter.format(subtotal)}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppColors.white,
          elevation: 0,
          onTap: (index) {
            if (index == 2) {
              ref.read(authControllerProvider.notifier).logout();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          selectedItemColor: AppColors.darkGreen,
          unselectedItemColor: AppColors.darkGray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_rounded),
              label: 'Kasir POS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Antrean',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded, color: AppColors.softRed),
              label: 'Keluar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final user = ref.watch(authControllerProvider).value;

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldenTan,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: AppColors.darkGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sakopi Saroja',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'TERMINAL KASIR',
                      style: TextStyle(
                        color: AppColors.goldenTan,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSidebarNavItem(
            index: 0,
            icon: Icons.grid_view_rounded,
            label: 'Katalog & Kasir',
          ),
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            index: 1,
            icon: Icons.receipt_long_rounded,
            label: 'Antrean Pesanan',
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => SecurityAuditDialog.show(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.goldenTan, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Security Log',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Active User Profile Card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.goldenTan,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'K',
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.goldenTan,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.softRed,
              side: BorderSide(color: AppColors.softRed.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.softRed),
            label: const Text(
              'Keluar Sesi',
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldenTan : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.darkGreen : AppColors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.darkGreen : AppColors.white,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosBody({required bool isDesktop}) {
    final user = ref.watch(authControllerProvider).value;
    final todayStr = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now());

    final menuContent = Container(
      color: AppColors.lightBeige,
      padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Menu Kedai',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: isDesktop ? 26 : 20,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? '$todayStr • Kasir Aktif: ${user.name}'
                          : todayStr,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.darkGray),
                    ),
                  ],
                ),
              ),
              if (!isDesktop)
                IconButton(
                  tooltip: 'Security Audit Log',
                  icon: const Icon(Icons.shield_outlined, color: AppColors.darkGreen),
                  onPressed: () => SecurityAuditDialog.show(context),
                ),
            ],
          ),
          const SizedBox(height: 18),
          // Modern Search Bar with Security Indicator
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kopi, matcha, atau cemilan favorit...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).setQuery('');
                          setState(() {});
                        },
                      )
                    : Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightBeige,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 13,
                              color: AppColors.darkGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Anti-XSS/SQLi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          _buildCategoryTabs(),
          const SizedBox(height: 18),
          // Products Grid
          Expanded(
            child: _buildProductsGrid(),
          ),
          if (!isDesktop) const SizedBox(height: 76),
        ],
      ),
    );

    final cartContent = Container(
      width: 390,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          left: BorderSide(color: AppColors.lightGray.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildCartList(),
          ),
          const Divider(height: 24),
          _buildCartSummary(),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: menuContent),
          cartContent,
        ],
      );
    } else {
      return menuContent;
    }
  }

  Widget _buildCartHeader() {
    final cart = ref.watch(cartProvider);
    final totalQty = cart.fold<int>(0, (sum, item) => sum + item.quantity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.darkGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Saat Ini',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                Text(
                  '$totalQty item dipilih',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                ),
              ],
            ),
          ],
        ),
        if (cart.isNotEmpty)
          TextButton.icon(
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
            icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.softRed),
            label: const Text(
              'Reset',
              style: TextStyle(color: AppColors.softRed, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _showMobileCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildCartHeader()),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildCartList(),
                  ),
                  const Divider(),
                  _buildCartSummary(isMobileBottomSheet: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      data: (categories) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTab(
                'Semua Menu',
                icon: Icons.restaurant_menu_rounded,
                isSelected: selectedCategory == null,
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).selectCategory(null);
                },
              ),
              ...categories.map(
                (c) => _buildTab(
                  c.name,
                  icon: c.name.toLowerCase().contains('kopi')
                      ? Icons.local_cafe_rounded
                      : Icons.bakery_dining_rounded,
                  isSelected: selectedCategory == c.id,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).selectCategory(c.id);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading categories: $e'),
    );
  }

  Widget _buildTab(
    String title, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkGreen : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.darkGreen : AppColors.lightGray,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.darkGreen.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.goldenTan : AppColors.darkGray,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.charcoal,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.darkGray.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tidak ada menu yang cocok dengan filter pencarian.',
                  style: TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }
        return LayoutBuilder(builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 175).floor();
          if (crossAxisCount < 2) crossAxisCount = 2;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.76,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                title: product.name,
                price: product.price,
                imageUrl: product.imageUrl,
                isAvailable: product.isAvailable,
                onTap: () {
                  ref.read(cartProvider.notifier).addProduct(product);
                },
              );
            },
          );
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading products: $e'),
    );
  }

  Widget _buildCartList() {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.lightBeige,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_cafe_outlined,
                size: 40,
                color: AppColors.darkGreen.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Keranjang Pesanan Kosong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Klik menu di sebelah kiri untuk menambahkan pesanan.',
              style: TextStyle(fontSize: 12, color: AppColors.darkGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: cart.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = cart[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightBeige,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.product.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.darkGreen,
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: AppColors.goldenTan,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(item.totalPrice),
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Modern Capsule Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.remove_rounded, size: 16, color: AppColors.darkGreen),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(cartProvider.notifier).addProduct(item.product),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.add_rounded, size: 16, color: AppColors.darkGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartSummary({bool isMobileBottomSheet = false}) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightBeige,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal Pesanan', style: TextStyle(fontSize: 13)),
                  Text(
                    currencyFormatter.format(subtotal),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pajak Layanan (0%)', style: TextStyle(fontSize: 13)),
                  Text(
                    currencyFormatter.format(0),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.charcoal),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodOption(
                title: 'Tunai',
                icon: Icons.payments_outlined,
                isSelected: _paymentMethod == 'Tunai',
                onTap: () => setState(() => _paymentMethod = 'Tunai'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentMethodOption(
                title: 'Non-Tunai',
                icon: Icons.qr_code_scanner_rounded,
                isSelected: _paymentMethod == 'Non-Tunai',
                onTap: () => setState(() => _paymentMethod = 'Non-Tunai'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: 'Bayar Sekarang',
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: cart.isEmpty ? AppColors.lightGray : AppColors.goldenTan,
          foregroundColor: AppColors.darkGreen,
          onPressed: cart.isEmpty
              ? null
              : () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final user = ref.read(authControllerProvider).value;
                    if (user == null) {
                      throw Exception('User belum login');
                    }

                    final itemsSnapshot = List<CartItem>.from(cart);
                    final methodSnapshot = _paymentMethod;

                    final txId = await ref.read(cashierRepositoryProvider).submitTransaction(
                          cashierId: user.id,
                          items: itemsSnapshot,
                          paymentMethod: methodSnapshot,
                          totalAmount: subtotal,
                        );

                    if (mounted) Navigator.pop(context);

                    if (isMobileBottomSheet && mounted) {
                      Navigator.pop(context);
                    }

                    if (mounted) {
                      _showSuccessDialog(
                        context: context,
                        transactionId: txId,
                        items: itemsSnapshot,
                        totalAmount: subtotal,
                        paymentMethod: methodSnapshot,
                        cashierName: user.name,
                      );
                    }

                    ref.read(cartProvider.notifier).clearCart();
                    ref.invalidate(queueProvider);
                  } catch (e) {
                    if (mounted) Navigator.pop(context);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal: $e'),
                          backgroundColor: AppColors.softRed,
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.darkGreen : AppColors.lightGray,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? AppColors.goldenTan : AppColors.darkGray,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? AppColors.white : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required BuildContext context,
    required String transactionId,
    required List<CartItem> items,
    required double totalAmount,
    required String paymentMethod,
    required String cashierName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.darkGreen,
                  size: 56,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pembayaran Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #${transactionId.substring(0, 8)} • $paymentMethod',
                style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currencyFormatter.format(totalAmount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final pdfBytes = await _generateReceiptPdf(
                  transactionId: transactionId,
                  items: items,
                  totalAmount: totalAmount,
                  paymentMethod: paymentMethod,
                  cashierName: cashierName,
                );
                await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Cetak Struk PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueBody({required bool isDesktop}) {
    final queueAsync = ref.watch(queueProvider);

    return Container(
      color: AppColors.lightBeige,
      padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antrean Pesanan Hari Ini',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: isDesktop ? 26 : 20,
                        ),
                  ),
                  const Text(
                    'Pantau dan selesaikan pesanan pelanggan yang sedang diproses.',
                    style: TextStyle(fontSize: 13, color: AppColors.darkGray),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(queueProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Segarkan'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: queueAsync.when(
              data: (queue) {
                if (queue.isEmpty) {
                  return const Center(
                    child: Text('Belum ada antrean transaksi hari ini.'),
                  );
                }
                return ListView.separated(
                  itemCount: queue.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = queue[index];
                    final isDiproses = tx['status'] == 'Diproses';

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDiproses
                              ? AppColors.goldenTan
                              : AppColors.lightGray.withValues(alpha: 0.7),
                          width: isDiproses ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDiproses
                                  ? AppColors.goldenTan.withValues(alpha: 0.25)
                                  : AppColors.darkGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isDiproses
                                  ? Icons.schedule_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: AppColors.darkGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Order #${tx['id'].toString().substring(0, 8)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.charcoal,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDiproses
                                            ? AppColors.goldenTan
                                            : AppColors.darkGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tx['status'].toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Metode: ${tx['payment_method']} • Total: ${currencyFormatter.format(tx['total_amount'])}',
                                  style: const TextStyle(
                                    color: AppColors.darkGray,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDiproses)
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(cashierRepositoryProvider)
                                      .updateTransactionStatus(tx['id'], 'Selesai');
                                  ref.invalidate(queueProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pesanan berhasil diselesaikan!'),
                                        backgroundColor: AppColors.darkGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppColors.softRed,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.done_all_rounded, size: 18),
                              label: const Text('Selesaikan'),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.verified_rounded,
                                color: AppColors.darkGreen,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
