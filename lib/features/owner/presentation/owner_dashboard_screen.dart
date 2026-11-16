import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/security_audit_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/owner_providers.dart';
import '../domain/owner_repository.dart';
import 'pdf_report_generator.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
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
              child: const Icon(Icons.storefront_rounded, color: AppColors.goldenTan, size: 18),
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
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_rounded), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_rounded), label: 'Pengeluaran'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Akun Staf'),
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
      width: 250,
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
                child: const Icon(Icons.storefront_rounded, color: AppColors.darkGreen, size: 26),
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
                      'EXECUTIVE OWNER',
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
          _buildSidebarItem(0, Icons.analytics_outlined, 'Laporan Keuangan'),
          const SizedBox(height: 8),
          _buildSidebarItem(1, Icons.account_balance_wallet_outlined, 'Beban Pengeluaran'),
          const SizedBox(height: 8),
          _buildSidebarItem(2, Icons.manage_accounts_outlined, 'Manajemen Staf (RBAC)'),
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
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'O',
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
        return 'Owner - Laporan';
      case 1:
        return 'Owner - Pengeluaran';
      case 2:
        return 'Manajemen Akun Staf';
      default:
        return 'Owner';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildReport();
      case 1:
        return _buildExpenses();
      case 2:
        return _buildStaffAccounts();
      default:
        return _buildReport();
    }
  }

  Widget _buildReport() {
    final reportAsync = ref.watch(financialReportProvider);
    final top5Async = ref.watch(top5MenusProvider);
    final dailyRevenueAsync = ref.watch(dailyRevenueProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final isWide = MediaQuery.of(context).size.width >= 760;

    return ListView(
      children: [
        // Top Header & Action Row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan & Analitik Keuangan',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 25),
                ),
                const Text(
                  'Rekapitulasi pendapatan kotor, beban pengeluaran, dan laba bersih secara real-time.',
                  style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Reset Transaksi'),
                        content: const Text(
                          'Anda yakin ingin mereset seluruh transaksi pada rentang waktu ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softRed),
                            onPressed: () async {
                              final range = ref.read(dateRangeProvider);
                              try {
                                await ref
                                    .read(ownerRepositoryProvider)
                                    .resetTransactions(range.startDate, range.endDate);
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                ref.invalidate(financialReportProvider);
                                ref.invalidate(dailyRevenueProvider);
                                ref.invalidate(top5MenusProvider);
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softRed, size: 18),
                  label: const Text('Reset Data', style: TextStyle(color: AppColors.softRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.softRed),
                    backgroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (reportAsync.value == null || top5Async.value == null) {
                      return;
                    }
                    final range = ref.read(dateRangeProvider);
                    final pdfData = await PdfReportGenerator.generateFinancialReport(
                      report: reportAsync.value!,
                      topMenus: top5Async.value!,
                      dateFilter: dateFilter,
                      startDate: range.startDate,
                      endDate: range.endDate,
                    );
                    await Printing.layoutPdf(onLayout: (format) async => pdfData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldenTan,
                    foregroundColor: AppColors.darkGreen,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Unduh Laporan PDF'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Capsule Date Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DateFilter.values.map((filter) {
              final isSelected = filter == dateFilter;
              String label = '';
              switch (filter) {
                case DateFilter.hariIni:
                  label = 'Hari Ini';
                  break;
                case DateFilter.mingguIni:
                  label = 'Minggu Ini';
                  break;
                case DateFilter.bulanIni:
                  label = 'Bulan Ini';
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: InkWell(
                  onTap: () => ref.read(dateFilterProvider.notifier).setFilter(filter),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.darkGreen : AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? AppColors.darkGreen : AppColors.lightGray,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isSelected ? AppColors.goldenTan : AppColors.darkGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.charcoal,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        reportAsync.when(
          data: (report) => Column(
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Pendapatan Kotor',
                        report.grossRevenue,
                        Icons.point_of_sale_rounded,
                        AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Beban Pengeluaran',
                        report.totalExpenses,
                        Icons.receipt_long_rounded,
                        AppColors.softRed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Laba Bersih (Net Profit)',
                        report.netProfit,
                        Icons.monetization_on_rounded,
                        AppColors.darkGreen,
                        isHighlight: true,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildMetricCard(
                  'Pendapatan Kotor',
                  report.grossRevenue,
                  Icons.point_of_sale_rounded,
                  AppColors.darkGreen,
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Beban Pengeluaran',
                  report.totalExpenses,
                  Icons.receipt_long_rounded,
                  AppColors.softRed,
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Laba Bersih (Net Profit)',
                  report.netProfit,
                  Icons.monetization_on_rounded,
                  AppColors.darkGreen,
                  isHighlight: true,
                ),
              ],
              const SizedBox(height: 22),
              // Grafik Penjualan & Proporsi Pembayaran
              dailyRevenueAsync.when(
                data: (dailyRevenue) {
                  return Container(
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Grafik Tren Penjualan Harian',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.charcoal,
                              ),
                            ),
                            Icon(Icons.trending_up_rounded, color: AppColors.darkGreen),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (dailyRevenue.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text('Belum ada transaksi selesai di periode ini'),
                            ),
                          )
                        else
                          Builder(builder: (context) {
                            List<FlSpot> spots = [];
                            double maxY = 0;
                            for (int i = 0; i < dailyRevenue.length; i++) {
                              final val = (dailyRevenue[i]['revenue'] as num).toDouble();
                              if (val > maxY) {
                                maxY = val;
                              }
                              spots.add(FlSpot(i.toDouble(), val));
                            }
                            if (maxY == 0) {
                              maxY = 100000;
                            }
                            return SizedBox(
                              height: 210,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final int index = value.toInt();
                                          if (index >= 0 && index < dailyRevenue.length) {
                                            final dateStr = dailyRevenue[index]['date'] as String;
                                            final day = dateStr.split('-').last;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(day, style: const TextStyle(fontSize: 10)),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: (dailyRevenue.length - 1) <= 0
                                      ? 1
                                      : (dailyRevenue.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: maxY * 1.2,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: AppColors.darkGreen,
                                      barWidth: 3.5,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.goldenTan.withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 20),
              // Proporsi Pembayaran
              Container(
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Proporsi Metode Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          sections: [
                            PieChartSectionData(
                              color: AppColors.darkGreen,
                              value: report.midtransTotal == 0 && report.tunaiTotal == 0
                                  ? 1
                                  : report.midtransTotal,
                              title: report.midtransTotal == 0 && report.tunaiTotal == 0
                                  ? ''
                                  : '${(report.midtransTotal / (report.midtransTotal + report.tunaiTotal) * 100).toStringAsFixed(0)}%',
                              radius: 34,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: AppColors.goldenTan,
                              value: report.midtransTotal == 0 && report.tunaiTotal == 0
                                  ? 1
                                  : report.tunaiTotal,
                              title: report.midtransTotal == 0 && report.tunaiTotal == 0
                                  ? ''
                                  : '${(report.tunaiTotal / (report.midtransTotal + report.tunaiTotal) * 100).toStringAsFixed(0)}%',
                              radius: 34,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Non-Tunai (${currencyFormatter.format(report.midtransTotal)})'),
                        const SizedBox(width: 20),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.goldenTan,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Tunai (${currencyFormatter.format(report.tunaiTotal)})'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        const SizedBox(height: 20),
        top5Async.when(
          data: (top5) => Container(
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top 5 Menu Terlaris (Data Aktual Database)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Icon(Icons.workspace_premium_rounded, color: AppColors.darkGreen),
                  ],
                ),
                const SizedBox(height: 18),
                if (top5.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Belum ada item terjual pada periode ini.',
                      style: TextStyle(color: AppColors.darkGray),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: top5.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final menu = top5[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: index == 0 ? AppColors.goldenTan : AppColors.lightBeige,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          menu['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${menu['qty']} porsi',
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    double amount,
    IconData icon,
    Color accentColor, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.darkGreen : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight
              ? AppColors.darkGreen
              : AppColors.lightGray.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: isHighlight ? 0.14 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHighlight
                  ? AppColors.goldenTan
                  : accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isHighlight ? AppColors.darkGreen : accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isHighlight
                        ? AppColors.lightBeige.withValues(alpha: 0.85)
                        : AppColors.darkGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 21,
                    color: isHighlight ? AppColors.goldenTan : accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpenseForm({Expense? existingExpense}) {
    final isEditing = existingExpense != null;
    final formKey = GlobalKey<FormState>();
    final nominalCtrl = TextEditingController(
      text: existingExpense != null ? existingExpense.amount.toInt().toString() : '',
    );
    final descCtrl = TextEditingController(text: existingExpense?.description ?? '');

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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Pengeluaran' : 'Catat Pengeluaran Baru',
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
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Pengeluaran',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (val) => SecurityUtils.validateSafeText(
                      val,
                      fieldName: 'Deskripsi Pengeluaran',
                      minLength: 3,
                      maxLength: 150,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nominalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Biaya (Rp)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => SecurityUtils.validatePositiveNumber(
                      val,
                      fieldName: 'Nominal Pengeluaran',
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Simpan Pengeluaran',
                    icon: Icons.save_outlined,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final expense = Expense(
                        id: existingExpense?.id,
                        amount: double.parse(nominalCtrl.text.trim()),
                        description: SecurityUtils.sanitizeInput(descCtrl.text),
                        expenseDate: existingExpense?.expenseDate ?? DateTime.now(),
                      );
                      try {
                        if (isEditing) {
                          await ref.read(ownerRepositoryProvider).updateExpense(expense);
                        } else {
                          await ref.read(ownerRepositoryProvider).addExpense(expense);
                        }
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        ref.invalidate(expensesProvider);
                        ref.invalidate(financialReportProvider);
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
        );
      },
    );
  }

  void _deleteExpense(Expense expense) {
    if (expense.id == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Hapus catatan pengeluaran "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softRed),
            onPressed: () async {
              try {
                await ref.read(ownerRepositoryProvider).deleteExpense(expense.id!);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                ref.invalidate(expensesProvider);
                ref.invalidate(financialReportProvider);
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

  Widget _buildExpenses() {
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        double total = 0;
        for (var e in expenses) {
          total += e.amount;
        }

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
                        'Beban Operasional Kedai',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      ),
                      const Text(
                        'Kelola pengeluaran bahan baku dan operasional untuk menghitung laba bersih.',
                        style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: PrimaryButton(
                    text: '+ Catat Pengeluaran',
                    backgroundColor: AppColors.goldenTan,
                    foregroundColor: AppColors.darkGreen,
                    onPressed: () => _showExpenseForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: const Border(left: BorderSide(color: AppColors.softRed, width: 5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Beban Pengeluaran Periode Ini:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.charcoal),
                  ),
                  Text(
                    currencyFormatter.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.softRed,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(36.0),
                child: Center(
                  child: Text('Belum ada pengeluaran dicatat pada periode ini.'),
                ),
              )
            else
              ...expenses.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.softRed),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.charcoal,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(e.expenseDate.toLocal()),
                              style: const TextStyle(color: AppColors.darkGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(e.amount),
                        style: const TextStyle(
                          color: AppColors.softRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.darkGreen),
                        onPressed: () => _showExpenseForm(existingExpense: e),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softRed),
                        onPressed: () => _deleteExpense(e),
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

  void _showStaffForm({Map<String, dynamic>? staff}) {
    final isEditing = staff != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: staff?['name'] ?? '');
    final uuidCtrl = TextEditingController(text: staff?['id'] ?? '');
    final emailCtrl = TextEditingController(text: staff?['email'] ?? '');
    String rawRole = (staff?['role'] ?? 'kasir').toString().toLowerCase();
    if (rawRole == 'cashier') rawRole = 'kasir';
    String role = ['kasir', 'admin', 'owner'].contains(rawRole) ? rawRole : 'kasir';

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
            constraints: const BoxConstraints(maxWidth: 500),
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
                          isEditing ? 'Edit Hak Akses Staf' : 'Tambah Akun Staf',
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
                    const SizedBox(height: 12),
                    if (!isEditing)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBeige,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.goldenTan),
                        ),
                        child: const Text(
                          'Tips: Staf dapat mendaftar mandiri melalui halaman Registrasi (/register), lalu Anda dapat mengubah Role-nya di sini.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (!isEditing) ...[
                      TextFormField(
                        controller: uuidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'UUID (Dari Supabase Auth)',
                          prefixIcon: Icon(Icons.fingerprint_rounded),
                        ),
                        validator: (val) => SecurityUtils.validateSafeText(
                          val,
                          fieldName: 'UUID',
                          minLength: 10,
                          maxLength: 64,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email Staf',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: SecurityUtils.validateEmail,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Staf',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (val) => SecurityUtils.validateSafeText(
                        val,
                        fieldName: 'Nama Staf',
                        minLength: 2,
                        maxLength: 80,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Role / Hak Akses (RBAC)',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'owner', child: Text('Owner (Pemilik)')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Manajer Toko)')),
                        DropdownMenuItem(value: 'kasir', child: Text('Kasir (Cashier)')),
                      ],
                      onChanged: (val) {
                        if (val != null) role = val;
                      },
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Simpan Hak Akses',
                      icon: Icons.verified_user_outlined,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          if (isEditing) {
                            await ref
                                .read(ownerRepositoryProvider)
                                .updateStaff(staff['id'], nameCtrl.text.trim(), role);
                          } else {
                            await ref.read(ownerRepositoryProvider).addStaff(
                                  uuidCtrl.text.trim(),
                                  emailCtrl.text.trim(),
                                  nameCtrl.text.trim(),
                                  role,
                                );
                          }
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          ref.invalidate(staffAccountsProvider);
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

  void _deleteStaff(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Akun Staf'),
        content: const Text('Profil staf ini akan dihapus dari sistem. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.softRed),
            onPressed: () async {
              try {
                await ref.read(ownerRepositoryProvider).deleteStaff(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                ref.invalidate(staffAccountsProvider);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.softRed,
                    ),
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

  Widget _buildStaffAccounts() {
    final staffAsync = ref.watch(staffAccountsProvider);

    return staffAsync.when(
      data: (staff) {
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
                        'Manajemen Akun & Otorisasi Staf (RBAC)',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      ),
                      const Text(
                        'Atur peran (Owner, Admin, Kasir) untuk mengontrol hak akses tiap pengguna.',
                        style: TextStyle(color: AppColors.darkGray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    text: '+ Tambah Staf',
                    backgroundColor: AppColors.goldenTan,
                    foregroundColor: AppColors.darkGreen,
                    onPressed: () => _showStaffForm(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...staff.asMap().entries.map((entry) {
              final s = entry.value;
              final roleStr = (s['role'] ?? 'kasir').toString().toLowerCase();
              final isOwnerRole = roleStr == 'owner';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isOwnerRole ? AppColors.goldenTan : AppColors.lightBeige,
                      child: Icon(
                        isOwnerRole
                            ? Icons.verified_user_rounded
                            : Icons.badge_outlined,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s['email'] ?? '',
                            style: const TextStyle(color: AppColors.darkGray, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOwnerRole
                            ? AppColors.goldenTan
                            : AppColors.darkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleStr.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.darkGreen),
                      onPressed: () => _showStaffForm(staff: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.softRed),
                      onPressed: () => _deleteStaff(s['id']),
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
