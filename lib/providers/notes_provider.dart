
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:rahisisha/models/note.dart';
import 'package:rahisisha/services/api_service.dart';
import 'package:rahisisha/services/database_service.dart';
import 'package:rahisisha/services/sync_service.dart'; // Import SyncService

class NotesProvider with ChangeNotifier {
  final ApiService _apiService;
  SyncService? _syncService; // Add SyncService field
  List<Note> _notes = [];
  bool _isLoading = false;

  NotesProvider(this._apiService);

  // Add setter for SyncService
  void setSyncService(SyncService syncService) {
    _syncService = syncService;
  }

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> fetchNotes(String userId) async {
    _isLoading = true;

    if (kIsWeb) {
      try {
        final notesData = await _apiService.getNotes();
        _notes = notesData.map((data) => Note.fromJson(data)).toList();
      } catch (error) {
        // Handle error
      }
    } else {
      final box = await Hive.openBox<Note>('notes');
      _notes = box.values
          .where((note) => note.userId == userId && note.isDeleted == false)
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    if (kIsWeb) {
      try {
        final response = await _apiService.addNote(note.toJson());
        _notes.add(Note.fromJson(response['data']));
      } catch (error) {
        // Handle error
      }
    } else {
      // For mobile, mark as dirty and save to local DB
      final newNote = note.copyWith(isDirty: true);
      await DatabaseService.instance.upsertNote(newNote);
      _notes.add(newNote);
      if (_syncService != null) {
        _syncService!.synchronize();
      }
    }
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    if (kIsWeb) {
      try {
        await _apiService.updateNote(note.id!, note.toJson());
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = note;
        }
      } catch (error) {
        // Handle error
      }
    } else {
      // For mobile, mark as dirty and save to local DB
      final updatedNote = note.copyWith(isDirty: true);
      await DatabaseService.instance.upsertNote(updatedNote);
      final index = _notes.indexWhere((n) => n.key == note.key);
       if (index != -1) {
        _notes[index] = updatedNote;
      }
      if (_syncService != null) {
        _syncService!.synchronize();
      }
    }
    notifyListeners();
  }

  Future<void> deleteNote(Note note) async {
    if (kIsWeb) {
      try {
        await _apiService.deleteNote(note.id!);
        _notes = List.from(_notes)..removeWhere((n) => n.id == note.id);
      } catch (error) {
        // Handle error
      }
    } else {
      // For mobile, mark as deleted and dirty in local DB
      await DatabaseService.instance.deleteNote(note.id!); // This marks isDeleted and isDirty
      _notes = List.from(_notes)..removeWhere((n) => n.id == note.id); // Remove from current list for immediate UI update
      if (_syncService != null) {
        _syncService!.synchronize();
      }
    }
    notifyListeners();
  }
}
