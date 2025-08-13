import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  static const String backupVersion = '1.0';

  static Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
    } catch (e) {
      print('Error initializing backup service: $e');
    }
  }

  Future<String> createBackup() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupData = await _collectBackupData();
      
      final directory = await getExternalStorageDirectory();
      final backupDir = Directory('${directory!.path}/rahisisha');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final backupFile = File('${backupDir.path}/rahisisha_backup_$timestamp.json');
      await backupFile.writeAsString(jsonEncode(backupData));
      
      return backupFile.path;
    } catch (e) {
      throw Exception('Hitilafu katika kuunda backup: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _collectBackupData() async {
    try {
      final db = DatabaseService.instance;
      
      List<BusinessRecord> businessRecords = [];
      try {
        businessRecords = await db.getAllBusinessRecords();
      } catch (e) {
        print('Error getting business records: $e');
        businessRecords = [];
      }
      
      List<InventoryItem> inventoryItems = [];
      try {
        inventoryItems = await db.getAllInventoryItems();
      } catch (e) {
        print('Error getting inventory items: $e');
        inventoryItems = [];
      }
      
      return {
        'version': backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'business_name': await _getBusinessName(),
        'data': {
          'business_records': businessRecords.map((r) => r.toJson()).toList(),
          'inventory_items': inventoryItems.map((i) => i.toJson()).toList(),
        },
      };
    } catch (e) {
      throw Exception('Hitilafu katika kukusanya data: ${e.toString()}');
    }
  }

  Future<String> _getBusinessName() async {
    try {
      return 'Biashara Yangu';
    } catch (e) {
      return 'Biashara Yangu';
    }
  }

  Future<void> shareBackup() async {
    try {
      final backupPath = await createBackup();
      final file = File(backupPath);
      
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(backupPath)],
          text: 'Backup ya data za biashara - Rahisisha App',
          subject: 'Rahisisha Backup',
        );
      } else {
        throw Exception('Faili la backup halipo');
      }
    } catch (e) {
      throw Exception('Hitilafu katika kushiriki backup: ${e.toString()}');
    }
  }

  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('Faili la backup halipo');
      }

      final backupContent = await file.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      await _validateBackupData(backupData);
      await _restoreData(backupData);
      
    } catch (e) {
      throw Exception('Hitilafu katika kurejesha backup: ${e.toString()}');
    }
  }

  Future<void> _validateBackupData(Map<String, dynamic> backupData) async {
    if (!backupData.containsKey('version') || 
        !backupData.containsKey('data')) {
      throw Exception('Faili la backup si sahihi');
    }
    
    final version = backupData['version'];
    if (version != backupVersion) {
      print('Warning: Backup version mismatch. Expected: $backupVersion, Found: $version');
    }
  }

  Future<void> _restoreData(Map<String, dynamic> backupData) async {
    try {
      final db = DatabaseService.instance;
      final data = backupData['data'] as Map<String, dynamic>;
      
      if (data.containsKey('business_records')) {
        final records = data['business_records'] as List;
        for (var recordJson in records) {
          try {
            final record = BusinessRecord.fromJson(recordJson as Map<String, dynamic>);
            await db.saveBusinessRecord(record);
          } catch (e) {
            print('Error restoring business record: $e');
          }
        }
      }
      
      if (data.containsKey('inventory_items')) {
        final items = data['inventory_items'] as List;
        for (var itemJson in items) {
          try {
            final item = InventoryItem.fromJson(itemJson as Map<String, dynamic>);
            await db.insertInventoryItem(item);
          } catch (e) {
            print('Error restoring inventory item: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Hitilafu katika kurejesha data: ${e.toString()}');
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      final directory = await getExternalStorageDirectory();
      final backupDir = Directory('${directory!.path}/rahisisha');
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = backupDir.listSync()
          .where((file) => file is File && file.path.contains('rahisisha_backup_'))
          .map((file) => file.path)
          .toList();
      
      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      print('Error getting available backups: $e');
      return [];
    }
  }

  Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Hitilafu katika kufuta backup: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return null;
      }

      final backupContent = await file.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      return {
        'version': backupData['version'],
        'created_at': backupData['created_at'],
        'business_name': backupData['business_name'],
        'file_size': await file.length(),
        'records_count': (backupData['data']['business_records'] as List?)?.length ?? 0,
        'items_count': (backupData['data']['inventory_items'] as List?)?.length ?? 0,
      };
    } catch (e) {
      print('Error getting backup info: $e');
      return null;
    }
  }

  Future<void> scheduleAutoBackup() async {
    try {
      await createBackup();
      print('Auto backup created successfully');
      } catch (e) {
      print('Error creating auto backup: $e');
    }
  }

  Future<bool> validateBackupFile(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return false;
      }

      final backupContent = await file.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      await _validateBackupData(backupData);
      return true;
    } catch (e) {
      print('Backup validation failed: $e');
      return false;
    }
  }

  Future<void> cleanOldBackups({int keepCount = 5}) async {
    try {
      final backups = await getAvailableBackups();
      if (backups.length > keepCount) {
        final backupsToDelete = backups.skip(keepCount);
        for (final backupPath in backupsToDelete) {
          await deleteBackup(backupPath);
        }
      }
    } catch (e) {
      print('Error cleaning old backups: $e');
    }
  }
}