import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../domain/owner_repository.dart';
import '../data/owner_providers.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateFinancialReport({
    required FinancialReport report,
    required List<Map<String, dynamic>> topMenus,
    required DateFilter dateFilter,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    String filterText;
    switch(dateFilter) {
      case DateFilter.hariIni:
        filterText = 'Laporan Hari Ini (${DateFormat('dd MMM yyyy').format(startDate)})';
        break;
      case DateFilter.mingguIni:
        filterText = 'Laporan Minggu Ini (${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate.subtract(const Duration(days: 1)))})';
        break;
      case DateFilter.bulanIni:
        filterText = 'Laporan Bulan Ini (${DateFormat('MMMM yyyy').format(startDate)})';
        break;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('POS SAKOPI SAROJA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(filterText, style: pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Financial Summary
              pw.Text('Ringkasan Keuangan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow('Pendapatan Kotor', currencyFormatter.format(report.grossRevenue), isBold: true),
                  _buildTableRow('  - Tunai', currencyFormatter.format(report.tunaiTotal)),
                  _buildTableRow('  - Non-Tunai', currencyFormatter.format(report.midtransTotal)),
                  _buildTableRow('Total Pengeluaran', currencyFormatter.format(report.totalExpenses)),
                  _buildTableRow('Keuntungan Bersih (Net Profit)', currencyFormatter.format(report.netProfit), isBold: true),
                ]
              ),
              pw.SizedBox(height: 32),
              
              // Top Products
              pw.Text('Produk Terlaris', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headers: ['No', 'Nama Menu', 'Terjual'],
                data: List<List<String>>.generate(
                  topMenus.length,
                  (index) => [
                    '${index + 1}',
                    topMenus[index]['name'].toString(),
                    '${topMenus[index]['qty']} porsi',
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Dicetak pada: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}'),
                  ]
                )
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
  
  static pw.TableRow _buildTableRow(String label, String value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        ),
      ]
    );
  }
}
