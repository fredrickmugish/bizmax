import 'package:flutter/foundation.dart';
import 'package:rahisisha/models/inventory_item.dart';
import 'package:rahisisha/repositories/business_repository.dart';
import 'package:rahisisha/services/sync_service.dart'; // Import SyncService
import 'package:rahisisha/utils/app_utils.dart'; // Import AppUtils
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus

class InventoryProvider with ChangeNotifier {
  final BusinessRepository _businessRepository;
  SyncService? _syncService; // Make it nullable

  // Add a setter for SyncService
  void setSyncService(SyncService syncService) {
    _syncService = syncService;
  }

  List<InventoryItem> _items = [];
  List<InventoryItem> _lowStockItems = []; // New field for low stock items
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  InventoryProvider(this._businessRepository);

  // Getters
  List<InventoryItem> get items => _items;
  List<InventoryItem> get lowStockItems {
    print('InventoryProvider: lowStockItems getter called. Returning ${_lowStockItems.length} items.');
    return _lowStockItems;
  } // Getter for low stock items
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<InventoryItem> get filteredItems {
    var filtered = _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory && item.isDeleted != true;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<String> get categories {
    final List<String> cats = ['All']; // Start with 'All'

    // Filter out null and empty categories before adding to the unique list
    final uniqueCategories = _items
        .map((item) => item.category)
        .where((category) => category != null && category.isNotEmpty) // <--- ADD THIS FILTER
        .toSet()
        .toList();

    cats.addAll(uniqueCategories.cast<String>()); // Ensure all are String (though the filter handles this)
    return cats;
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _businessRepository.getInventoryItems();
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadItems() => loadInventory();

  void setLowStockItems(List<InventoryItem> items) {
    _lowStockItems = items;
    print('InventoryProvider: setLowStockItems called with ${items.length} items.');
    notifyListeners();
  }

  Future<bool> addProduct(InventoryItem item) async {
    try {
      final dirtyItem = item.copyWith(isDirty: true);
      await _businessRepository.addInventoryItem(dirtyItem);

      // Correctly update state without reloading
      _items.insert(0, dirtyItem); // Add to the top
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
      notifyListeners();

      if (!kIsWeb && _syncService != null) {
        _syncService!.synchronize();
      }
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<void> addItem(InventoryItem item) => addProduct(item);

  Future<bool> updateProduct(InventoryItem item) async {
    try {
      final dirtyItem = item.copyWith(isDirty: true);
      await _businessRepository.addInventoryItem(dirtyItem);

      // Correctly update state without reloading
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = dirtyItem;
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Ensure order
        notifyListeners();
      }

      if (!kIsWeb && _syncService != null) {
        _syncService!.synchronize();
      }
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<void> updateItem(InventoryItem item) => updateProduct(item);

  Future<bool> deleteProduct(String id) async {
    try {
      if (kIsWeb) {
        await _businessRepository.deleteInventoryItem(id);
      } else {
        final connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.none) {
          AppUtils.showErrorSnackBar('Ingia online ili kufuta bidhaa');
          return false;
        }
        await _businessRepository.deleteInventoryItem(id);
      }

      // Correctly update state without reloading
      _items.removeWhere((i) => i.id == id);
      notifyListeners();

      if (!kIsWeb && _syncService != null) {
        _syncService!.synchronize();
      }
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      AppUtils.showErrorSnackBar('Hitilafu: ${e.toString()}');
      return false;
    }
  }

  Future<void> deleteItem(String id) => deleteProduct(id);

  Future<void> updateStock(String id, int newStock) async {
    try {
      final item = _items.firstWhere((item) => item.id == id);
      final updatedItem = item.copyWith(currentStock: newStock);
      await updateProduct(updatedItem);
    } catch (e) {
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  InventoryItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  void setItems(List<InventoryItem> items) {
    _items = items;
    notifyListeners();
  }
}
