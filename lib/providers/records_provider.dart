import 'package:flutter/foundation.dart';
import 'package:rahisisha/models/business_record.dart';
import 'package:rahisisha/repositories/business_repository.dart';
import 'package:rahisisha/utils/app_utils.dart';
import 'package:rahisisha/services/sync_service.dart'; // Import SyncService
import 'package:rahisisha/services/api_exception.dart';
import 'package:rahisisha/services/insufficient_stock_exception.dart';

class RecordsProvider with ChangeNotifier {
  final BusinessRepository _businessRepository;
  SyncService? _syncService; // Make it nullable

  // Add a setter for SyncService
  void setSyncService(SyncService syncService) {
    _syncService = syncService;
  }

  List<BusinessRecord> _records = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showTodayOnly = true;
  String? _lastLoadedUserId;

  RecordsProvider(this._businessRepository) { // Remove syncService from constructor
    final today = AppUtils.getEastAfricaTime();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    _startDate = startOfDay;
    _endDate = endOfDay;
    _showTodayOnly = true;
  }

  // Getters
  List<BusinessRecord> get allRecords => _records;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get showTodayOnly => _showTodayOnly;
  String? get lastLoadedUserId => _lastLoadedUserId;

  List<BusinessRecord> get filteredRecords {
    print('Filtering records: showTodayOnly=$_showTodayOnly, startDate=$_startDate, endDate=$_endDate, searchQuery=$_searchQuery');

    var filtered = _records.where((record) {
      // Search functionality
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = record.description.toLowerCase().contains(query) ||
            (record.customerName?.toLowerCase().contains(query) ?? false) ||
            (record.supplierName?.toLowerCase().contains(query) ?? false) ||
            (record.category?.toLowerCase().contains(query) ?? false) ||
            record.amount.toString().contains(query) ||
            record.quantity.toString().contains(query);
      }

      // Date filtering
      bool matchesDate = true;
      if (_showTodayOnly) {
        final today = AppUtils.getEastAfricaTime();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        matchesDate = (record.date.isAtSameMomentAs(startOfDay) || record.date.isAfter(startOfDay)) && record.date.isBefore(endOfDay);
      } else if (_startDate != null && _endDate != null) {
        final endOfRange = _endDate!.add(const Duration(days: 1));
        matchesDate = (record.date.isAtSameMomentAs(_startDate!) || record.date.isAfter(_startDate!)) && record.date.isBefore(endOfRange);
      }

      return matchesSearch && matchesDate;
    }).toList();

    // Sort by creation time in descending order (latest first - newest on top)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  List<BusinessRecord> get salesRecords => filteredRecords.where((r) => r.type == 'sale').toList();
  List<BusinessRecord> get purchaseRecords => filteredRecords.where((r) => r.type == 'purchase').toList();
  List<BusinessRecord> get expenseRecords => filteredRecords.where((r) => r.type == 'expense').toList();

  // totalSales now correctly sums the total amount (which is already unit price × quantity)
  double get totalSales {
    return salesRecords.fold(0.0, (sum, record) => sum + record.amount);
  }

  // totalPurchases now correctly sums the total amount (which is already unit price × quantity)
  double get totalPurchases {
    return purchaseRecords.fold(0.0, (sum, record) => sum + record.amount);
  }

  double get totalExpenses {
    return expenseRecords.fold(0.0, (sum, record) => sum + record.amount);
  }

  /// Calculates the **Gross Profit**: (Total Sales Revenue) - (Total Cost of Goods Sold for Sales).
  /// This requires `costOfGoodsSold` and `quantity` to be present for each 'sale' record.
  double get totalGrossProfit {
    double grossProfit = 0.0;
    for (var record in salesRecords) {
      // Gross Profit per item = (Selling Price - Cost of Goods Sold) * Quantity
      // Ensure costOfGoodsSold and quantity are available for accurate calculation.
      if (record.costOfGoodsSold != null && record.quantity != null) {
        grossProfit += (record.amount - record.costOfGoodsSold!) * record.quantity!;
      } else {
        // Log a warning if data is missing, as it impacts the accuracy of gross profit.
        // You might want to display this warning in the UI for the user.
        print('Warning: Sale record ID ${record.id} is missing costOfGoodsSold or quantity. This record will be excluded from gross profit calculation.');
      }
    }
    return grossProfit;
  }

  /// Calculates the **Operating Profit**: Gross Profit - Total Operating Expenses.
  /// This replaces the previous `totalProfit` getter.
  double get totalOperatingProfit => totalGrossProfit - totalExpenses;

  // Load records
  Future<void> loadRecords({DateTime? startDate, DateTime? endDate, String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _businessRepository.getBusinessRecords();
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort here
      _lastLoadedUserId = userId;
      print('Loaded record types: ' + _records.map((r) => r.type).toList().toString());
      print('✅ Loaded  [32m [1m [4m${'records.length'} [0m records into provider');
    } catch (e) {
      print('❌ Error loading records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add record
  Future<bool> addRecord(BusinessRecord record) async {
    try {
      // Attempt to send to API first
      final apiResponse = await _businessRepository.addBusinessRecordToApi(record);
      final recordFromApi = BusinessRecord.fromJson(apiResponse['data']);

      // If API call is successful, save to local DB with isDirty: false
      if (!kIsWeb) {
        await _businessRepository.insertRecordLocally(recordFromApi.copyWith(isDirty: false));
      }
      
      // Update local state
      _records.insert(0, recordFromApi); // Add to the top
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
      notifyListeners();
      
      return true;
    } on InsufficientStockException catch (e) {
      AppUtils.showErrorSnackBar(e.message);
      return false;
    } on ApiException catch (e) {
      // If API call fails, save to local DB with isDirty: true and let SyncService handle it
      print('API Exception adding record: ${e.message}. Saving locally for sync.');
      try {
        if (!kIsWeb) {
          await _businessRepository.insertRecordLocally(record.copyWith(isDirty: true));
        }
        
        // Update local state
        _records.insert(0, record.copyWith(isDirty: true)); // Add to the top
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();

        if (!kIsWeb && _syncService != null) {
          _syncService!.synchronize(); // Trigger sync for dirty records
        }
        return true; // Indicate that local save was successful
      } on InsufficientStockException catch (stockException) {
        AppUtils.showErrorSnackBar(stockException.message);
        return false;
      } catch (localSaveError) {
        print('Error saving record locally after API failure: $localSaveError');
        AppUtils.showErrorSnackBar('Hitilafu: Hitilafu imetokea wakati wa kuhifadhi baadhi ya data kwenye simu');
        return false;
      }
    } catch (e) {
      print('Error adding record: $e');
      // Fallback for other unexpected errors, save locally as dirty
      try {
        if (!kIsWeb) {
          await _businessRepository.insertRecordLocally(record.copyWith(isDirty: true));
        }
        
        // Update local state
        _records.insert(0, record.copyWith(isDirty: true)); // Add to the top
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();

        if (!kIsWeb && _syncService != null) {
          _syncService!.synchronize(); // Trigger sync for dirty records
        }
        return true; // Indicate that local save was successful
      } on InsufficientStockException catch (stockException) {
        AppUtils.showErrorSnackBar(stockException.message);
        return false;
      } catch (localSaveError) {
        print('Error saving record locally after general error: $localSaveError');
        AppUtils.showErrorSnackBar('Hitilafu: Hitilafu imetokea wakati wa kuhifadhi baadhi ya data kwenye simu');
        return false;
      }
    }
  }

  // Update record
  Future<void> updateRecord(BusinessRecord record) async {
    try {
      // Attempt to send to API first
      final apiResponse = await _businessRepository.updateBusinessRecordInApi(record);
      final recordFromApi = BusinessRecord.fromJson(apiResponse['data']);

      // If API call is successful, save to local DB with isDirty: false
      if (!kIsWeb) {
        await _businessRepository.insertRecordLocally(recordFromApi.copyWith(isDirty: false));
      }

      // Correctly update state without reloading
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = recordFromApi;
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();
      }
    } on ApiException catch (e) {
      // If API call fails, save to local DB with isDirty: true and let SyncService handle it
      print('API Exception updating record: ${e.message}. Saving locally for sync.');
      if (!kIsWeb) {
        await _businessRepository.insertRecordLocally(record.copyWith(isDirty: true));
      }

      // Correctly update state without reloading
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record.copyWith(isDirty: true);
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();
      }
      if (!kIsWeb && _syncService != null) {
        _syncService!.synchronize(); // Trigger sync for dirty records
      }
      rethrow; // Re-throw to propagate the error to the UI
    } catch (e) {
      print('Error updating record: $e');
      // Fallback for other unexpected errors, save locally as dirty
      if (!kIsWeb) {
        await _businessRepository.insertRecordLocally(record.copyWith(isDirty: true));
      }

      // Correctly update state without reloading
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record.copyWith(isDirty: true);
        _records.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();
      }
      if (!kIsWeb && _syncService != null) {
        _syncService!.synchronize(); // Trigger sync for dirty records
      }
      rethrow;
    }
  }

  // Delete record
  Future<bool> deleteRecord(String id) async {
    try {
      print('Attempting to delete record with ID: $id');
      final bool success = await _businessRepository.deleteBusinessRecord(id);

      if (success) {
        // If deletion (API or local marking) was successful
        _records.removeWhere((r) => r.id == id);
        notifyListeners();

        if (!kIsWeb && _syncService != null) {
          _syncService!.synchronize(); // Trigger sync for dirty records
        }
        return true;
      } else {
        // This else block should ideally only be hit if local marking for deletion failed,
        // which is unlikely given the current BusinessRepository implementation.
        AppUtils.showErrorSnackBar('Hitilafu wakati wa kufuta rekodi.');
        return false;
      }
    } catch (e) {
      print('Error deleting record: $e');
      AppUtils.showErrorSnackBar('Hitilafu: ${e.toString()}');
      return false;
    }
  }

  // Filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _showTodayOnly = false; // Switch to custom date range
    print('Date range set: ${start.toString()} to ${end.toString()}');
    print('Show today only: $_showTodayOnly');

    // Reload records from server with the new date range
    loadRecords(startDate: start, endDate: end);
  }

  void showAllRecords() {
    _showTodayOnly = false;
    _startDate = null;
    _endDate = null;
    // Reload all records from server
    loadRecords();
  }

  void clearFilters() {
    _searchQuery = '';
    final today = AppUtils.getEastAfricaTime();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    _startDate = startOfDay;
    _endDate = endOfDay;
    _showTodayOnly = true;
    loadRecords(startDate: startOfDay, endDate: endOfDay);
  }

  // Returns a list of unique customer names from sales records
  List<String> get uniqueCustomers {
    return _records
        .where((r) => r.type == 'sale' && r.customerName != null && r.customerName!.isNotEmpty)
        .map((r) => r.customerName!)
        .toSet()
        .toList();
  }

  void clearRecords() {
    _records = [];
    _lastLoadedUserId = null;
    notifyListeners();
  }

  void setRecords(List<BusinessRecord> records) {
    _records = records;
    notifyListeners();
  }
}
