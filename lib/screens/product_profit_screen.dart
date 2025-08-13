import 'package:rahisisha/services/product_profit_report_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/foundation.dart';

class ProductProfitScreen extends StatefulWidget {
  const ProductProfitScreen({Key? key}) : super(key: key);

  @override
  State<ProductProfitScreen> createState() => _ProductProfitScreenState();
}

class _ProductProfitScreenState extends State<ProductProfitScreen> {
  String _selectedPeriod = 'Mwezi huu';
  List<ProductProfitData> _productProfitData = [];
  bool _isLoading = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final List<String> _periods = [
    'Leo',
    'Jana',
    'Wiki hii',
    'Wiki iliyopita',
    'Mwezi huu',
    'Mwezi uliopita',
    'Mwaka huu',
    'Mwaka uliopita',
    'Muda maalum',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductProfitData();
    });
  }

  Future<void> _loadProductProfitData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recordsProvider = context.read<RecordsProvider>();
      final inventoryProvider = context.read<InventoryProvider>();

      // Ensure data is loaded
      await Future.wait([
        recordsProvider.loadRecords(),
        inventoryProvider.loadInventory(),
      ]);

      _calculateProductProfitData();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = 'Muda maalum';
      });
      _calculateProductProfitData();
    }
  }

  void _calculateProductProfitData() {
    final recordsProvider = context.read<RecordsProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    final (startDate, endDate) = _getDateRangeForPeriod(_selectedPeriod);

    final salesRecords = recordsProvider.allRecords.where((record) =>
      record.type == 'sale' &&
      record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      record.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final Map<String, ProductProfitData> productData = {};

    for (final record in salesRecords) {
      final productId = record.inventoryItemId;
      final productName = record.description;

      if (productId == null) continue;

      final product = inventoryProvider.items.firstWhere(
        (item) => item.id == productId,
        orElse: () => InventoryItem(
          id: productId,
          name: productName,
          description: productName,
          category: 'Unknown',
          unit: 'pcs',
          buyingPrice: 0,
          sellingPrice: record.amount,
          currentStock: 0,
          minimumStock: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (!productData.containsKey(productId)) {
        productData[productId] = ProductProfitData(
          productId: productId,
          productName: product.name,
          quantity: 0,
          buyingPrice: product.buyingPrice,
          sellingPrice: product.sellingPrice,
          totalRevenue: 0,
          totalCost: 0,
          profit: 0,
        );
      }

      final data = productData[productId]!;
      final quantity = record.quantity ?? 1;
      final revenue = record.amount;
      final cost = product.buyingPrice * quantity;

      data.quantity += quantity;
      data.totalRevenue += revenue;
      data.totalCost += cost;
      data.profit = data.totalRevenue - data.totalCost;
    }

    setState(() {
      _productProfitData = productData.values.toList()
        ..sort((a, b) => b.profit.compareTo(a.profit));
    });
  }

  (DateTime, DateTime) _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'Leo':
        return (today, today);
      case 'Jana':
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, yesterday);
      case 'Wiki hii':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (startOfWeek, today);
      case 'Wiki iliyopita':
        final startOfLastWeek =
            today.subtract(Duration(days: today.weekday + 6));
        final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
        return (startOfLastWeek, endOfLastWeek);
      case 'Mwezi huu':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return (startOfMonth, today);
      case 'Mwezi uliopita':
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return (startOfLastMonth, endOfLastMonth);
      case 'Mwaka huu':
        final startOfYear = DateTime(now.year, 1, 1);
        return (startOfYear, today);
      case 'Mwaka uliopita':
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year - 1, 12, 31);
        return (startOfLastYear, endOfLastYear);
      case 'Muda maalum':
        if (_customStartDate != null && _customEndDate != null) {
          return (_customStartDate!, _customEndDate!);
        }
        return (today.subtract(const Duration(days: 30)), today);
      default:
        return (today.subtract(const Duration(days: 30)), today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faida kwa Bidhaa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Muda maalum') {
                _showCustomDatePicker();
              } else {
                setState(() {
                  _selectedPeriod = value;
                });
                _calculateProductProfitData();
              }
            },
            itemBuilder: (context) => _periods
                .map((period) => PopupMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _selectedPeriod,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final (startDate, endDate) = _getDateRangeForPeriod(_selectedPeriod);
              ProductProfitReportService.generateReport(
                _productProfitData,
                _selectedPeriod,
                startDate,
                endDate,
              );
            },
          ),
        ],
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Inapakia data ya faida...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 12),
                    _buildProfitTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRevenue =
        _productProfitData.fold(0.0, (sum, data) => sum + data.totalRevenue);
    final totalProfit =
        _productProfitData.fold(0.0, (sum, data) => sum + data.profit);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Jumla ya Mauzo',
                CurrencyFormatter.format(totalRevenue),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryItem(
                'Jumla ya Faida',
                CurrencyFormatter.format(totalProfit),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfitTable() {
    final totalCost =
        _productProfitData.fold(0.0, (sum, data) => sum + data.totalCost);
    final totalRevenue =
        _productProfitData.fold(0.0, (sum, data) => sum + data.totalRevenue);
    final totalProfit =
        _productProfitData.fold(0.0, (sum, data) => sum + data.profit);
    final totalQuantity =
        _productProfitData.fold(0, (sum, data) => sum + data.quantity);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F6FA)),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue.withOpacity(0.08);
                }
                return null;
              }),
              columns: const [
                DataColumn(label: Text('Bidhaa')),
                DataColumn(label: Text('Idadi')),
                DataColumn(label: Text('Kununua (TShs)')),
                DataColumn(label: Text('Mauzo (TShs)')),
                DataColumn(label: Text('Faida (TShs)')),
              ],
              rows: [
                ..._productProfitData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final isEven = index % 2 == 0;
                  return DataRow(
                    color: MaterialStateProperty.all(
                        isEven ? const Color(0xFFF5F6FA) : Colors.white),
                    cells: [
                      DataCell(Text(data.productName, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(data.quantity.toString())),
                      DataCell(Text(CurrencyFormatter.format(data.totalCost))),
                      DataCell(Text(CurrencyFormatter.format(data.totalRevenue))),
                      DataCell(Text(CurrencyFormatter.format(data.profit))),
                    ],
                  );
                }),
                // Totals row
                DataRow(
                  color: MaterialStateProperty.all(const Color(0xFFF5F6FA)),
                  cells: [
                    const DataCell(
                        Text('JUMLA', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(totalQuantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(CurrencyFormatter.format(totalCost),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(CurrencyFormatter.format(totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(CurrencyFormatter.format(totalProfit),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black))),
                  ],
                ),
              ],
              clipBehavior: Clip.antiAlias,
            ),
          ),
        );
      },
    );
  }
}

class ProductProfitData {
  final String productId;
  final String productName;
  int quantity;
  final double buyingPrice;
  final double sellingPrice;
  double totalRevenue;
  double totalCost;
  double profit;

  ProductProfitData({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.totalRevenue,
    required this.totalCost,
    required this.profit,
  });
}
