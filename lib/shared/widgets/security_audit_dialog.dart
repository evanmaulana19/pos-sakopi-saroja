import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/security_audit_logger.dart';

class SecurityAuditDialog extends StatefulWidget {
  const SecurityAuditDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SecurityAuditDialog(),
    );
  }

  @override
  State<SecurityAuditDialog> createState() => _SecurityAuditDialogState();
}

class _SecurityAuditDialogState extends State<SecurityAuditDialog> {
  @override
  Widget build(BuildContext context) {
    final logs = SecurityAuditLogger.logs;
    final dateFmt = DateFormat('dd MMM yyyy HH:mm:ss');

    Session? currentSession;
    try {
      currentSession = Supabase.instance.client.auth.currentSession;
    } catch (_) {}

    final expiresAt = currentSession?.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(currentSession!.expiresAt! * 1000)
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.darkGreen, size: 28),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Audit & Activity Log',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pemantauan Keamanan Sesi, RBAC, Rate Limit, & Input Sanitizer',
                            style: TextStyle(fontSize: 12, color: AppColors.darkGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Session & Token Security Info Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBeige,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, size: 16, color: AppColors.darkGreen),
                        SizedBox(width: 6),
                        Text(
                          'Status Keamanan Sesi & Kriptografi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Hashing Password: Bcrypt (Supabase Auth GoTrue) + Strong Password Policy\n'
                      '• Sesi/Token: JWT Bearer Token (${currentSession != null ? "Aktif" : "Belum Login"})'
                      '${expiresAt != null ? " • Kedaluwarsa: ${dateFmt.format(expiresAt)}" : ""}\n'
                      '• Proteksi Aktif: RBAC Route & RLS Database, Anti-SQLi, Anti-XSS, Login Rate Limiter (5x/60s)',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Log Aktivitas (${logs.length} Kejadian)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Segarkan'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('Belum ada catatan log aktivitas.'))
                    : ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = logs[index];
                          Color badgeColor;
                          IconData badgeIcon;
                          switch (item.severity) {
                            case SecuritySeverity.critical:
                              badgeColor = AppColors.softRed;
                              badgeIcon = Icons.gpp_bad;
                              break;
                            case SecuritySeverity.warning:
                              badgeColor = Colors.orange.shade800;
                              badgeIcon = Icons.warning_amber_rounded;
                              break;
                            case SecuritySeverity.info:
                              badgeColor = AppColors.darkGreen;
                              badgeIcon = Icons.check_circle_outline;
                              break;
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Icon(badgeIcon, color: badgeColor, size: 22),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.eventType,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.actor} • ${dateFmt.format(item.timestamp)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.darkGray),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                item.description,
                                style: const TextStyle(fontSize: 12, color: AppColors.charcoal),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
