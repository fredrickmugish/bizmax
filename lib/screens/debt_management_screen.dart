import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../models/business_record.dart';
import '../utils/currency_formatter.dart';
import 'record_details_screen.dart';
import 'package:flutter/foundation.dart';
import '../widgets/sidebar_scaffold.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({Key? key}) : super(key: key);

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  String _filterType = 'all'; // 'all', 'unpaid', 'partial', 'paid'
  String _debtSectionFilter = 'all'; // 'all', 'unaowadai', 'wanaokudai'
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tafuta jina la mteja...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Usimamizi wa Madeni'),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showSectionFilterOptions,
            ),
          ],
        ],
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get all credit sales (Unaowadai)
          final creditSales = provider.allRecords
              .where((record) => record.type == 'sale' && record.isCredit)
              .toList();

          // Get all credit purchases (Wanaokudai)
          final creditPurchases = provider.allRecords
              .where((record) => record.type == 'purchase' && record.isCredit)
              .toList();

          // Sort by date (newest first)
          creditSales.sort((a, b) => b.date.compareTo(a.date));
          creditPurchases.sort((a, b) => b.date.compareTo(a.date));

          // Apply search filter
          final searchedSales = _searchQuery.isEmpty
              ? creditSales
              : creditSales.where((sale) =>
                  (sale.customerName ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())
                ).toList();

          final searchedPurchases = _searchQuery.isEmpty
              ? creditPurchases
              : creditPurchases.where((purchase) =>
                  (purchase.supplierName ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())
                ).toList();

          final filteredSales = _filterCreditSales(searchedSales);
          final filteredPurchases = _filterCreditPurchases(searchedPurchases);

          if (creditSales.isEmpty && creditPurchases.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Hakuna Madeni ya Mkopo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Madeni ya mkopo yataonekana hapa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Unaowadai (Sales)
                if ((_debtSectionFilter == 'all' || _debtSectionFilter == 'unaowadai') && creditSales.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.person, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Unaowadai (Wateja)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  _buildSummaryCards(creditSales),
                  _buildFilterChips(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildDebtCard(sale);
                    },
                  ),
                ],
                // Wanaokudai (Purchases)
                if ((_debtSectionFilter == 'all' || _debtSectionFilter == 'wanaokudai') && creditPurchases.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.business, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Wanaokudai (Wasambazaji)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  _buildSummaryCardsPurchases(creditPurchases),
                  _buildFilterChipsPurchases(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPurchases.length,
                    itemBuilder: (context, index) {
                      final purchase = filteredPurchases[index];
                      return _buildDebtCardPurchase(purchase);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<BusinessRecord> creditSales) {
    final totalDebt = creditSales.fold<double>(
        0, (sum, sale) => sum + sale.remainingDebt);
    final totalCreditSales = creditSales.fold<double>(
        0, (sum, sale) => sum + sale.saleTotal);
    final totalPaid = creditSales.fold<double>(
        0, (sum, sale) => sum + sale.paidAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Jumla ya Madeni',
              CurrencyFormatter.format(totalDebt),
              Icons.warning_amber,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Jumla ya Mkopo',
              CurrencyFormatter.format(totalCreditSales),
              Icons.credit_card,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Kilicholipwa',
              CurrencyFormatter.format(totalPaid),
              Icons.payment,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Zote'),
            _buildFilterChip('unpaid', 'Hawajalipa'),
            _buildFilterChip('partial', 'Sehemu'),
            _buildFilterChip('paid', 'Waliolipa'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterType = value;
          });
        },
        selectedColor: Colors.orange.shade100,
        checkmarkColor: Colors.orange,
      ),
    );
  }

  Widget _buildDebtCard(BusinessRecord sale) {
    final statusColor = _getStatusColor(sale);
    final daysAgo = DateTime.now().difference(sale.date).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/record-details',
            arguments: sale,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName ?? 'Mteja',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sale.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.paymentStatus ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow(
                      'Jumla ya Mauzo:',
                      CurrencyFormatter.format(sale.saleTotal),
                      Colors.black,
                    ),
                    const SizedBox(height: 6),
                    _buildPaymentRow(
                      'Kilicholipwa:',
                      CurrencyFormatter.format(sale.paidAmount),
                      Colors.green,
                    ),
                    const Divider(height: 16),
                    _buildPaymentRow(
                      'Deni Lililobaki:',
                      CurrencyFormatter.format(sale.remainingDebt),
                      sale.remainingDebt > 0 ? Colors.red : Colors.green,
                      isDebt: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Footer row
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${sale.date.day}/${sale.date.month}/${sale.date.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    daysAgo == 0 ? 'Leo' : '$daysAgo siku zilizopita',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (sale.remainingDebt > 0) ...[
                    TextButton.icon(
                      onPressed: () => _showPaymentDialog(sale),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Lipa'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, Color color, {bool isDebt = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isDebt ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isDebt ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<BusinessRecord> _filterCreditSales(List<BusinessRecord> creditSales) {
    switch (_filterType) {
      case 'unpaid':
        return creditSales.where((sale) => sale.paidAmount == 0).toList();
      case 'partial':
        return creditSales.where((sale) => sale.paidAmount > 0 && sale.remainingDebt > 0).toList();
      case 'paid':
        return creditSales.where((sale) => sale.remainingDebt <= 0).toList();
      default:
        return creditSales;
    }
  }

  Color _getStatusColor(BusinessRecord sale) {
    if (sale.remainingDebt <= 0) return Colors.green;
    if (sale.paidAmount > 0) return Colors.orange;
    return Colors.red;
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'unpaid':
        return 'hawajalipa';
      case 'partial':
        return 'waliolipa sehemu';
      case 'paid':
        return 'waliolipa kamili';
      default:
        return 'zote';
    }
  }

  void _showSectionFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chagua Aina ya Madeni',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionFilterOption('all', 'Zote', Icons.layers),
            _buildSectionFilterOption('unaowadai', 'Unaowadai (Wateja)', Icons.person, Colors.orange),
            _buildSectionFilterOption('wanaokudai', 'Wanaokudai (Wasambazaji)', Icons.business, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionFilterOption(String value, String title, IconData icon, [Color? color]) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        setState(() => _debtSectionFilter = value);
        Navigator.pop(context);
      },
      selected: _debtSectionFilter == value,
    );
  }

  void _showPaymentDialog(BusinessRecord sale) {
    final paymentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lipa Deni - ${sale.customerName}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maelezo ya Deni:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Bidhaa: ${sale.description}'),
                    Text('Jumla: ${CurrencyFormatter.format(sale.saleTotal)}'),
                    Text('Kilicholipwa: ${CurrencyFormatter.format(sale.paidAmount)}'),
                    Text(
                      'Deni: ${CurrencyFormatter.format(sale.remainingDebt)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: paymentController,
                decoration: const InputDecoration(
                  labelText: 'Kiasi cha Malipo (TSH)',
                  hintText: 'Ingiza kiasi kilicholipwa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingiza kiasi cha malipo';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingiza kiasi sahihi';
                  }
                  if (amount > sale.remainingDebt) {
                    return 'Kiasi hakiwezi kuzidi deni lililobaki';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _processPayment(sale, paymentController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lipa'),
          ),
        ],
      ),
    );
  }

  void _processPayment(BusinessRecord sale, String paymentText) {
    final paymentAmount = double.parse(paymentText);
    
    // Calculate new amounts
    final newPaidAmount = sale.paidAmount + paymentAmount;
    final newDebtAmount = sale.saleTotal - newPaidAmount;
    
    // Update the sale record
    final updatedSale = sale.copyWith(
      amountPaid: newPaidAmount,
      debtAmount: newDebtAmount > 0 ? newDebtAmount : 0,
      amount: newPaidAmount, // Update income amount
      updatedAt: DateTime.now(),
    );

    // Update the record
    context.read<RecordsProvider>().updateRecord(updatedSale);
    
    Navigator.pop(context);
    
    // Show success message
    String message = 'Malipo ya ${CurrencyFormatter.format(paymentAmount)} yamehifadhiwa!';
    if (newDebtAmount <= 0) {
      message += '\n🎉 Deni limekamilika!';
    } else {
      message += '\nDeni lililobaki: ${CurrencyFormatter.format(newDebtAmount)}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<BusinessRecord> _filterCreditPurchases(List<BusinessRecord> creditPurchases) {
    switch (_filterType) {
      case 'unpaid':
        return creditPurchases.where((purchase) => purchase.paidAmount == 0).toList();
      case 'partial':
        return creditPurchases.where((purchase) => purchase.paidAmount > 0 && purchase.remainingDebt > 0).toList();
      case 'paid':
        return creditPurchases.where((purchase) => purchase.remainingDebt <= 0).toList();
      default:
        return creditPurchases;
    }
  }

  Widget _buildSummaryCardsPurchases(List<BusinessRecord> creditPurchases) {
    final totalDebt = creditPurchases.fold<double>(
        0, (sum, purchase) => sum + purchase.remainingDebt);
    final totalCreditPurchases = creditPurchases.fold<double>(
        0, (sum, purchase) => sum + purchase.saleTotal);
    final totalPaid = creditPurchases.fold<double>(
        0, (sum, purchase) => sum + purchase.paidAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Jumla ya Madeni',
              CurrencyFormatter.format(totalDebt),
              Icons.warning_amber,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Jumla ya Mkopo',
              CurrencyFormatter.format(totalCreditPurchases),
              Icons.credit_card,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Kilicholipwa',
              CurrencyFormatter.format(totalPaid),
              Icons.payment,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsPurchases() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Zote'),
            _buildFilterChip('unpaid', 'Hujalipa'),
            _buildFilterChip('partial', 'Sehemu'),
            _buildFilterChip('paid', 'Umeshalipa'),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCardPurchase(BusinessRecord purchase) {
    final statusColor = _getStatusColor(purchase);
    final daysAgo = DateTime.now().difference(purchase.date).inDays;
    String paymentStatus;
    if (purchase.remainingDebt <= 0) {
      paymentStatus = 'Umeshalipa';
    } else if (purchase.paidAmount > 0) {
      paymentStatus = 'Sehemu';
    } else {
      paymentStatus = 'Hujalipa';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordDetailsScreen(record: purchase),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.supplierName ?? 'Msambazaji',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purchase.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Payment status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      paymentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Payment breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow(
                      'Jumla ya Manunuzi:',
                      CurrencyFormatter.format(purchase.saleTotal),
                      Colors.black,
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentRow(
                      'Kilicholipwa:',
                      CurrencyFormatter.format(purchase.paidAmount),
                      Colors.green,
                    ),
                    const Divider(),
                    _buildPaymentRow(
                      'Deni Lililobaki:',
                      CurrencyFormatter.format(purchase.remainingDebt),
                      purchase.remainingDebt > 0 ? Colors.red : Colors.green,
                      isDebt: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Footer row (date and Lipa button)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${purchase.date.day}/${purchase.date.month}/${purchase.date.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    daysAgo == 0 ? 'Leo' : '$daysAgo siku zilizopita',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (purchase.remainingDebt > 0) ...[
                    TextButton.icon(
                      onPressed: () => _showPaymentDialog(purchase),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Lipa'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
