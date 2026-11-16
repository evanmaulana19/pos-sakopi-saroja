import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SecuritySeverity { info, warning, critical }

class SecurityLogEntry {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final SecuritySeverity severity;
  final String actor;
  final String description;

  SecurityLogEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.actor,
    required this.description,
  });

  factory SecurityLogEntry.fromJson(Map<String, dynamic> json) {
    final sevStr = (json['severity'] ?? 'info').toString().toLowerCase();
    SecuritySeverity sev = SecuritySeverity.info;
    if (sevStr == 'warning') sev = SecuritySeverity.warning;
    if (sevStr == 'critical') sev = SecuritySeverity.critical;

    return SecurityLogEntry(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventType: json['event_type']?.toString() ?? 'UNKNOWN',
      severity: sev,
      actor: json['actor_email']?.toString() ?? 'anonymous',
      description: json['description']?.toString() ?? '',
    );
  }
}

class SecurityAuditLogger {
  static final List<SecurityLogEntry> _localLogs = [
    SecurityLogEntry(
      id: 'init-1',
      timestamp: DateTime.now(),
      eventType: 'SYSTEM_INIT',
      severity: SecuritySeverity.info,
      actor: 'system',
      description: 'Sistem proteksi keamanan POS Sakopi Saroja aktif (Input Sanitizer, RBAC Guard, Rate Limiter).',
    ),
  ];

  static List<SecurityLogEntry> get logs => List.unmodifiable(_localLogs);

  static void log({
    required String eventType,
    required SecuritySeverity severity,
    required String description,
    String? actor,
  }) {
    String currentActor = actor ?? 'anonymous';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (actor == null && user?.email != null) {
        currentActor = user!.email!;
      }
    } catch (_) {
      // Supabase might not be initialized in unit tests
    }

    final entry = SecurityLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      eventType: eventType,
      severity: severity,
      actor: currentActor,
      description: description,
    );

    _localLogs.insert(0, entry);
    if (_localLogs.length > 200) {
      _localLogs.removeLast();
    }

    // Best-effort async persistence to Supabase `security_logs` table if available
    _persistToSupabase(entry);
  }

  static Future<void> _persistToSupabase(SecurityLogEntry entry) async {
    try {
      await Supabase.instance.client.from('security_logs').insert({
        'event_type': entry.eventType,
        'severity': entry.severity.name.toUpperCase(),
        'actor_email': entry.actor,
        'description': entry.description,
        'created_at': entry.timestamp.toUtc().toIso8601String(),
      });
    } catch (_) {
      // Ignore if table doesn't exist yet or user is unauthenticated
    }
  }
}

class SecurityLogsNotifier extends Notifier<List<SecurityLogEntry>> {
  @override
  List<SecurityLogEntry> build() {
    return SecurityAuditLogger.logs;
  }

  void refreshLogs() {
    state = List.from(SecurityAuditLogger.logs);
  }
}

final securityLogsProvider = NotifierProvider<SecurityLogsNotifier, List<SecurityLogEntry>>(
  () => SecurityLogsNotifier(),
);
