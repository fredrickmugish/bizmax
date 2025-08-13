import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import 'note_edit_screen.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar_scaffold.dart';
import 'note_edit_sidebar.dart';

class NotesScreen extends StatefulWidget {
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  Note? _selectedNote;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user != null ? authProvider.user!['id']?.toString() : null;
      if (userId != null) {
        Provider.of<NotesProvider>(context, listen: false).fetchNotes(userId);
      }
    });
  }

  String? getCurrentUserId(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user != null ? authProvider.user!['id']?.toString() : null;
  }

  void _selectNote(Note? note) {
    setState(() {
      _selectedNote = note;
      _isEditing = true;
    });
  }

  void _closeSidebar() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    Widget notesList = Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (notesProvider.notes.isEmpty) {
          return Center(child: Text('No notes yet.'));
        }
        final filteredNotes = _searchQuery.isEmpty
            ? notesProvider.notes
            : notesProvider.notes.where((note) =>
                note.title.toLowerCase().contains(_searchQuery) ||
                note.content.toLowerCase().contains(_searchQuery)
              ).toList();
        if (filteredNotes.isEmpty) {
          return Center(child: Text('No notes found.'));
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            final note = filteredNotes[index];
            return GestureDetector(
              onTap: () {
                if (isWeb) {
                  _selectNote(note);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
                  );
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title.trim().isNotEmpty)
                      Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (note.title.trim().isNotEmpty && note.content.trim().isNotEmpty)
                      SizedBox(height: 8),
                    if (note.content.trim().isNotEmpty)
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if ((note.title.trim().isNotEmpty || note.content.trim().isNotEmpty))
                      SizedBox(height: 8),
                    Text(
                      '${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}, ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    Widget mainContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search notes',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(child: notesList),
      ],
    );

    if (isWeb) {
      return Row(
        children: [
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Notebook', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.blue,
                elevation: 0,
                automaticallyImplyLeading: true, // Add back button
                iconTheme: const IconThemeData(color: Colors.white), // Ensure back button is white
              ),
              body: mainContent,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  _selectNote(null);
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, size: 36, color: Colors.white),
              ),
            ),
          ),
          if (_isEditing)
            NoteEditSidebar(
              note: _selectedNote,
              onClose: _closeSidebar,
              onSave: (note) {
                // UI will be updated by ValueListenableBuilder
              },
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: mainContent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isWeb) {
            _selectNote(null);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditScreen()),
            );
          }
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, size: 36, color: Colors.white),
      ),
    );
  }
}
