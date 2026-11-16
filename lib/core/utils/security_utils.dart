import 'security_audit_logger.dart';

class SecurityUtils {
  // Pola deteksi SQL Injection (Case-Insensitive)
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE|TRUNCATE|EXEC|DECLARE)\b\s+)", caseSensitive: false),
    RegExp(r"(\b(OR|AND)\b\s+['\d\w]+\s*=\s*['\d\w]+)", caseSensitive: false),
    RegExp(r"('--|;--|\/\*|\*\/|@@|char\(|nchar\(|varchar\(|cast\(|sleep\(|benchmark\(|waitfor\s+delay)", caseSensitive: false),
    RegExp(r"('\s*(OR|AND)\s*')", caseSensitive: false),
    RegExp(r"('\s*=\s*')", caseSensitive: false),
  ];

  // Pola deteksi Cross-Site Scripting / XSS (Case-Insensitive)
  static final List<RegExp> _xssPatterns = [
    RegExp(r"<\s*\/?\s*(script|iframe|object|embed|svg|img|body|link|meta|style|form|input|button)\b[^>]*>", caseSensitive: false),
    RegExp(r"(javascript\s*:|vbscript\s*:|data\s*:\s*text\/html)", caseSensitive: false),
    RegExp(r"\bon(error|load|click|mouseover|mouseout|focus|blur|submit|change|keyup|keydown)\s*=", caseSensitive: false),
    RegExp(r"(alert\s*\(|confirm\s*\(|prompt\s*\(|document\.cookie|document\.write|window\.location|eval\s*\()", caseSensitive: false),
    RegExp(r"[<>]", caseSensitive: false),
  ];

  // Daftar password lemah yang sering digunakan (Blacklist)
  static const Set<String> _weakPasswordsBlacklist = {
    'password',
    'password123',
    'password123!',
    '12345678',
    '123456789',
    '1234567890',
    'qwerty123',
    'qwertyuiop',
    'admin123',
    'admin1234',
    'kasir123',
    'owner123',
    'sakopi123',
    'iloveyou',
    'welcome123',
  };

  /// Mengecek apakah string mengandung indikasi payload SQL Injection
  static bool containsSqlInjection(String input) {
    if (input.isEmpty) return false;
    final decoded = Uri.decodeFull(input);
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(input) || pattern.hasMatch(decoded)) {
        return true;
      }
    }
    return false;
  }

  /// Mengecek apakah string mengandung indikasi payload XSS
  static bool containsXss(String input) {
    if (input.isEmpty) return false;
    final decoded = Uri.decodeFull(input);
    for (final pattern in _xssPatterns) {
      if (pattern.hasMatch(input) || pattern.hasMatch(decoded)) {
        return true;
      }
    }
    return false;
  }

  /// Sanitasi teks input dari tag HTML dan karakter kontrol berbahaya
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', "'")
        .replaceAll('`', '')
        .replaceAll('--', '');
  }

  /// Validator umum untuk TextFormField (Mencegah SQLi & XSS)
  static String? validateSafeText(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 150,
    bool allowEmpty = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return allowEmpty ? null : '$fieldName tidak boleh kosong';
    }
    if (text.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    if (text.length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    if (containsXss(text)) {
      SecurityAuditLogger.log(
        eventType: 'XSS_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan input XSS diblokir pada field "$fieldName": ${_truncate(text)}',
      );
      return 'Input ditolak: Terdeteksi karakter/script berbahaya (XSS) pada $fieldName!';
    }
    if (containsSqlInjection(text)) {
      SecurityAuditLogger.log(
        eventType: 'SQLI_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan SQL Injection diblokir pada field "$fieldName": ${_truncate(text)}',
      );
      return 'Input ditolak: Terdeteksi pola karakter ilegal (SQL Injection) pada $fieldName!';
    }
    return null;
  }

  /// Validator Email yang aman dari SQL Injection & XSS
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (containsXss(email)) {
      SecurityAuditLogger.log(
        eventType: 'XSS_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan XSS pada field Email diblokir: ${_truncate(email)}',
      );
      return 'Input ditolak: Terdeteksi payload XSS pada Email!';
    }
    if (containsSqlInjection(email)) {
      SecurityAuditLogger.log(
        eventType: 'SQLI_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan SQL Injection pada field Email diblokir: ${_truncate(email)}',
      );
      return 'Input ditolak: Terdeteksi pola SQL Injection pada Email!';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid (contoh: nama@sakopi.com)';
    }
    return null;
  }

  /// Validator Password saat Login (Memeriksa SQLi/XSS pada form login)
  static String? validateLoginPassword(String? value) {
    final pwd = value ?? '';
    if (pwd.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (containsSqlInjection(pwd)) {
      SecurityAuditLogger.log(
        eventType: 'SQLI_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan SQL Injection pada field Password Login diblokir.',
      );
      return 'Input ditolak: Terdeteksi pola SQL Injection pada Password!';
    }
    if (containsXss(pwd)) {
      SecurityAuditLogger.log(
        eventType: 'XSS_ATTEMPT_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'Percobaan XSS pada field Password Login diblokir.',
      );
      return 'Input ditolak: Terdeteksi karakter berbahaya (XSS) pada Password!';
    }
    return null;
  }

  /// Validator Password Kuat untuk Registrasi (Menolak password lemah)
  static String? validateStrongPassword(String? value) {
    final pwd = value ?? '';
    if (pwd.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (pwd.length < 8) {
      SecurityAuditLogger.log(
        eventType: 'WEAK_PASSWORD_REJECTED',
        severity: SecuritySeverity.warning,
        description: 'Registrasi ditolak: Password kurang dari 8 karakter.',
      );
      return 'Password terlalu lemah: Minimal 8 karakter';
    }
    if (_weakPasswordsBlacklist.contains(pwd.toLowerCase())) {
      SecurityAuditLogger.log(
        eventType: 'WEAK_PASSWORD_REJECTED',
        severity: SecuritySeverity.warning,
        description: 'Registrasi ditolak: Password termasuk dalam daftar password umum/lemah.',
      );
      return 'Password terlalu umum/lemah, gunakan kombinasi yang lebih unik';
    }
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) {
      return 'Password wajib mengandung minimal 1 huruf besar (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(pwd)) {
      return 'Password wajib mengandung minimal 1 huruf kecil (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(pwd)) {
      return 'Password wajib mengandung minimal 1 angka (0-9)';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(pwd)) {
      return 'Password wajib mengandung minimal 1 simbol/karakter spesial (!@#\$%^&* dll)';
    }
    return null;
  }

  /// Menghitung skor kekuatan password (0.0 s/d 1.0) untuk indikator UI
  static double calculatePasswordStrength(String pwd) {
    if (pwd.isEmpty) return 0.0;
    double score = 0.0;
    if (pwd.length >= 8) score += 0.25;
    if (pwd.length >= 12) score += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(pwd)) score += 0.15;
    if (_weakPasswordsBlacklist.contains(pwd.toLowerCase())) score = 0.2;
    return score.clamp(0.0, 1.0);
  }

  /// Validator angka positif (Harga produk, Nominal pengeluaran)
  static String? validatePositiveNumber(
    String? value, {
    required String fieldName,
    double maxAmount = 100000000,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return '$fieldName harus berupa angka yang valid';
    }
    if (parsed <= 0) {
      return '$fieldName harus lebih besar dari Rp 0';
    }
    if (parsed > maxAmount) {
      return '$fieldName melebihi batas maksimum yang diizinkan';
    }
    return null;
  }

  /// Validator URL Gambar yang aman (Mencegah SSRF / XSS via javascript: atau data: URI)
  static String? validateSafeUrl(String? value, {String fieldName = 'URL Gambar'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (containsXss(text) || containsSqlInjection(text)) {
      SecurityAuditLogger.log(
        eventType: 'MALICIOUS_URL_BLOCKED',
        severity: SecuritySeverity.critical,
        description: 'URL berbahaya diblokir pada field "$fieldName": ${_truncate(text)}',
      );
      return 'Input ditolak: $fieldName mengandung payload berbahaya!';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http')) || uri.host.isEmpty) {
      return '$fieldName harus menggunakan protokol https:// atau http:// yang valid';
    }
    return null;
  }

  static String _truncate(String input, [int maxLen = 60]) {
    if (input.length <= maxLen) return input;
    return '${input.substring(0, maxLen)}...';
  }
}
