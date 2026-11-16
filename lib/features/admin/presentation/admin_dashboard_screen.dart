import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/security_audit_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cashier/domain/product_model.dart';
import '../data/admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.lightBeige,
        body: Row(
          children: [
            _buildDesktopSidebar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.coffee_rounded, color: AppColors.goldenTan, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_getAppBarTitle(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Security Audit & Activity Log',
            icon: const Icon(Icons.shield_outlined, color: AppColors.darkGreen),
            onPressed: () => SecurityAuditDialog.show(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.white,
        onTap: (index) {
          if (index == 3) {
            ref.read(authControllerProvider.notifier).logout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.darkGray,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline_rounded), label: 'Ringkasan'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Transaksi'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded, color: AppColors.softRed),
            label: 'Keluar',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final user = ref.watch(authControllerProvider).value;

    return Container(
      width: 240,
      color: AppColors.darkGreen,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldenTan,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.coffee_rounded, color: AppColors.darkGreen, size: 26),
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
                      'PANEL ADMIN TOKO',
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
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Ringkasan Operasional'),
          const SizedBox(height: 8),
          _buildSidebarItem(1, Icons.restaurant_menu_rounded, 'Manajemen Menu'),
          const SizedBox(height: 8),
          _buildSidebarItem(2, Icons.receipt_long_rounded, 'Riwayat Transaksi'),
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
                      'Security Audit Log',
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
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
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
            label: const Text('Keluar Sesi', style: TextStyle(color: AppColors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Admin - Ringkasan';
      case 1:
        return 'Admin - Menu';
      case 2:
        return 'Admin - Transaksi';
      default:
        return 'Admin';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildSummary();
      case 1:
        return _buildMenuManagement();
      case 2:
        return _buildTransactions();
      default:
        return _buildSummary();
    }
  }

  Widget _buildSummary() {
    final summaryAsync = ref.watch(adminSummaryProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return summaryAsync.when(
      data: (summary) {
        return ListView(
          children: [
            // Modern Hero Welcome Banner
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkGreen, Color(0xFF1F2B23)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldenTan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'RINGKASAN OPERASIONAL HARI INI',
                            style: TextStyle(
                              color: AppColors.goldenTan,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kelola Ketersediaan Menu & Pantau Transaksi Kasir',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pastikan seluruh stok menu kopi dan makanan selalu diperbarui secara real-time.',
                          style: TextStyle(
                            color: AppColors.lightBeige.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.goldenTan,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.darkGreen,
                        size: 42,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Menu Aktif',
                      summary.totalActiveMenu.toString(),
                      'Menu siap dipesan',
                      Icons.inventory_2_rounded,
                      AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Stok Menu Habis',
                      summary.totalOutOfStock.toString(),
                      'Perlu restock segera',
                      Icons.warning_amber_rounded,
                      AppColors.softRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Transaksi Hari Ini',
                      summary.todayTransactions.toString(),
                      'Pesanan tercatat',
                      Icons.receipt_long_rounded,
                      AppColors.darkGreen,
                    ),
                  ),
                ],
              )
            else ...[
              _buildStatCard(
                'Total Menu Aktif',
                summary.totalActiveMenu.toString(),
                'Menu siap dipesan',
                Icons.inventory_2_rounded,
                AppColors.darkGreen,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Stok Menu Habis',
                summary.totalOutOfStock.toString(),
                'Perlu restock segera',
                Icons.warning_amber_rounded,
                AppColors.softRed,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Transaksi Hari Ini',
                summary.todayTransactions.toString(),
                'Pesanan tercatat',
                Icons.receipt_long_rounded,
                AppColors.darkGreen,
              ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Pintasan Operasional Cepat',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isWide ? 240 : double.infinity,
                  child: PrimaryButton(
                    text: 'Kelola & Tambah Menu',
                    icon: Icons.add_business_rounded,
                    backgroundColor: AppColors.goldenTan,
                    foregroundColor: AppColors.darkGreen,
                    onPressed: () => setState(() => _currentIndex = 1),
                  ),
                ),
                SizedBox(
                  width: isWide ? 240 : double.infinity,
                  child: PrimaryButton(
                    text: 'Pantau Transaksi Kasir',
                    icon: Icons.visibility_outlined,
                    onPressed: () => setState(() => _currentIndex = 2),
                  ),
                ),
                SizedBox(
                  width: isWide ? 240 : double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shield_outlined, color: AppColors.darkGreen),
                    label: const Text('Security Audit Log'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => SecurityAuditDialog.show(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor == AppColors.softRed
                  ? AppColors.softRed.withValues(alpha: 0.12)
                  : AppColors.lightBeige,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    color: accentColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.darkGray, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductForm({Product? product}) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product != null ? product.price.toInt().toString() : '',
    );
    final imageCtrl = TextEditingController(
      text: product?.imageUrl ?? 'https://placehold.co/150/155e75/FFFFFF?text=Menu+Sakopi',
    );
    int categoryId = product?.categoryId ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Menu Kedai' : 'Tambah Menu Baru',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                        prefixIcon: Icon(Icons.local_cafe_outlined),
                      ),
                      validator: (val) => SecurityUtils.validateSafeText(
                        val,
                        fieldName: 'Nama Produk',
                        minLength: 2,
                        maxLength: 100,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => SecurityUtils.validatePositiveNumber(
                        val,
                        fieldName: 'Harga Produk',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar (https://...)',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      validator: (val) => SecurityUtils.validateSafeUrl(
                        val,
                        fieldName: 'URL Gambar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Menu',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Kopi')),
                        DropdownMenuItem(value: 2, child: Text('Non-Kopi')),
                        DropdownMenuItem(value: 3, child: Text('Makanan')),
                      ],
                      onChanged: (val) {
                        if (val != null) categoryId = val;
                      },
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: isEditing ? 'Simpan Perubahan' : 'Tambahkan Menu',
                      icon: Icons.save_outlined,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final newProduct = Product(
                          id: product?.id ?? 0,
                          categoryId: categoryId,
                          name: SecurityUtils.sanitizeInput(nameCtrl.text),
                          price: double.parse(priceCtrl.text.trim()),
                          imageUrl: imageCtrl.text.trim(),
                          isAvailable: product?.isAvailable ?? true,
                        );

                        try {
                          if (isEditing) {
                            await ref.read(adminRepositoryProvider).updateProduct(newProduct);
                          } else {
                            await ref.read(adminRepositoryProvider).addProduct(newProduct);
                          }
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          ref.invalidate(allProductsProvider);
                          ref.invalidate(adminSummaryProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Menu berhasil diperbarui!'
                                      : 'Menu baru berhasil ditambahkan!',
                                ),
                                backgroundColor: AppColors.darkGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.softRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Anda yakin ingin menghapus "${product.name}" dari daftar menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softRed),
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteProduct(product.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                ref.invalidate(allProductsProvider);
                ref.invalidate(adminSummaryProvider);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuManagement() {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      data: (products) {
        return ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Katalog Menu',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      ),
                      const Text(
                        'Tambah, ubah harga, atau atur status stok menu (Dilindungi Anti-XSS & SQLi).',
                        style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    text: '+ Menu Baru',
                    backgroundColor: AppColors.goldenTan,
                    foregroundColor: AppColors.darkGreen,
                    onPressed: () => _showProductForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...products.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        p.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.darkGreen,
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: AppColors.goldenTan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(p.price),
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.isAvailable
                                ? AppColors.darkGreen.withValues(alpha: 0.08)
                                : AppColors.softRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: p.isAvailable,
                                onChanged: (val) async {
                                  await ref
                                      .read(adminRepositoryProvider)
                                      .toggleProductAvailability(p.id, val);
                                  ref.invalidate(allProductsProvider);
                                  ref.invalidate(adminSummaryProvider);
                                },
                                activeThumbColor: AppColors.darkGreen,
                              ),
                              Text(
                                p.isAvailable ? 'Tersedia' : 'Habis',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.isAvailable ? AppColors.darkGreen : AppColors.softRed,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Edit Menu',
                          icon: const Icon(Icons.edit_outlined, color: AppColors.darkGreen),
                          onPressed: () => _showProductForm(product: p),
                        ),
                        IconButton(
                          tooltip: 'Hapus Menu',
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softRed),
                          onPressed: () => _deleteProduct(p),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTransactions() {
    final txAsync = ref.watch(recentTransactionsProvider);

    return txAsync.when(
      data: (transactions) {
        return ListView(
          children: [
            Text(
              'Riwayat Transaksi Kasir',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
            ),
            const Text(
              'Pantau 100 transaksi terakhir yang tercatat di seluruh kasir.',
              style: TextStyle(color: AppColors.darkGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ...transactions.map((tx) {
              final date = DateTime.parse(tx['created_at']);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
              final kasirName =
                  tx['users_profile'] != null ? tx['users_profile']['name'] : 'Kasir';
              final isSelesai = tx['status'] == 'Selesai';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${tx['id'].toString().substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelesai
                                    ? AppColors.darkGreen.withValues(alpha: 0.12)
                                    : AppColors.goldenTan,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tx['status'],
                                style: const TextStyle(
                                  color: AppColors.darkGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$formattedDate • Kasir: $kasirName • ${tx['payment_method']}',
                          style: const TextStyle(color: AppColors.darkGray, fontSize: 12.5),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          currencyFormatter.format(tx['total_amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('Rincian'),
                          onPressed: () async {
                            try {
                              final items = await ref
                                  .read(adminRepositoryProvider)
                                  .getTransactionItems(tx['id']);
                              if (!mounted) return;

                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    'Detail Transaksi #${tx['id'].toString().substring(0, 8)}',
                                  ),
                                  content: SizedBox(
                                    width: 400,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: items.length,
                                      itemBuilder: (ctx, i) {
                                        final item = items[i];
                                        final name = item['products'] != null
                                            ? item['products']['name']
                                            : 'Menu';
                                        return ListTile(
                                          title: Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            '${item['quantity']}x ${currencyFormatter.format(item['price_at_time'])}',
                                          ),
                                          trailing: Text(
                                            currencyFormatter.format(
                                              item['quantity'] * item['price_at_time'],
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkGreen,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
