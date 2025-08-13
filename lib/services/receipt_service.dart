import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/business_record.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_utils.dart';

class ReceiptService {
  static Future<void> generateAndPrintReceipt(List<BusinessRecord> records, AuthProvider authProvider, BusinessProvider businessProvider) async {
    final DateTime now = DateTime.now();
    final pdf = pw.Document();

    // Assuming all records in the list belong to the same transaction and customer
    final firstRecord = records.first;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(authProvider, businessProvider),
              pw.SizedBox(height: 20),
              _buildCustomerDetails(firstRecord, now),
              pw.SizedBox(height: 20),
              _buildItemsTable(records),
              pw.SizedBox(height: 20),
              _buildTotal(records),
              pw.SizedBox(height: 40),
              _buildFooter(authProvider), // Pass authProvider to _buildFooter
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(AuthProvider authProvider, BusinessProvider businessProvider) {
    final businessName = businessProvider.businessName;
    final businessAddress = businessProvider.businessAddress;
    final userPhone = authProvider.user?['phone'] as String?;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        if (businessName != null) pw.Text(businessName),
        if (businessAddress != null) pw.Text(businessAddress),
        if (userPhone != null) pw.Text('Phone: $userPhone'),
      ],
    );
  }

  static pw.Widget _buildCustomerDetails(BusinessRecord record, DateTime printTime) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(record.customerName ?? 'Walk-in Customer'),
        pw.SizedBox(height: 20),
        pw.Text('Date: ${AppUtils.formatDateTimeEastAfrica(printTime)}'),
        pw.Text('Receipt #: ${record.transactionId ?? record.id}'), // Use transactionId if available
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<BusinessRecord> records) {
    final headers = ['Description', 'Quantity', 'Unit Price', 'Total'];

    final data = records.map((record) => [
      record.description,
      record.quantity?.toString() ?? '1',
      CurrencyFormatter.format(record.unitPrice),
      CurrencyFormatter.format(record.totalAmount ?? record.amount),
    ]).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotal(List<BusinessRecord> records) {
    final subtotal = records.fold<double>(0, (sum, record) => sum + (record.totalAmount ?? record.amount));
    final totalPaid = records.fold<double>(0, (sum, record) => sum + (record.amountPaid ?? 0));
    final totalDebt = records.fold<double>(0, (sum, record) => sum + (record.debtAmount ?? 0));
    final isCreditSale = records.any((record) => record.isCreditSale);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Subtotal: ${CurrencyFormatter.format(subtotal)}'),
            pw.Text('Tax (0%): ${CurrencyFormatter.format(0)}'),
            pw.Divider(),
            pw.Text('Total: ${CurrencyFormatter.format(subtotal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (isCreditSale) ...[
              pw.Text('Amount Paid: ${CurrencyFormatter.format(totalPaid)}'),
              pw.Text('Amount Due: ${CurrencyFormatter.format(totalDebt)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            ]
          ],
        )
      ],
    );
  }

  static pw.Widget _buildFooter(AuthProvider authProvider) {
    final businessName = authProvider.user?['business']?['name'] as String?;
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text('Welcome back!'),
          pw.SizedBox(height: 5),
          pw.Text('Generated by Bizmax', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );
  }
}