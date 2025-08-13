import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rahisisha/models/business_record.dart';
import 'package:rahisisha/models/inventory_item.dart';
import 'package:rahisisha/models/note.dart';
import 'package:rahisisha/models/customer.dart';
import 'package:rahisisha/providers/inventory_provider.dart';
import 'package:rahisisha/providers/records_provider.dart';
import 'package:rahisisha/providers/notes_provider.dart';
import 'package:rahisisha/providers/customers_provider.dart';
import 'package:rahisisha/services/api_service.dart';
import 'package:rahisisha/services/database_service.dart';
import 'package:rahisisha/utils/app_utils.dart'; 
import 'package:rahisisha/services/api_exception.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final RecordsProvider _recordsProvider;
  final InventoryProvider _inventoryProvider;
  final NotesProvider _notesProvider;
  final CustomersProvider _customersProvider;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.none; // Track last known connectivity

  SyncService(this._apiService, this._databaseService, this._recordsProvider, this._inventoryProvider, this._notesProvider, this._customersProvider);

  void start() async {
    // Perform an initial sync if already connected
    _lastConnectivityResult = await Connectivity().checkConnectivity();
    if (_lastConnectivityResult != ConnectivityResult.none) {
      synchronize();
    }

    // Listen for future connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _lastConnectivityResult == ConnectivityResult.none) {
        // Was offline, now online
        synchronize(showSuccessSnackbar: true);
      } else if (result != ConnectivityResult.none) {
        // Already online, just ensure sync is triggered if needed
        synchronize();
      }
      _lastConnectivityResult = result;
    });
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  Future<void> synchronize({bool showSuccessSnackbar = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    bool uploadedAny = false;
    bool hadDirtyRecords = false; // Track if there were dirty records initially

    try {
      // Check for dirty records before attempting upload
      final initialDirtyRecords = await _databaseService.getDirtyRecords();
      final initialDirtyInventoryItems = await _databaseService.getDirtyInventoryItems();
      final initialDirtyNotes = await _databaseService.getDirtyNotes();
      final initialDirtyCustomers = await _databaseService.getDirtyCustomers();
      hadDirtyRecords = initialDirtyRecords.isNotEmpty || initialDirtyInventoryItems.isNotEmpty || initialDirtyNotes.isNotEmpty || initialDirtyCustomers.isNotEmpty;

      // Upload pending changes
      uploadedAny = await _uploadPendingChanges();

      // Download new data
      await _downloadNewData();

      final currentConnectivity = await Connectivity().checkConnectivity();

      if (showSuccessSnackbar && uploadedAny) {
        AppUtils.showSuccessSnackBar('Data za kwenye simu zimetumwa kwenye server kikamilifu');
      } else if (uploadedAny && currentConnectivity != ConnectivityResult.none) {
        AppUtils.showSuccessSnackBar('Data zimetumwa kwenye server kikamilifu');
      } else if (!uploadedAny && currentConnectivity == ConnectivityResult.none && hadDirtyRecords) {
        // If nothing was uploaded (because offline) but there were dirty records, show local save message
        AppUtils.showSuccessSnackBar('Data zimehifadhiwa kwenye simu yako kikamilifu');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during synchronization: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _uploadPendingChanges() async {
    if (kDebugMode) {
      print('Uploading pending changes...');
    }
    bool uploadedAny = false;

    // Process dirty records
    final dirtyRecords = await _databaseService.getDirtyRecords();
    for (final record in dirtyRecords) {
      try {
        if (record.isDeleted == true) {
          try {
            await _apiService.delete('records/${record.id}');
            await _databaseService.hardDeleteRecord(record.id);
            uploadedAny = true;
            if (kDebugMode) {
              print('Successfully deleted record ${record.id} from API and local DB.');
            }
          } on ApiException catch (apiException) {
            if (apiException.statusCode == 404) {
              // If record not found on server, it means it's already deleted, so hard delete locally
              await _databaseService.hardDeleteRecord(record.id);
              uploadedAny = true;
              if (kDebugMode) {
                print('Record ${record.id} not found on API (404), hard deleted locally.');
              }
            } else {
              // Other API errors, keep as dirty
              if (kDebugMode) {
                print('Failed to delete record ${record.id} from API (status: ${apiException.statusCode}), error: ${apiException.message}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to delete record: ${record.id}, error: $e');
            }
          }
        } else {
          // Handle new or updated records
          final apiResponse = await _apiService.post('records', record.toJson());
          final newRecord = BusinessRecord.fromJson(apiResponse['data']);

          // Delete the old local record (with client-generated ID) if it's different from the new one
          if (record.id != newRecord.id) {
            await _databaseService.hardDeleteRecord(record.id);
          }
          await _databaseService.upsertRecord(newRecord.copyWith(isDirty: false));
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully uploaded/updated record ${record.id} to API. New ID: ${newRecord.id}. Local DB updated.');
          }

          // If this record was associated with an inventory item, mark that item as clean
          if (newRecord.inventoryItemId != null) {
            final associatedItem = await _databaseService.getInventoryItemById(newRecord.inventoryItemId!);
            if (associatedItem != null && associatedItem.isDirty) {
              await _databaseService.upsertInventoryItem(associatedItem.copyWith(isDirty: false));
              if (kDebugMode) {
                print('Marked associated inventory item ${associatedItem.id} as clean after record sync.');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to upload/delete record: ${record.id}, error: $e');
        }
        // Keep the record as dirty/deleted in local DB for future sync attempts
      }
    }

    // Process dirty inventory items (assuming similar logic for isDeleted if applicable)
    final dirtyInventoryItems = await _databaseService.getDirtyInventoryItems();
    for (final item in dirtyInventoryItems) {
      try {
        if (item.isDeleted == true) {
          // Handle deleted inventory items
          await _apiService.delete('inventory/${item.id}');
          await _databaseService.hardDeleteInventoryItem(item.id);
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully deleted inventory item ${item.id} from API and local DB.');
          }
        } else {
          // Handle new or updated inventory items
          final newItemData = await _apiService.post('inventory', item.toJson());
          final newItem = InventoryItem.fromJson(newItemData['data']);
          await _databaseService.upsertInventoryItem(newItem.copyWith(isDirty: false));
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully uploaded/updated inventory item ${item.id} to API and local DB.');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to upload/delete inventory item: ${item.id}, error: $e');
        }
        // Keep the item as dirty/deleted in local DB for future sync attempts
      }
    }

    // Process dirty notes
    final dirtyNotes = await _databaseService.getDirtyNotes();
    for (final note in dirtyNotes) {
      try {
        if (note.isDeleted == true) {
          // Handle deleted notes
          await _apiService.deleteNote(note.id!); // Deletes from API
          // IMPORTANT: Hard delete from local DB using the local Hive key
          await _databaseService.hardDeleteNoteByLocalKey(note.key as int); // Use the correct method
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully deleted note ${note.id} from API and hard deleted from local DB (key: ${note.key}).');
          }
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully deleted note ${note.id} from API and local DB.');
          }
        } else {
          // Handle new or updated notes
          Map<String, dynamic> apiResponse;
          if (note.id == null) { // New note
            apiResponse = await _apiService.addNote(note.toJson()); // Use specific addNote
            final newNote = Note.fromJson(apiResponse['data']);
            // IMPORTANT: Delete the old local note (with client-generated ID)
            // and then upsert the new one (with server-generated ID)
            await _databaseService.hardDeleteNoteByLocalKey(note.key as int); // Delete by local key
            await _databaseService.upsertNote(newNote.copyWith(isDirty: false));
            uploadedAny = true;
            if (kDebugMode) {
              print('Successfully uploaded new note. Old local key: ${note.key}, New server ID: ${newNote.id}. Local DB updated.');
            }
          } else { // Existing note (update)
            apiResponse = await _apiService.updateNote(note.id!, note.toJson()); // Use specific updateNote
            final updatedNote = Note.fromJson(apiResponse['data']); // Get updated data from server
            await _databaseService.upsertNote(updatedNote.copyWith(isDirty: false));
            uploadedAny = true;
            if (kDebugMode) {
              print('Successfully uploaded/updated note ${note.id} to API and local DB.');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to upload/delete note: ${note.id}, error: $e');
        }
        // Keep the note as dirty/deleted in local DB for future sync attempts
      }
    }

    // Process dirty customers
    final dirtyCustomers = await _databaseService.getDirtyCustomers();
    for (final customer in dirtyCustomers) {
      try {
        if (customer.isDeleted == true) {
          // Handle deleted customers
          await _apiService.delete('customers/${customer.id}');
          await _databaseService.hardDeleteCustomer(customer.id!);
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully deleted customer ${customer.id} from API and local DB.');
          }
        } else {
          // Handle new or updated customers
          final apiResponse = await _apiService.post('customers', customer.toJson());
          final newCustomer = Customer.fromJson(apiResponse['data']);

          // Delete the old local customer (with client-generated ID) if it's different from the new one
          if (customer.id != newCustomer.id) {
            await _databaseService.hardDeleteCustomer(customer.id!);
          }
          await _databaseService.upsertCustomer(newCustomer.copyWith(isDirty: false));
          uploadedAny = true;
          if (kDebugMode) {
            print('Successfully uploaded/updated customer ${customer.id} to API. New ID: ${newCustomer.id}. Local DB updated.');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to upload/delete customer: ${customer.id}, error: $e');
        }
        // Keep the customer as dirty/deleted in local DB for future sync attempts
      }
    }

    return uploadedAny;
  }

  Future<void> _downloadNewData() async {
    if (kDebugMode) {
      print('Downloading new data...');
    }

    try {
      final records = await _apiService.getBusinessRecords();
      for (final recordData in records) {
        final record = BusinessRecord.fromJson(recordData);
        await _databaseService.upsertRecord(record);
      }
      _recordsProvider.loadRecords();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download business records: $e');
      }
    }

    try {
      final items = await _apiService.getInventoryItems();
      for (final itemData in items) {
        final item = InventoryItem.fromJson(itemData);
        await _databaseService.upsertInventoryItem(item);
      }
      _inventoryProvider.loadInventory();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download inventory items: $e');
      }
    }

    try {
      final notes = await _apiService.getNotes();
      for (final noteData in notes) {
        final note = Note.fromJson(noteData);
        await _databaseService.upsertNote(note);
      }
      // No need to call _notesProvider.fetchNotes here.
      // The NotesProvider will listen to changes in the local database (on mobile)
      // or fetch directly from API (on web).
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download notes: $e');
      }
    }

    try {
      final customers = await _apiService.get('customers');
      for (final customerData in customers['data']['data']) {
        final customer = Customer.fromJson(customerData);
        await _databaseService.upsertCustomer(customer);
      }
      _customersProvider.loadCustomers();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download customers: $e');
      }
    }
  }
}
