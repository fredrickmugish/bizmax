import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/business_record.dart';
import '../widgets/record_list_item.dart';
import '../widgets/records_summary_card.dart';
import '../utils/app_routes.dart';
import '../utils/app_utils.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, RouteAware {
  TabController? _tabController;
  PageRoute? _route;
  String? _lastUserId;
  int _tabCount = 3; // Default to salesperson

  // Period filter state
  String _selectedPeriod = 'Leo';
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadRecords(); // Load all records, no date filter
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register this screen as a route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteObserver<PageRoute> routeObserver = AppUtils.routeObserver;
      routeObserver.subscribe(this, route);
      _route = route;
    }
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role = user != null ? (user['role'] ?? user['data']?['role']) : null;
    final isOwner = role == 'owner';
    final newTabCount = isOwner ? 4 : 1; // 4 for owner, 1 for salesperson
    if (_tabController == null || _tabCount != newTabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: newTabCount, vsync: this);
      _tabCount = newTabCount;
    }
    final userId = user != null ? (user['id'] ?? user['data']?['id'])?.toString() : null;
    _lastUserId = userId;
  }

  @override
  void dispose() {
    if (_route != null) {
      RouteObserver<PageRoute> routeObserver = AppUtils.routeObserver;
      routeObserver.unsubscribe(this);
    }
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload records when returning to this screen
    final provider = context.read<RecordsProvider>();
    if (provider.showTodayOnly) {
      final today = AppUtils.getEastAfricaTime();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      provider.loadRecords(startDate: startOfDay, endDate: endOfDay);
    } else if (provider.startDate != null && provider.endDate != null) {
      provider.loadRecords(startDate: provider.startDate, endDate: provider.endDate);
    } else {
      provider.loadRecords();
    }
  }

  (DateTime, DateTime) _getDateRangeForPeriod(String period) {
    final now = AppUtils.getEastAfricaTime();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'Leo':
        return (today, today);
      case 'Jana':
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, yesterday);
      case 'Wiki hii':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, today);
      case 'Wiki iliyopita':
        final lastWeekStart = today.subtract(Duration(days: today.weekday + 6));
        final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
        return (lastWeekStart, lastWeekEnd);
      case 'Mwezi huu':
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, today);
      case 'Mwezi uliopita':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return (lastMonth, lastMonthEnd);
      case 'Mwaka huu':
        final yearStart = DateTime(now.year, 1, 1);
        return (yearStart, today);
      case 'Mwaka uliopita':
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);
        return (lastYearStart, lastYearEnd);
      case 'Muda maalum':
        if (_customStartDate != null && _customEndDate != null) {
          return (_customStartDate!, _customEndDate!);
        } else {
          return (today.subtract(const Duration(days: 30)), today);
        }
      default:
        return (today, today);
    }
  }

  void _onPeriodSelected(String value) async {
    if (value == 'Muda maalum') {
      final DateTime now = DateTime.now();
      final DateTime lastAllowedDate = DateTime(now.year + 1, 12, 31);
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: lastAllowedDate,
        initialDateRange: _customStartDate != null && _customEndDate != null
            ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
            : DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now,
              ),
      );
      if (picked != null) {
        setState(() {
          _customStartDate = picked.start;
          _customEndDate = picked.end;
          _selectedPeriod = 'Muda maalum';
        });
      }
    } else {
      setState(() {
        _selectedPeriod = value;
      });
    }
  }

  List<BusinessRecord> _filterRecords(List<BusinessRecord> records, String searchQuery) {
    final (start, end) = _getDateRangeForPeriod(_selectedPeriod);
    final endOfRange = end.add(const Duration(days: 1));

    return records.where((record) {
      final isAfterStart = record.date.isAtSameMomentAs(start) || record.date.isAfter(start);
      final isBeforeEnd = record.date.isBefore(endOfRange);
      final matchesSearchQuery = searchQuery.isEmpty ||
          record.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (record.customerName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          (record.supplierName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          record.amount.toString().contains(searchQuery);
      return isAfterStart && isBeforeEnd && matchesSearchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role = user != null ? (user['role'] ?? user['data']?['role']) : null;
    final isOwner = role == 'owner';
    final provider = context.watch<RecordsProvider>();
    final allRecords = provider.allRecords;
    final filtered = _filterRecords(allRecords, provider.searchQuery);
    final salesRecords = filtered.where((r) => r.type == 'sale').toList();
    final purchaseRecords = filtered.where((r) => r.type == 'purchase').toList();
    final expenseRecords = filtered.where((r) => r.type == 'expense').toList();
    final List<Tab> tabs = [
      if (isOwner)
        const Tab(text: 'Zote', icon: Icon(Icons.list)),
      const Tab(text: 'Mauzo', icon: Icon(Icons.point_of_sale)),
      if (isOwner)
        const Tab(text: 'Manunuzi', icon: Icon(Icons.shopping_cart)),
      if (isOwner)
        const Tab(text: 'Matumizi', icon: Icon(Icons.money_off)),
    ];
    final List<Widget> tabViews = [
      if (isOwner)
        _buildRecordsList(filtered, isOwner),
      _buildRecordsList(salesRecords, isOwner),
      if (isOwner)
        _buildRecordsList(purchaseRecords, isOwner),
      if (isOwner)
        _buildRecordsList(expenseRecords, isOwner),
    ];
    // Defensive: If TabController is not ready or mismatched, show loading
    if (_tabController == null || _tabController!.length != tabs.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isSmallWeb = kIsWeb && MediaQuery.of(context).size.width < 840;

    final appBar = AppBar(
      automaticallyImplyLeading: !kIsWeb,
      title: const Text('Rekodi'),
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
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context),
        ),
        PopupMenuButton<String>(
          onSelected: _onPeriodSelected,
          itemBuilder: (context) => _periods
              .map((period) => PopupMenuItem(
                    value: period,
                    child: Text(period),
                  ))
              .toList(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedPeriod,
                    style: const TextStyle(color: Colors.white)),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController!,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: tabs,
      ),
    );

    return Scaffold(
      appBar: appBar,
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Column(
            children: [
              RecordsSummaryCard(
                showPurchases: isOwner,
                showExpenses: isOwner,
                records: filtered,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController!,
                  children: tabViews,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordOptions(context, isOwner),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecordsList(List<BusinessRecord> records, bool isOwner) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.read<RecordsProvider>().searchQuery.isNotEmpty
                  ? 'Hakuna rekodi zinazolingana na utafutaji'
                  : 'Hakuna rekodi za kuonyesha',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: kIsWeb ? 20 : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ongeza rekodi ya kwanza yako',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
                fontSize: kIsWeb ? 16 : null,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddRecordOptions(context, isOwner),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Ongeza Rekodi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Removed the Expanded widget from here!
    return RefreshIndicator(
      onRefresh: () {
        final provider = context.read<RecordsProvider>();
        return provider.loadRecords();
      },
      child: kIsWeb
          ? Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return RecordListItem(
                    record: record,
                    onTap: () => _viewRecordDetails(context, record),
                  );
                },
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return RecordListItem(
                  record: record,
                  onTap: () => _viewRecordDetails(context, record),
                  onEdit: () => _editRecord(context, record),
                  onDelete: () => _deleteRecord(context, record),
                );
              },
            ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final provider = context.read<RecordsProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tafuta Rekodi'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: provider.searchQuery),
          decoration: const InputDecoration(
            hintText: 'Ingiza neno la kutafuta...',
            prefixIcon: Icon(Icons.search),
            helperText: 'Tafuta kwa maelezo, jina la mteja, muuzaji, au kiasi',
          ),
          onChanged: (value) {
            provider.setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.setSearchQuery('');
              Navigator.pop(context);
            },
            child: const Text('Futa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Funga'),
          ),
        ],
      ),
    );
  }

  void _showAddRecordOptions(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.point_of_sale, color: Colors.green),
              title: const Text('Ongeza Mauzo'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.pushNamed(context, AppRoutes.addSale);
                if (result == true && mounted) {
                  final provider = context.read<RecordsProvider>();
                  provider.loadRecords();
                }
              },
            ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                title: const Text('Ongeza Manunuzi'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(context, AppRoutes.addPurchase);
                  if (result == true && mounted) {
                    final provider = context.read<RecordsProvider>();
                    provider.loadRecords();
                  }
                },
              ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('Ongeza Matumizi'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(context, AppRoutes.addExpense);
                  if (result == true && mounted) {
                    final provider = context.read<RecordsProvider>();
                    provider.loadRecords();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewRecordDetails(BuildContext context, BusinessRecord record) {
    Navigator.pushNamed(
      context,
      AppRoutes.recordDetails,
      arguments: record,
    ).then((_) {
      // Reload records after returning from details
      if (mounted) { // Add this check
        final provider = context.read<RecordsProvider>();
        provider.loadRecords();
      }
    });
  }

  void _editRecord(BuildContext context, BusinessRecord record) {
    Navigator.pushNamed(
      context,
      AppRoutes.editRecord,
      arguments: record,
    ).then((_) {
      // Reload records after editing
      final provider = context.read<RecordsProvider>();
      provider.loadRecords();
    });
  }

  void _deleteRecord(BuildContext context, BusinessRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Rekodi'),
        content: Text('Je, una uhakika unataka kufuta rekodi ya "${record.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<RecordsProvider>().deleteRecord(record.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rekodi imefutwa!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hitilafu: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}
