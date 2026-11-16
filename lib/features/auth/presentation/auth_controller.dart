import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/security_audit_logger.dart';
import '../domain/user_profile_model.dart';
import '../data/auth_providers.dart';

class AuthController extends AsyncNotifier<UserProfile?> {
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 60);

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  int get failedAttempts => _failedAttempts;
  DateTime? get lockoutUntil => _lockoutUntil;

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get remainingLockoutSeconds {
    if (!isLockedOut || _lockoutUntil == null) return 0;
    return _lockoutUntil!.difference(DateTime.now()).inSeconds.clamp(1, 60);
  }

  @override
  Future<UserProfile?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    // 1. Cek Rate Limiting / Brute-Force Lockout
    if (isLockedOut) {
      final secs = remainingLockoutSeconds;
      SecurityAuditLogger.log(
        eventType: 'AUTH_RATE_LIMIT_BLOCKED',
        severity: SecuritySeverity.critical,
        actor: email,
        description: 'Percobaan login ditolak oleh Rate Limiter (Masih terkunci $secs detik).',
      );
      state = AsyncValue.error(
        'Terlalu banyak percobaan login gagal (Rate Limit). Silakan tunggu $secs detik lagi.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email, password);
      // Reset counter jika berhasil login
      _failedAttempts = 0;
      _lockoutUntil = null;
      state = AsyncValue.data(user);
    } catch (e, st) {
      _failedAttempts++;
      if (_failedAttempts >= maxFailedAttempts) {
        _lockoutUntil = DateTime.now().add(lockoutDuration);
        SecurityAuditLogger.log(
          eventType: 'AUTH_BRUTEFORCE_LOCKOUT',
          severity: SecuritySeverity.critical,
          actor: email,
          description: 'Akun/IP dikunci sementara selama ${lockoutDuration.inSeconds} detik setelah $_failedAttempts kali gagal login.',
        );
        state = AsyncValue.error(
          'Batas percobaan login terlampaui ($maxFailedAttempts kali gagal). Login dikunci selama ${lockoutDuration.inSeconds} detik!',
          st,
        );
      } else {
        final remainingTries = maxFailedAttempts - _failedAttempts;
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        state = AsyncValue.error(
          '$cleanMsg (Sisa percobaan sebelum terkunci: $remainingTries kali)',
          st,
        );
      }
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.register(
        name: name,
        email: email,
        password: password,
      );
      // Jika sesi langsung aktif setelah signUp, set user; jika butuh verifikasi/login, arahkan ke login
      final currentUser = await repo.getCurrentUser();
      state = AsyncValue.data(currentUser ?? profile);
      return true;
    } catch (e, st) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      state = AsyncValue.error(cleanMsg, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
      return null;
    });
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserProfile?>(
  () => AuthController(),
);
