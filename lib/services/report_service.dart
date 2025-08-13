import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/reports_provider.dart';
import '../utils/currency_formatter.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_utils.dart';

class ReportService {
  static Future<void> generateReport(ReportsProvider reportsProvider, InventoryProvider inventoryProvider, String selectedPeriod, DateTime? startDate, DateTime? endDate) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            _buildHeader(selectedPeriod, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildOverview(reportsProvider),
            pw.SizedBox(height: 20),
            _buildSales(reportsProvider, selectedPeriod),
            pw.SizedBox(height: 20),
            _buildPurchases(reportsProvider, selectedPeriod),
            pw.SizedBox(height: 20),
            _buildExpenses(reportsProvider, selectedPeriod),
            pw.SizedBox(height: 20),
            _buildInventory(inventoryProvider),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(String selectedPeriod, DateTime? startDate, DateTime? endDate) {
    String periodText = selectedPeriod;
    if (startDate != null && endDate != null) {
      periodText += ' (${startDate.toLocal().toString().split(' ')[0]} - ${endDate.toLocal().toString().split(' ')[0]})';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Business Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Period: $periodText'),
        pw.Text('Generated on: ${AppUtils.formatDateTimeEastAfrica(DateTime.now())}'),
      ],
    );
  }

  static pw.Widget _buildOverview(ReportsProvider provider) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Total Revenue', CurrencyFormatter.format(provider.metrics.totalRevenue)],
            ['Total Expenses', CurrencyFormatter.format(provider.metrics.totalExpenses)],
            ['Gross Profit', CurrencyFormatter.format(provider.metrics.totalGrossProfit)],
            ['Net Profit', CurrencyFormatter.format(provider.metrics.totalNetProfit)],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSales(ReportsProvider provider, String selectedPeriod) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Sales', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            if (selectedPeriod == 'Leo') ['Today\'s Revenue', CurrencyFormatter.format(provider.metrics.todayRevenue)],
            ['Total Revenue', CurrencyFormatter.format(provider.metrics.totalRevenue)],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('Top Selling Products', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: ['Product', 'Revenue'],
          data: provider.topSellingProducts.map((product) => [product['name'], CurrencyFormatter.format(product['revenue'])]).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPurchases(ReportsProvider provider, String selectedPeriod) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Purchases', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            if (selectedPeriod == 'Leo') ['Today\'s Purchases', CurrencyFormatter.format(provider.metrics.todayPurchases ?? 0)],
            ['Total Purchases', CurrencyFormatter.format(provider.metrics.totalPurchases ?? 0)],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('Top Purchases', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: ['Product', 'Amount'],
          data: provider.topPurchases.map((purchase) => [purchase['name'], CurrencyFormatter.format(purchase['revenue'])]).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildExpenses(ReportsProvider provider, String selectedPeriod) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Expenses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            if (selectedPeriod == 'Leo') ['Today\'s Expenses', CurrencyFormatter.format(provider.metrics.todayExpenses)],
            ['Total Expenses', CurrencyFormatter.format(provider.metrics.totalExpenses)],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInventory(InventoryProvider provider) {
    final allItems = provider.items;
    final totalProducts = allItems.length;
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Inventory', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Total Products', totalProducts.toString()],
            ['Low Stock Items', lowStockItems.toString()],
          ],
        ),
      ],
    );
  }
}