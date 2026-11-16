import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/local_fallback_store.dart';
import '../../../core/utils/security_audit_logger.dart';
import '../../../core/utils/security_utils.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile_model.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<UserProfile> login(String email, String password) async {
    final emailErr = SecurityUtils.validateEmail(email);
    if (emailErr != null) {
      throw Exception(emailErr);
    }
    final pwdErr = SecurityUtils.validateLoginPassword(password);
    if (pwdErr != null) {
      throw Exception(pwdErr);
    }

    final cleanEmail = SecurityUtils.sanitizeInput(email).toLowerCase();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      if (response.user == null || response.session == null) {
        throw Exception('Autentikasi gagal: Sesi tidak ditemukan.');
      }

      final profile = await _fetchOrCreateUserProfile(response.user!);
      LocalFallbackStore.currentUser = profile;

      SecurityAuditLogger.log(
        eventType: 'AUTH_LOGIN_SUCCESS',
        severity: SecuritySeverity.info,
        actor: cleanEmail,
        description: 'Login berhasil dengan role "${profile.role}". Token JWT diterbitkan.',
      );

      return profile;
    } on AuthException catch (e) {
      SecurityAuditLogger.log(
        eventType: 'AUTH_LOGIN_FAILED',
        severity: SecuritySeverity.warning,
        actor: cleanEmail,
        description: 'Percobaan login gagal: ${e.message}',
      );
      throw Exception('Email atau password salah (${e.message})');
    } catch (e) {
      // Jika Supabase Cloud sedang Pause (Failed to fetch), gunakan Fallback Store
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        try {
          final fallbackUser = LocalFallbackStore.authenticate(cleanEmail, password);
          SecurityAuditLogger.log(
            eventType: 'AUTH_LOGIN_SUCCESS',
            severity: SecuritySeverity.info,
            actor: cleanEmail,
            description:
                'Login berhasil (Mode Resilient Fallback) untuk "${fallbackUser.name}" dengan role "${fallbackUser.role}".',
          );
          return fallbackUser;
        } catch (fallbackErr) {
          final msg = fallbackErr.toString().replaceFirst('Exception: ', '');
          SecurityAuditLogger.log(
            eventType: 'AUTH_LOGIN_FAILED',
            severity: SecuritySeverity.warning,
            actor: cleanEmail,
            description: 'Percobaan login gagal: $msg',
          );
          throw Exception(msg);
        }
      }

      SecurityAuditLogger.log(
        eventType: 'AUTH_LOGIN_ERROR',
        severity: SecuritySeverity.warning,
        actor: cleanEmail,
        description: 'Login gagal: $e',
      );
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final nameErr = SecurityUtils.validateSafeText(
      name,
      fieldName: 'Nama Lengkap',
      minLength: 3,
      maxLength: 80,
    );
    if (nameErr != null) throw Exception(nameErr);

    final emailErr = SecurityUtils.validateEmail(email);
    if (emailErr != null) throw Exception(emailErr);

    final pwdErr = SecurityUtils.validateStrongPassword(password);
    if (pwdErr != null) throw Exception(pwdErr);

    final cleanName = SecurityUtils.sanitizeInput(name);
    final cleanEmail = SecurityUtils.sanitizeInput(email).toLowerCase();

    try {
      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'name': cleanName,
          'role': 'kasir',
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Registrasi gagal: Tidak dapat membuat akun pengguna.');
      }

      final newProfile = UserProfile(
        id: user.id,
        email: cleanEmail,
        role: 'kasir',
        name: cleanName,
      );

      try {
        await _supabase.from('users_profile').upsert(newProfile.toJson());
      } catch (_) {}

      LocalFallbackStore.currentUser = newProfile;

      SecurityAuditLogger.log(
        eventType: 'AUTH_REGISTER_SUCCESS',
        severity: SecuritySeverity.info,
        actor: cleanEmail,
        description: 'Registrasi akun baru berhasil untuk "$cleanName" dengan role "kasir".',
      );

      return newProfile;
    } on AuthException catch (e) {
      SecurityAuditLogger.log(
        eventType: 'AUTH_REGISTER_FAILED',
        severity: SecuritySeverity.warning,
        actor: cleanEmail,
        description: 'Registrasi gagal: ${e.message}',
      );
      throw Exception('Registrasi gagal: ${e.message}');
    } catch (e) {
      if (LocalFallbackStore.isNetworkOrFetchError(e)) {
        final fallbackProfile = LocalFallbackStore.registerUser(
          name: cleanName,
          email: cleanEmail,
          password: password,
        );
        SecurityAuditLogger.log(
          eventType: 'AUTH_REGISTER_SUCCESS',
          severity: SecuritySeverity.info,
          actor: cleanEmail,
          description:
              'Registrasi akun baru berhasil (Mode Resilient Fallback) untuk "$cleanName" dengan role "kasir".',
        );
        return fallbackProfile;
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async {
    final currentEmail =
        _supabase.auth.currentUser?.email ?? LocalFallbackStore.currentUser?.email ?? 'unknown';
    LocalFallbackStore.currentUser = null;
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    SecurityAuditLogger.log(
      eventType: 'AUTH_LOGOUT',
      severity: SecuritySeverity.info,
      actor: currentEmail,
      description: 'Pengguna berhasil logout dan token sesi JWT telah dihapus.',
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    if (session == null || user == null) {
      return LocalFallbackStore.currentUser;
    }

    if (session.isExpired) {
      SecurityAuditLogger.log(
        eventType: 'SESSION_EXPIRED',
        severity: SecuritySeverity.warning,
        actor: user.email ?? 'unknown',
        description: 'Sesi JWT telah kedaluwarsa (expired). Melakukan auto-logout.',
      );
      LocalFallbackStore.currentUser = null;
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      return null;
    }

    try {
      final profile = await _fetchOrCreateUserProfile(user);
      LocalFallbackStore.currentUser = profile;
      return profile;
    } catch (_) {
      return LocalFallbackStore.currentUser;
    }
  }

  Future<UserProfile> _fetchOrCreateUserProfile(User user) async {
    try {
      final data = await _supabase
          .from('users_profile')
          .select()
          .eq('id', user.id)
          .single();
      return UserProfile.fromJson(data);
    } catch (_) {
      final fallbackName = user.userMetadata?['name']?.toString() ??
          user.email?.split('@').first ??
          'Staf Kasir';
      final fallbackProfile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        role: 'kasir',
        name: SecurityUtils.sanitizeInput(fallbackName),
      );
      try {
        await _supabase.from('users_profile').upsert(fallbackProfile.toJson());
      } catch (_) {}
      return fallbackProfile;
    }
  }
}
