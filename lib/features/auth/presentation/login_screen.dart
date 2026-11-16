import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/security_audit_dialog.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCooldownWatcher() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final notifier = ref.read(authControllerProvider.notifier);
      setState(() {});
      if (!notifier.isLockedOut) {
        timer.cancel();
      }
    });
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      _startCooldownWatcher();
    }
  }

  void _fillDemoEmail(String email) {
    setState(() {
      _emailController.text = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      authControllerProvider,
      (_, state) {
        if (!state.isLoading && state.hasError) {
          final notifier = ref.read(authControllerProvider.notifier);
          if (notifier.isLockedOut) {
            _startCooldownWatcher();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: AppColors.softRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final isLoading = authState.isLoading;
    final isLockedOut = authNotifier.isLockedOut;
    final remainingSeconds = authNotifier.remainingLockoutSeconds;
    final isWide = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      body: Stack(
        children: [
          // Ambient Decorative Background Circles
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldenTan.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkGreen.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Top Security Audit Pill Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: OutlinedButton.icon(
                  onPressed: () => SecurityAuditDialog.show(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.9),
                    side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.shield_outlined, color: AppColors.darkGreen, size: 18),
                  label: const Text(
                    'Security Audit Log',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Main Content Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 920 : 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isWide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: _buildHeroBrandingPanel()),
                              Expanded(
                                flex: 6,
                                child: _buildFormPanel(isLoading, isLockedOut, remainingSeconds),
                              ),
                            ],
                          ),
                        )
                      : _buildFormPanel(isLoading, isLockedOut, remainingSeconds),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBrandingPanel() {
    return Container(
      padding: const EdgeInsets.all(40.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkGreen,
            Color(0xFF1F2B23),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldenTan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldenTan.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.goldenTan, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'SECURED CLOUD POS',
                      style: TextStyle(
                        color: AppColors.goldenTan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.goldenTan,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.coffee_rounded,
                  color: AppColors.darkGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sakopi Saroja\nPoint of Sale',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sistem manajemen transaksi kasir, inventori menu, dan analitik keuangan kedai kopi berbasis cloud dengan proteksi keamanan berlapis.',
                style: TextStyle(
                  color: AppColors.lightBeige.withValues(alpha: 0.8),
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standar Keamanan Aktif:',
                  style: TextStyle(
                    color: AppColors.goldenTan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                _SecurityFeatureItem(text: 'Bcrypt Password Hashing & JWT Session'),
                SizedBox(height: 4),
                _SecurityFeatureItem(text: 'Validasi & Sanitasi Input (Anti-SQLi & XSS)'),
                SizedBox(height: 4),
                _SecurityFeatureItem(text: 'RBAC Route Guard & Row Level Security'),
                SizedBox(height: 4),
                _SecurityFeatureItem(text: 'Brute-Force Login Rate Limiter (5x/60s)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(bool isLoading, bool isLockedOut, int remainingSeconds) {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBeige,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.goldenTan),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.darkGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Masuk ke dashboard operasional sesuai peran Anda',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLockedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.softRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off_outlined, color: AppColors.softRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Proteksi Brute-Force Aktif!\nTerlalu banyak percobaan gagal. Silakan tunggu $remainingSeconds detik.',
                        style: const TextStyle(
                          color: AppColors.softRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailController,
              enabled: !isLockedOut && !isLoading,
              decoration: const InputDecoration(
                labelText: 'Alamat Email',
                hintText: 'nama@sakopi.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: SecurityUtils.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !isLockedOut && !isLoading,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                hintText: 'Masukkan kata sandi Anda',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              onFieldSubmitted: (_) => _onLogin(),
              validator: SecurityUtils.validateLoginPassword,
            ),
            const SizedBox(height: 14),
            // Quick Fill Demo Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pintasan Email Akun Uji (Klik untuk isi cepat):',
                    style: TextStyle(fontSize: 11, color: AppColors.darkGray, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildQuickRoleChip('Kasir', 'kasir@sakopi.com', Icons.point_of_sale_rounded),
                      _buildQuickRoleChip('Admin', 'admin@sakopi.com', Icons.inventory_2_outlined),
                      _buildQuickRoleChip('Owner', 'owner@sakopi.com', Icons.analytics_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: isLockedOut ? 'Terkunci ($remainingSeconds dtk)' : 'Masuk ke Sistem',
              icon: isLockedOut ? Icons.lock_clock : Icons.login_rounded,
              isLoading: isLoading,
              onPressed: (isLoading || isLockedOut) ? null : _onLogin,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun staf?',
                  style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => context.go('/register'),
                  child: const Text(
                    'Daftar Sekarang',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRoleChip(String label, String email, IconData icon) {
    final isSelected = _emailController.text.trim().toLowerCase() == email;
    return InkWell(
      onTap: () => _fillDemoEmail(email),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkGreen : AppColors.lightGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.goldenTan : AppColors.darkGreen,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.darkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityFeatureItem extends StatelessWidget {
  final String text;
  const _SecurityFeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.goldenTan, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.white, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}
