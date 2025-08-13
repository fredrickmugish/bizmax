
import 'package:rahisisha/models/business_record.dart';
import 'package:rahisisha/models/inventory_item.dart';
import 'package:rahisisha/services/api_service.dart';
import 'package:rahisisha/services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:rahisisha/services/insufficient_stock_exception.dart';

class BusinessRepository {
  final ApiService _apiService;
  final DatabaseService? _databaseService;
  final Connectivity _connectivity;

  BusinessRepository(this._apiService, this._databaseService, this._connectivity);

  Future<List<BusinessRecord>> getBusinessRecords() async {
    if (_databaseService == null) {
      // Web implementation: always fetch from API
      final apiRecords = await _apiService.getBusinessRecords();
      return apiRecords.map((e) => BusinessRecord.fromJson(e)).toList();
    }

    List<BusinessRecord> localRecords = await _databaseService!.getAllRecords();
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // Online: Try to fetch from API
      try {
        final apiRecords = await _apiService.getBusinessRecords();
        final recordsFromApi = apiRecords.map((e) => BusinessRecord.fromJson(e)).toList();

        // Get dirty records from local DB
        final dirtyLocalRecords = (await _databaseService!.getDirtyRecords()).where((record) => record.isDeleted != true).toList(); // Filter out locally deleted records
        final dirtyLocalRecordIds = dirtyLocalRecords.map((r) => r.id).toSet();

        // Create a map for quick lookup of API records
        final apiRecordsMap = {for (var record in recordsFromApi) record.id: record};

        // Merge records: API records + local dirty records
        List<BusinessRecord> mergedRecords = [];
        Set<String> mergedRecordIds = {};

        // Add API records first
        for (var record in recordsFromApi) {
          // Only add API records that are not marked as deleted (in case API returns deleted records)
          if (record.isDeleted != true) {
            mergedRecords.add(record.copyWith(isDirty: false, isDeleted: false)); // Ensure API records are clean
            mergedRecordIds.add(record.id);
          }
        }

        // Add local dirty records, prioritizing them if they conflict with API records
        for (var record in dirtyLocalRecords) {
          if (!mergedRecordIds.contains(record.id)) {
            // Only add if not already present from API (meaning it's a new local record or a local update)
            mergedRecords.add(record);
            mergedRecordIds.add(record.id);
          } else {
            // If it's a dirty record that also exists in API, it means it's an update or a deletion pending sync
            // If the local dirty record is marked as deleted, we should remove it from the merged list
            // otherwise, we keep the local dirty version until it's synced
            final index = mergedRecords.indexWhere((r) => r.id == record.id);
            if (index != -1) {
              if (record.isDeleted == true) {
                mergedRecords.removeAt(index); // Remove the record if it's marked for deletion
                mergedRecordIds.remove(record.id); // Also remove from the set
              } else {
                mergedRecords[index] = record; // Keep the local dirty version if it's an update
              }
            }
          }
        }

        // Identify records to be hard deleted from local DB (those not in API and not dirty)
        final recordsToDeleteLocally = localRecords.where((localRecord) =>
            !mergedRecordIds.contains(localRecord.id) && !localRecord.isDirty && localRecord.isDeleted != true
        ).toList();

        // Perform hard deletes for records no longer present on the server and not dirty locally
        for (final record in recordsToDeleteLocally) {
          await _databaseService!.hardDeleteRecord(record.id);
        }

        // Update local database with merged records (upsert)
        for (final record in mergedRecords) {
          await _databaseService!.upsertRecord(record);
        }

        if (kDebugMode) {
          print('BusinessRepository: Fetched ${recordsFromApi.length} business records from API and merged with ${dirtyLocalRecords.length} dirty local records. Total merged: ${mergedRecords.length}');
        }
        return mergedRecords;
      } catch (e) {
        if (kDebugMode) {
          print('BusinessRepository: Failed to fetch business records from API ($e). Returning local records.');
        }
        // Fallback to local records if API fetch fails
        return localRecords;
      }
    } else {
      // Offline: Return local records directly
      if (kDebugMode) {
        print('BusinessRepository: Offline. Returning ${localRecords.length} business records from local storage.');
      }
      return localRecords;
    }
  }

  Future<Map<String, dynamic>> addBusinessRecordToApi(BusinessRecord record) async {
    final apiResponse = await _apiService.addBusinessRecord(record.toJson());
    return apiResponse;
  }

  Future<void> insertRecordLocally(BusinessRecord record) async {
    if (_databaseService == null) return;
    // Only update stock if the record is dirty (meaning it's an offline record being saved locally for the first time)
    if (record.isDirty && record.inventoryItemId != null && record.quantity != null) {
      await _updateInventoryStock(record);
    }
    await _databaseService!.insertRecord(record);
  }

  Future<Map<String, dynamic>> updateBusinessRecordInApi(BusinessRecord record) async {
    return await _apiService.updateBusinessRecord(record.id!, record.toJson());
  }

  Future<bool> deleteBusinessRecord(String id) async {
    if (_databaseService == null) {
      // Web implementation: always use API
      await _apiService.deleteBusinessRecord(id);
      return true;
    }
    try {
      await _apiService.deleteBusinessRecord(id);
      await _databaseService!.hardDeleteRecord(id); // Hard delete from local DB after successful API delete
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete business record from API, marking locally as dirty and deleted: $e');
      }
      final recordToDelete = await _databaseService!.getRecordById(id);
      if (recordToDelete != null) {
        await _databaseService!.upsertRecord(recordToDelete.copyWith(isDirty: true, isDeleted: true));
        return true; // Local marking for deletion was successful
      }
      // If record not found locally or local upsert fails, rethrow
      rethrow;
    }
  }

  Future<void> deleteBusinessRecordFromApi(String id) async {
    await _apiService.deleteBusinessRecord(id);
  }

  Future<void> deleteRecordLocally(String id) async {
    if (_databaseService == null) return;
    await _databaseService!.deleteRecord(id);
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    if (_databaseService == null) {
      // Web implementation: always fetch from API
      final apiItems = await _apiService.getInventoryItems();
      return apiItems.map((e) => InventoryItem.fromJson(e)).toList();
    }

    List<InventoryItem> localItems = await _databaseService!.getAllInventoryItems();
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // Online: Try to fetch from API
      try {
        final apiItems = await _apiService.getInventoryItems();
        final itemsFromApi = apiItems.map((e) => InventoryItem.fromJson(e)).toList();

        // Get dirty inventory items from local DB
        final dirtyLocalItems = await _databaseService!.getDirtyInventoryItems();
        final dirtyLocalItemIds = dirtyLocalItems.map((item) => item.id).toSet();

        // Create a map for quick lookup of API items
        final apiItemsMap = {for (var item in itemsFromApi) item.id: item};

        // Merge items: API items + local dirty items
        List<InventoryItem> mergedItems = [];
        Set<String> mergedItemIds = {};

        // Add API items first
        for (var item in itemsFromApi) {
          mergedItems.add(item.copyWith(isDirty: false, isDeleted: false)); // Ensure API items are clean
          mergedItemIds.add(item.id);
        }

        // Add local dirty items, prioritizing them if they conflict with API items
        for (var item in dirtyLocalItems) {
          if (!mergedItemIds.contains(item.id)) {
            // Only add if not already present from API (meaning it's a new local item or a local update)
            mergedItems.add(item);
            mergedItemIds.add(item.id);
          } else {
            // If it's a dirty item that also exists in API, it means it's an update
            // We should keep the local dirty version until it's synced
            final index = mergedItems.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              mergedItems[index] = item;
            }
          }
        }

        // Identify items to be hard deleted from local DB (those not in API and not dirty)
        final itemsToDeleteLocally = localItems.where((localItem) =>
            !mergedItemIds.contains(localItem.id) && !localItem.isDirty && localItem.isDeleted != true
        ).toList();

        // Perform hard deletes for items no longer present on the server and not dirty locally
        for (final item in itemsToDeleteLocally) {
          await _databaseService!.hardDeleteInventoryItem(item.id);
        }

        // Update local database with merged items (upsert)
        for (final item in mergedItems) {
          await _databaseService!.upsertInventoryItem(item);
        }

        if (kDebugMode) {
          print('BusinessRepository: Fetched ${itemsFromApi.length} inventory items from API and merged with ${dirtyLocalItems.length} dirty local items. Total merged: ${mergedItems.length}');
        }
        return mergedItems;
      } catch (e) {
        if (kDebugMode) {
          print('BusinessRepository: Failed to fetch inventory items from API ($e). Returning local items.');
        }
        // Fallback to local items if API fetch fails
        return localItems;
      }
    } else {
      // Offline: Return local items directly
      if (kDebugMode) {
        print('BusinessRepository: Offline. Returning ${localItems.length} inventory items from local storage.');
      }
      return localItems;
    }
  }

  Future<void> _updateInventoryStock(BusinessRecord record) async {
    if (_databaseService == null) return;
    if (record.inventoryItemId == null || record.quantity == null) {
      return; // No inventory item or quantity to update
    }

    InventoryItem? item = await _databaseService!.getInventoryItemById(record.inventoryItemId!);

    if (item == null) {
      // If item is not found locally, try fetching from API if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          final apiItem = await _apiService.getInventoryItemById(record.inventoryItemId!);
          item = InventoryItem.fromJson(apiItem);
          await _databaseService!.upsertInventoryItem(item.copyWith(isDirty: false)); // Save fetched item locally
        } catch (e) {
          if (kDebugMode) {
            print('Failed to fetch inventory item ${record.inventoryItemId} from API: $e');
          }
          throw Exception('Inventory item not found: ${record.inventoryItemId}');
        }
      } else {
        throw Exception('Inventory item not found locally and offline: ${record.inventoryItemId}');
      }
    }

    int newStock = item!.currentStock;

    if (record.type == 'sale') {
      if (item.currentStock < record.quantity!) {
        throw InsufficientStockException('Hifadhi haitoshi kwa ${item.name}. Zilizopo: ${item.currentStock}, Unazohitaji: ${record.quantity}');
      }
      newStock = item.currentStock - record.quantity!;
    } else if (record.type == 'purchase') {
      newStock = item.currentStock + record.quantity!;
    } else {
      return; // Only update stock for sales and purchases
    }

    final updatedItem = item.copyWith(currentStock: newStock, isDirty: true);

    // Update locally and mark as dirty. SyncService will handle API update.
    await _databaseService!.upsertInventoryItem(updatedItem);
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    if (_databaseService == null) {
      // Web implementation: always use API
      await _apiService.addInventoryItem(item.toJson());
      return;
    }
    try {
      final apiResponse = await _apiService.addInventoryItem(item.toJson());
      final newItem = InventoryItem.fromJson(apiResponse['data']);
      await _databaseService!.insertInventoryItem(newItem.copyWith(isDirty: false));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add inventory item to API, saving locally as dirty: $e');
      }
      await _databaseService!.insertInventoryItem(item.copyWith(isDirty: true));
      rethrow; // Re-throw to propagate the error to the UI
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    await _apiService.deleteInventoryItem(id);
  }
}
