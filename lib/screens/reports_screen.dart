import 'package:rahisisha/services/report_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../utils/currency_formatter.dart';
import '../providers/inventory_provider.dart';
import '../providers/records_provider.dart';
import 'package:flutter/foundation.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Mwezi huu';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final recordsProvider = context.read<RecordsProvider>();
      final reportsProvider = context.read<ReportsProvider>();

      // Start loading reports immediately, which will set isLoading to true
      reportsProvider.loadReports(selectedPeriod: _selectedPeriod); // This call will now initiate loading state

      // Ensure records are loaded before reports are calculated (ReportsProvider will wait for this)
      await recordsProvider.loadRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallWeb = kIsWeb && MediaQuery.of(context).size.width < 840;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !kIsWeb,
        title: const Text('Ripoti za Biashara'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: isSmallWeb
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : null,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Muda maalum') {
                final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: context.read<ReportsProvider>().customStartDate != null &&
                          context.read<ReportsProvider>().customEndDate != null
                      ? DateTimeRange(
                          start: context.read<ReportsProvider>().customStartDate!,
                          end: context.read<ReportsProvider>().customEndDate!)
                      : DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                );

                if (picked != null) {
                  context.read<ReportsProvider>().setCustomDateRange(picked.start, picked.end);
                  setState(() {
                    _selectedPeriod = 'Muda maalum';
                  });
                  context.read<ReportsProvider>().loadReports(selectedPeriod: 'Muda maalum');
                  context.read<ReportsProvider>().refreshReports(selectedPeriod: 'Muda maalum');
                }
              } else {
                setState(() {
                  _selectedPeriod = value;
                });
                context.read<ReportsProvider>().loadReports(selectedPeriod: value);
                context.read<ReportsProvider>().refreshReports(selectedPeriod: value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Leo', child: Text('Leo')),
              const PopupMenuItem(value: 'Jana', child: Text('Jana')),
              const PopupMenuItem(value: 'Wiki hii', child: Text('Wiki hii')),
              const PopupMenuItem(value: 'Wiki iliyopita', child: Text('Wiki iliyopita')),
              const PopupMenuItem(value: 'Mwezi huu', child: Text('Mwezi huu')),
              const PopupMenuItem(value: 'Mwezi uliopita', child: Text('Mwezi uliopita')),
              const PopupMenuItem(value: 'Mwaka huu', child: Text('Mwaka huu')),
              const PopupMenuItem(value: 'Mwaka uliopita', child: Text('Mwaka uliopita')),
              const PopupMenuItem(value: 'Muda maalum', child: Text('Muda maalum')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final reportsProvider = context.read<ReportsProvider>();
              final inventoryProvider = context.read<InventoryProvider>();
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              DateTime? startDate;
              DateTime? endDate;

              switch (_selectedPeriod) {
                case 'Leo':
                  startDate = today;
                  endDate = today;
                  break;
                case 'Jana':
                  final yesterday = today.subtract(const Duration(days: 1));
                  startDate = yesterday;
                  endDate = yesterday;
                  break;
                case 'Wiki hii':
                  startDate = today.subtract(Duration(days: today.weekday - 1));
                  endDate = today;
                  break;
                case 'Wiki iliyopita':
                  startDate = today.subtract(Duration(days: today.weekday + 6));
                  endDate = today.subtract(Duration(days: today.weekday));
                  break;
                case 'Mwezi huu':
                  startDate = DateTime(now.year, now.month, 1);
                  endDate = today;
                  break;
                case 'Mwezi uliopita':
                  startDate = DateTime(now.year, now.month - 1, 1);
                  endDate = DateTime(now.year, now.month, 0);
                  break;
                case 'Mwaka huu':
                  startDate = DateTime(now.year, 1, 1);
                  endDate = today;
                  break;
                case 'Mwaka uliopita':
                  startDate = DateTime(now.year - 1, 1, 1);
                  endDate = DateTime(now.year - 1, 12, 31);
                  break;
                case 'Muda maalum':
                  startDate = reportsProvider.customStartDate;
                  endDate = reportsProvider.customEndDate;
                  break;
              }

              ReportService.generateReport(reportsProvider, inventoryProvider, _selectedPeriod, startDate, endDate);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Muhtasari', icon: Icon(Icons.dashboard)),
            Tab(text: 'Mauzo', icon: Icon(Icons.trending_up)),
            Tab(text: 'Manunuzi', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Matumizi', icon: Icon(Icons.trending_down)),
            Tab(text: 'Hifadhi', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider),
              _buildSalesTab(provider),
              _buildPurchasesTab(provider),
              _buildExpensesTab(provider),
              _buildInventoryTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(ReportsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsCards(provider),
          const SizedBox(height: 20),
          _buildMonthlyTrendsChart(provider),
          // const SizedBox(height: 20),
          // _buildRevenueChart(provider),
          // const SizedBox(height: 20),
          // _buildProfitChart(provider),
        ],
      ),
    );
  }

  Widget _buildSalesTab(ReportsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesMetrics(provider),
          const SizedBox(height: 20),
          _buildSalesChart(provider),
          const SizedBox(height: 20),
          _buildTopProductsChart(provider),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(ReportsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpensesMetrics(provider),
          const SizedBox(height: 20),
          _buildExpensesChart(provider),
        ],
      ),
    );
  }

  Widget _buildInventoryTab(ReportsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInventoryMetrics(provider),
          const SizedBox(height: 20),
          _buildStockLevelsChart(provider),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab(ReportsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPurchasesMetrics(provider),
          const SizedBox(height: 20),
          _buildPurchasesChart(provider),
          const SizedBox(height: 20),
          _buildTopPurchasesChart(provider),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(ReportsProvider provider) {
    return Column(
      children: [
        // First row - Revenue and Expenses
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Jumla ya Mauzo',
                CurrencyFormatter.format(provider.metrics.totalRevenue),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Jumla ya Matumizi',
                CurrencyFormatter.format(provider.metrics.totalExpenses),
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - Gross Profit and Net Profit
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Faida ya Mauzo',
                CurrencyFormatter.format(provider.metrics.totalGrossProfit),
                Icons.account_balance_wallet,
                Colors.blue,
                subtitle: 'Mauzo - Gharama ya Bidhaa',
              ),

            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Faida baada ya Matumizi',
                CurrencyFormatter.format(provider.metrics.totalNetProfit),
                Icons.account_balance_wallet,
                Colors.purple,
                subtitle: 'Faida ya Mauzo - Matumizi',
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
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
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(ReportsProvider provider) {
    final trends = provider.monthlyTrends;
    final titles = _getChartTitles();

    if (trends.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mwelekeo wa Mauzo kwa Miezi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Hakuna data ya miezi ya hivi karibuni',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mwelekeo wa Mauzo kwa Miezi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxMonthlyTrends(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatWithoutSymbol(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < titles.length) {
                            return Text(
                              titles[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateMonthlyTrendsBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildRevenueChart(ReportsProvider provider) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Mwelekeo wa Mauzo kwa Siku',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 20),
  //           SizedBox(
  //             height: 200,
  //             child: BarChart(
  //               BarChartData(
  //                 alignment: BarChartAlignment.spaceAround,
  //                 maxY: _calculateMaxRevenue(),
  //                 barTouchData: BarTouchData(enabled: true),
  //                 titlesData: FlTitlesData(
  //                   leftTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 60,
  //                       getTitlesWidget: (value, meta) {
  //                         return Text(
  //                           CurrencyFormatter.formatWithoutSymbol(value),
  //                           style: const TextStyle(fontSize: 10),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   bottomTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       getTitlesWidget: (value, meta) {
  //                         final days = ['Jum', 'Jmt', 'Jmn', 'Alh', 'Iju', 'Jma', 'Jpi'];
  //                         if (value.toInt() < days.length) {
  //                           return Text(days[value.toInt()]);
  //                         }
  //                         return const Text('');
  //                       },
  //                     ),
  //                   ),
  //                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                 ),
  //                 borderData: FlBorderData(show: false),
  //                 barGroups: _generateRevenueBars(),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildProfitChart(ReportsProvider provider) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Mwelekeo wa Faida',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 20),
  //           SizedBox(
  //             height: 200,
  //             child: BarChart(
  //               BarChartData(
  //                 alignment: BarChartAlignment.spaceAround,
  //                 maxY: _calculateMaxProfit(),
  //                 barTouchData: BarTouchData(enabled: true),
  //                 titlesData: FlTitlesData(
  //                   leftTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 60,
  //                       getTitlesWidget: (value, meta) {
  //                         return Text(
  //                           CurrencyFormatter.formatWithoutSymbol(value),
  //                           style: const TextStyle(fontSize: 10),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   bottomTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       getTitlesWidget: (value, meta) {
  //                         return Text('${value.toInt() + 1}');
  //                       },
  //                     ),
  //                   ),
  //                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                 ),
  //                 borderData: FlBorderData(show: false),
  //                 barGroups: _generateProfitBars(),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSalesMetrics(ReportsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Mauzo ya Leo',
            CurrencyFormatter.format(provider.metrics.todayRevenue),
            Icons.today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Jumla ya Mauzo',
            CurrencyFormatter.format(provider.metrics.totalRevenue),
            Icons.trending_up,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart(ReportsProvider provider) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mauzo kwa Siku',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxSales(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatWithoutSymbol(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < 7) {
                            final date = dates[index];
                            return Text(DateFormat.E().format(date)); // E.g., Mon, Tue
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateSalesBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(ReportsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bidhaa Zinazouzwa Zaidi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateTopProductsSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPieChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesMetrics(ReportsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Matumizi za Leo',
            CurrencyFormatter.format(provider.metrics.todayExpenses),
            Icons.money_off,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Jumla ya Matumizi',
            CurrencyFormatter.format(provider.metrics.totalExpenses),
            Icons.receipt_long,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesChart(ReportsProvider provider) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matumizi kwa Siku',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxExpenses(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatWithoutSymbol(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < 7) {
                            final date = dates[index];
                            return Text(DateFormat.E().format(date)); // E.g., Mon, Tue
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateExpensesBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryMetrics(ReportsProvider provider) {
    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.items;
    final totalProducts = allItems.length;
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Bidhaa Chini',
            '$lowStockItems',
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Jumla ya Bidhaa',
            '$totalProducts',
            Icons.inventory,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStockLevelsChart(ReportsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hali ya Hifadhi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateStockLevelSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStockLevelLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockChart(ReportsProvider provider) {
    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.items;
    final totalProducts = allItems.length;
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).length;
    final normalStockItems = totalProducts - lowStockItems;

    if (totalProducts == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hali ya Hifadhi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Hakuna data ya hifadhi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final normalPercentage = totalProducts > 0 ? (normalStockItems / totalProducts * 100) : 0;
    final lowPercentage = totalProducts > 0 ? (lowStockItems / totalProducts * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hali ya Hifadhi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: normalPercentage.toDouble(),
                      title: 'Hifadhi Nzuri\n${normalPercentage.toInt()}%',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: lowPercentage.toDouble(),
                      title: 'Hifadhi Chini\n${lowPercentage.toInt()}%',
                      color: Colors.orange,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartLegend() {
    final provider = context.read<ReportsProvider>();
    final topProducts = provider.topSellingProducts.take(4).toList();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];

    if (topProducts.isEmpty) {
      return const Center(
        child: Text(
          'Hakuna data ya bidhaa',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: topProducts.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final productName = product['name'] ?? 'Bidhaa ${index + 1}';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              productName.length > 8 ? '${productName.substring(0, 8)}...' : productName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Data generation methods for charts - Updated to use real data
  List<FlSpot> _generateRevenueSpots() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();

    // Use real revenue data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyRevenue = _getDailyRevenue(date, provider);
      spots.add(FlSpot((6 - i).toDouble(), dailyRevenue));
    }

    return spots;
  }

  List<FlSpot> _generateSalesSpots() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();

    // Use real sales data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailySales = _getDailySales(date, provider);
      spots.add(FlSpot((6 - i).toDouble(), dailySales));
    }

    return spots;
  }

  List<FlSpot> _generateExpensesSpots() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();

    // Use real expenses data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyExpenses = _getDailyExpenses(date, provider);
      spots.add(FlSpot((6 - i).toDouble(), dailyExpenses));
    }

    return spots;
  }

  double _getDailyRevenue(DateTime date, ReportsProvider provider) {
    // Use real daily revenue data
    final revenueByPeriod = provider.revenueByPeriod;
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // If we have specific daily data, use it
    return revenueByPeriod[dateKey] ?? 0;
  }

  double _getDailySales(DateTime date, ReportsProvider provider) {
    // Use real daily sales data (same as revenue for now)
    return _getDailyRevenue(date, provider);
  }

  double _getDailyPurchases(DateTime date, ReportsProvider provider) {
    final purchasesByPeriod = provider.purchasesByPeriod;
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return purchasesByPeriod[dateKey] ?? 0;
  }

  double _getDailyExpenses(DateTime date, ReportsProvider provider) {
    final expensesByPeriod = provider.expensesByPeriod;
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return expensesByPeriod[dateKey] ?? 0;
  }

  List<PieChartSectionData> _generateTopProductsSections() {
    // Use real top products data from the provider
    final provider = context.read<ReportsProvider>();
    final topProducts = provider.topSellingProducts;

    if (topProducts.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          title: 'Hakuna Data',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Take top 4 products
    final top4Products = topProducts.take(4).toList();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];

    // Calculate total revenue for percentage calculation
    final totalRevenue = top4Products.fold<double>(
      0, (sum, product) => sum + (product['revenue'] ?? 0.0));

    return top4Products.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;
      final revenue = product['revenue'] ?? 0.0;
      final percentage = totalRevenue > 0 ? (revenue / totalRevenue * 100) : 0;

      return PieChartSectionData(
        value: percentage,
        title: '${percentage.toInt()}%',
        color: colors[index],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _generateStockLevelBars() {
    // Use real inventory data from the provider
    final provider = context.read<ReportsProvider>();
    final totalProducts = provider.metrics.totalProducts ?? 0;
    final lowStockItems = provider.metrics.lowStockItems;
    final normalStockItems = totalProducts - lowStockItems;

    if (totalProducts == 0) {
      return [
        BarChartGroupData(
          x: 0,
          barRods: [BarChartRodData(toY: 1, color: Colors.grey, width: 20, borderRadius: BorderRadius.zero)],
        ),
      ];
    }

    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: normalStockItems.toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: lowStockItems.toDouble(),
            color: Colors.red,
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
    ];
  }

  // New method to generate monthly trends chart data
  List<FlSpot> _generateMonthlyTrendsSpots() {
    final provider = context.read<ReportsProvider>();
    final trends = provider.monthlyTrends;
    final spots = <FlSpot>[];

    for (int i = 0; i < trends.length; i++) {
      final trend = trends[i];
      final revenue = trend['sales'] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return spots;
  }

  // New method to get chart titles based on real data
  List<String> _getChartTitles() {
    final provider = context.read<ReportsProvider>();
    final trends = provider.monthlyTrends;

    return trends.map((trend) {
      final monthKey = trend['month'] ?? '';
      // Convert "2024-01" to "Jan 2024"
      if (monthKey.contains('-')) {
        final parts = monthKey.split('-');
        if (parts.length == 2) {
          final year = parts[0];
          final month = int.tryParse(parts[1]) ?? 1;
          final monthNames = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          return '${monthNames[month - 1]} $year';
        }
      }
      return monthKey;
    }).map((e) => e.toString()).toList();
  }

  double _calculateMaxMonthlyTrends() {
    final provider = context.read<ReportsProvider>();
    final trends = provider.monthlyTrends;
    final maxValue = trends.fold<double>(0, (max, trend) {
      final revenue = trend['sales'] ?? 0.0;
      return revenue > max ? revenue : max;
    });

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  double _calculateMaxRevenue() {
    final provider = context.read<ReportsProvider>();
    final revenueByPeriod = provider.revenueByPeriod;
    final maxValue = revenueByPeriod.values.fold<double>(0, (max, revenue) {
      return revenue > max ? revenue : max;
    });

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  double _calculateMaxProfit() {
    final provider = context.read<ReportsProvider>();
    final maxValue = [
      provider.metrics.totalRevenue,
      provider.metrics.totalExpenses,
      provider.metrics.totalProfit,
    ].reduce((a, b) => a > b ? a : b);

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  // New methods for bar charts
  List<BarChartGroupData> _generateMonthlyTrendsBars() {
    final provider = context.read<ReportsProvider>();
    final trends = provider.monthlyTrends;
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.indigo];

    if (trends.isEmpty) {
      return [
        BarChartGroupData(
          x: 0,
          barRods: [BarChartRodData(toY: 1, color: Colors.grey, width: 20)],
        ),
      ];
    }

    return trends.asMap().entries.map((entry) {
      final index = entry.key;
      final trend = entry.value;
      final revenue = trend['sales'] ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: revenue,
            color: colors[index % colors.length],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _generateRevenueBars() {
    final spots = <BarChartGroupData>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();
    final colors = [Colors.green, Colors.lightGreen, Colors.greenAccent, Colors.teal, Colors.cyan, Colors.blue, Colors.indigo];

    // Use real revenue data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyRevenue = _getDailyRevenue(date, provider);
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dailyRevenue,
            color: colors[i],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return spots;
  }

  List<BarChartGroupData> _generateSalesBars() {
    final spots = <BarChartGroupData>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();
    final colors = [Colors.green, Colors.lightGreen, Colors.greenAccent, Colors.teal, Colors.cyan, Colors.blue, Colors.indigo];

    // Use real sales data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailySales = _getDailySales(date, provider);
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dailySales,
            color: colors[i],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return spots;
  }

  List<BarChartGroupData> _generateExpensesBars() {
    final spots = <BarChartGroupData>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();
    final colors = [Colors.red, Colors.redAccent, Colors.deepOrange, Colors.orange, Colors.amber, Colors.yellow, Colors.orangeAccent];

    // Use real expenses data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyExpenses = _getDailyExpenses(date, provider);
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dailyExpenses,
            color: colors[i],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return spots;
  }

  List<BarChartGroupData> _generateProfitBars() {
    final spots = <BarChartGroupData>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();
    final colors = [Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue, Colors.cyan, Colors.teal, Colors.green];

    // Generate profit data for the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyRevenue = _getDailyRevenue(date, provider);
      final dailyExpenses = _getDailyExpenses(date, provider);
      final dailyProfit = dailyRevenue - dailyExpenses;
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dailyProfit,
            color: colors[i],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return spots;
  }

  double _calculateMaxSales() {
    final provider = context.read<ReportsProvider>();
    final revenueByPeriod = provider.revenueByPeriod;
    final maxValue = revenueByPeriod.values.fold<double>(0, (max, revenue) {
      return revenue > max ? revenue : max;
    });

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  double _calculateMaxExpenses() {
    final provider = context.read<ReportsProvider>();
    final totalExpenses = provider.metrics.totalExpenses;
    final todayExpenses = provider.metrics.todayExpenses;
    final maxValue = totalExpenses > todayExpenses ? totalExpenses : todayExpenses;

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  // New methods for pie charts
  List<PieChartSectionData> _generateExpensesCategorySections() {
    final provider = context.read<ReportsProvider>();
    final expensesByCategory = provider.expensesByCategory;

    if (expensesByCategory.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          title: 'Hakuna Data',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Convert map to list and sort by value
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 4 categories
    final topCategories = sortedCategories.take(4).toList();
    final colors = [Colors.red, Colors.orange, Colors.purple, Colors.teal];

    // Calculate total expenses for percentage calculation
    final totalExpenses = topCategories.fold<double>(
      0, (sum, category) => sum + category.value);

    return topCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = totalExpenses > 0 ? (category.value / totalExpenses * 100) : 0;

      return PieChartSectionData(
        value: percentage.toDouble(),
        title: '${percentage.toInt()}%',
        color: colors[index],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _generateStockLevelSections() {
    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.items;
    final totalProducts = allItems.length;
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).length;
    final normalStockItems = totalProducts - lowStockItems;

    if (totalProducts == 0) {
      return [
        PieChartSectionData(
          value: 100,
          title: 'Hakuna Data',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    final normalPercentage = totalProducts > 0 ? (normalStockItems / totalProducts * 100) : 0;
    final lowPercentage = totalProducts > 0 ? (lowStockItems / totalProducts * 100) : 0;

    return [
      PieChartSectionData(
        value: normalPercentage.toDouble(),
        title: 'Hifadhi Nzuri\n${normalPercentage.toInt()}%',
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: lowPercentage.toDouble(),
        title: 'Hifadhi Chini\n${lowPercentage.toInt()}%',
        color: Colors.orange,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildTopPurchasesLegend() {
    final provider = context.read<ReportsProvider>();
    final topPurchases = provider.topPurchases;

    if (topPurchases.isEmpty) {
      return const Center(
        child: Text(
          'Hakuna data ya manunuzi',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: topPurchases.take(4).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final purchase = entry.value;
        final productName = purchase['name'] ?? 'Manunuzi ${index + 1}';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: [Colors.blue, Colors.green, Colors.orange, Colors.red][index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              productName.length > 8 ? '${productName.substring(0, 8)}...' : productName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _generatePurchasesBars() {
    final spots = <BarChartGroupData>[];
    final now = DateTime.now();
    final provider = context.read<ReportsProvider>();
    final colors = [Colors.blue, Colors.indigo, Colors.purple, Colors.deepPurple, Colors.cyan, Colors.teal, Colors.blueAccent];

    // Use real purchases data from the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyPurchases = _getDailyPurchases(date, provider);
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: dailyPurchases,
            color: colors[i],
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return spots;
  }

  
  
  Widget _buildPurchasesMetrics(ReportsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Manunuzi ya Leo',
            CurrencyFormatter.format(provider.metrics.todayPurchases ?? 0),
            Icons.shopping_cart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Jumla ya Manunuzi',
            CurrencyFormatter.format(provider.metrics.totalPurchases ?? 0),
            Icons.shopping_basket,
            Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasesChart(ReportsProvider provider) {
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manunuzi kwa Siku',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxPurchases(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatWithoutSymbol(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < 7) {
                            final date = dates[index];
                            return Text(DateFormat.E().format(date)); // E.g., Mon, Tue
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generatePurchasesBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPurchasesChart(ReportsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bidhaa Zinazonunuliwa Zaidi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateTopPurchasesSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTopPurchasesLegend(),
          ],
        ),
      ),
    );
  }

  double _calculateMaxPurchases() {
    final provider = context.read<ReportsProvider>();
    final totalPurchases = provider.metrics.totalPurchases ?? 0;
    final todayPurchases = provider.metrics.todayPurchases ?? 0;
    final maxValue = totalPurchases > todayPurchases ? totalPurchases : todayPurchases;

    // Add 20% padding to the top
    return maxValue * 1.2;
  }

  List<PieChartSectionData> _generateTopPurchasesSections() {
    final provider = context.read<ReportsProvider>();
    final topPurchases = provider.topPurchases;

    if (topPurchases.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          title: 'Hakuna Data',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Take top 4 purchases
    final top4Purchases = topPurchases.take(4).toList();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];

    // Calculate total purchases for percentage calculation
    final totalPurchases = top4Purchases.fold<double>(
      0, (sum, purchase) => sum + (purchase['revenue'] ?? 0.0));

    return top4Purchases.asMap().entries.map((entry) {
      final index = entry.key;
      final purchase = entry.value;
      final revenue = purchase['revenue'] ?? 0.0;
      final percentage = totalPurchases > 0 ? (revenue / totalPurchases * 100) : 0;

      return PieChartSectionData(
        value: percentage,
        title: '${percentage.toInt()}%',
        color: colors[index],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildStockLevelLegend() {
    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.items;
    final totalProducts = allItems.length;
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).length;
    final normalStockItems = totalProducts - lowStockItems;

    if (totalProducts == 0) {
      return const Center(
        child: Text(
          'Hakuna data ya hifadhi',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Hifadhi Nzuri ($normalStockItems)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Hifadhi Chini ($lowStockItems)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}