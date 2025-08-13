import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../screens/product_profit_screen.dart';
import '../utils/currency_formatter.dart';

class ProductProfitReportService {
  static Future<void> generateReport(
    List<ProductProfitData> productProfitData,
    String selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(selectedPeriod, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildProfitTable(productProfitData),
          pw.SizedBox(height: 20),
          _buildSummary(productProfitData),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(
      String selectedPeriod, DateTime? startDate, DateTime? endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ripoti ya Faida kwa Bidhaa', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Kipindi: $selectedPeriod'),
        if (startDate != null && endDate != null)
          pw.Text('Kuanzia: ${startDate.toLocal().toString().split(' ')[0]} - Mpaka: ${endDate.toLocal().toString().split(' ')[0]}'),
      ],
    );
  }

  static pw.Widget _buildProfitTable(List<ProductProfitData> productProfitData) {
    final headers = [
      'Bidhaa',
      'Idadi',
      'Kununua (TShs)',
      'Mauzo (TShs)',
      'Faida (TShs)',
    ];

    final data = productProfitData.map((data) {
      return [
        data.productName,
        data.quantity.toString(),
        CurrencyFormatter.format(data.totalCost),
        CurrencyFormatter.format(data.totalRevenue),
        CurrencyFormatter.format(data.profit),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerRight,
      cellStyle: const pw.TextStyle(),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
    );
  }

  static pw.Widget _buildSummary(List<ProductProfitData> productProfitData) {
    final totalRevenue =
        productProfitData.fold(0.0, (sum, data) => sum + data.totalRevenue);
    final totalProfit =
        productProfitData.fold(0.0, (sum, data) => sum + data.profit);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Muhtasari', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Jumla ya Mauzo:'),
            pw.Text(CurrencyFormatter.format(totalRevenue), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Jumla ya Faida:'),
            pw.Text(CurrencyFormatter.format(totalProfit), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
