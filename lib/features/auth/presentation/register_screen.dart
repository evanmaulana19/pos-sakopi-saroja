import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/security_audit_dialog.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _currentPassword = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi berhasil! Akun Anda telah dibuat dengan aman.'),
            backgroundColor: AppColors.darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        final user = ref.read(authControllerProvider).value;
        if (user == null) {
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      authControllerProvider,
      (_, state) {
        if (!state.isLoading && state.hasError) {
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
    final isLoading = authState.isLoading;
    final strength = SecurityUtils.calculatePasswordStrength(_currentPassword);

    Color strengthColor = AppColors.softRed;
    String strengthLabel = 'Lemah';
    if (strength >= 0.85) {
      strengthColor = AppColors.darkGreen;
      strengthLabel = 'Kuat (Aman)';
    } else if (strength >= 0.55) {
      strengthColor = Colors.orange.shade800;
      strengthLabel = 'Sedang';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldenTan.withValues(alpha: 0.25),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Kembali'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => SecurityAuditDialog.show(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Security Log'),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(34.0),
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
                                color: AppColors.darkGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.goldenTan,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registrasi Akun Baru',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(fontSize: 22),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pendaftaran staf operasional Sakopi Saroja',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightBeige,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.goldenTan),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_outlined, size: 18, color: AppColors.darkGreen),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Proteksi RBAC: Akun baru otomatis terdaftar dengan role standar "Kasir". Peningkatan akses ke Admin/Owner dikelola oleh Owner.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.charcoal, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Contoh: Budi Santoso',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (val) => SecurityUtils.validateSafeText(
                            val,
                            fieldName: 'Nama Lengkap',
                            minLength: 3,
                            maxLength: 80,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Email',
                            hintText: 'nama@sakopi.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: SecurityUtils.validateEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          onChanged: (val) => setState(() => _currentPassword = val),
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Kuat',
                            hintText: 'Min. 8 karakter (A-Z, a-z, 0-9, Simbol)',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: SecurityUtils.validateStrongPassword,
                        ),
                        if (_currentPassword.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBeige,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Indikator Kekuatan Sandi:',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      strengthLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: strengthColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: strength,
                                    minHeight: 7,
                                    backgroundColor: AppColors.lightGray,
                                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildRequirementRow(
                                  'Minimal 8 karakter',
                                  _currentPassword.length >= 8,
                                ),
                                _buildRequirementRow(
                                  'Huruf besar (A-Z) & huruf kecil (a-z)',
                                  RegExp(r'[A-Z]').hasMatch(_currentPassword) &&
                                      RegExp(r'[a-z]').hasMatch(_currentPassword),
                                ),
                                _buildRequirementRow(
                                  'Mengandung angka (0-9)',
                                  RegExp(r'[0-9]').hasMatch(_currentPassword),
                                ),
                                _buildRequirementRow(
                                  'Mengandung simbol (!@#\$%^&* dll)',
                                  RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]')
                                      .hasMatch(_currentPassword),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (val != _passwordController.text) {
                              return 'Konfirmasi password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Buat Akun Sekarang',
                          icon: Icons.how_to_reg_rounded,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _onRegister,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun?',
                              style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: isLoading ? null : () => context.go('/login'),
                              child: const Text(
                                'Masuk di sini',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet ? AppColors.darkGreen : AppColors.darkGray,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              color: isMet ? AppColors.darkGreen : AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
