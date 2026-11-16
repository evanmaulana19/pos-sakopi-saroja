import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/security_audit_logger.dart';
import '../utils/security_utils.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cashier/presentation/pos_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/owner/presentation/owner_dashboard_screen.dart';

String _homeRouteForRole(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return '/admin';
    case 'owner':
      return '/owner';
    case 'kasir':
    default:
      return '/cashier';
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // 1. Inspeksi Keamanan Parameter URL terhadap SQL Injection & XSS
      for (final entry in state.uri.queryParameters.entries) {
        final key = entry.key;
        final val = entry.value;
        if (SecurityUtils.containsXss(key) ||
            SecurityUtils.containsXss(val) ||
            SecurityUtils.containsSqlInjection(key) ||
            SecurityUtils.containsSqlInjection(val)) {
          SecurityAuditLogger.log(
            eventType: 'URL_PARAM_ATTACK_BLOCKED',
            severity: SecuritySeverity.critical,
            description:
                'Payload berbahaya (SQLi/XSS) pada parameter URL "?$key=$val" diblokir oleh Router Guard.',
          );
          return state.uri.path; // Bersihkan query parameter berbahaya
        }
      }

      final isAuthLoading = authState.isLoading;
      if (isAuthLoading) return null;

      final user = authState.value;
      final path = state.uri.path;
      final isPublicAuthRoute = path == '/login' || path == '/register';

      // 2. Proteksi Autentikasi: Tolak akses jika belum login
      if (user == null && !isPublicAuthRoute) {
        SecurityAuditLogger.log(
          eventType: 'RBAC_UNAUTHENTICATED_BLOCKED',
          severity: SecuritySeverity.warning,
          description: 'Akses tanpa autentikasi ke rute "$path" ditolak. Mengarahkan ke /login.',
        );
        return '/login';
      }

      // 3. Jika sudah login dan membuka /login atau /register, arahkan ke dashboard sesuai role
      if (user != null && isPublicAuthRoute) {
        return _homeRouteForRole(user.role);
      }

      // 4. Proteksi Otorisasi / Role-Based Access Control (RBAC) Ketat pada Setiap Rute
      if (user != null) {
        final role = user.role.toLowerCase();

        if (path.startsWith('/owner') && role != 'owner') {
          SecurityAuditLogger.log(
            eventType: 'RBAC_UNAUTHORIZED_ACCESS',
            severity: SecuritySeverity.critical,
            actor: user.email,
            description:
                'Kontrol Akses: User "${user.email}" (role: $role) mencoba mengakses halaman "/owner" tanpa hak akses! Akses ditolak.',
          );
          return _homeRouteForRole(role);
        }

        if (path.startsWith('/admin') && role != 'admin' && role != 'owner') {
          SecurityAuditLogger.log(
            eventType: 'RBAC_UNAUTHORIZED_ACCESS',
            severity: SecuritySeverity.critical,
            actor: user.email,
            description:
                'Kontrol Akses: User "${user.email}" (role: $role) mencoba mengakses halaman "/admin" tanpa hak akses! Akses ditolak.',
          );
          return _homeRouteForRole(role);
        }

        if (path.startsWith('/cashier') && role != 'kasir' && role != 'owner') {
          SecurityAuditLogger.log(
            eventType: 'RBAC_UNAUTHORIZED_ACCESS',
            severity: SecuritySeverity.warning,
            actor: user.email,
            description:
                'Kontrol Akses: User "${user.email}" (role: $role) diarahkan kembali dari "/cashier" ke dashboard sesuai perannya.',
          );
          return _homeRouteForRole(role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/cashier',
        builder: (context, state) {
          final rawQuery = state.uri.queryParameters['q'] ?? '';
          final safeQuery = SecurityUtils.sanitizeInput(rawQuery);
          return PosScreen(initialSearchQuery: safeQuery);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
    ],
  );
});
