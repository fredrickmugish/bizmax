import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';

class NoteEditSidebar extends StatefulWidget {
  final Note? note;
  final VoidCallback onClose;
  final Function(Note) onSave;

  const NoteEditSidebar({
    Key? key,
    this.note,
    required this.onClose,
    required this.onSave,
  }) : super(key: key);

  @override
  _NoteEditSidebarState createState() => _NoteEditSidebarState();
}

class _NoteEditSidebarState extends State<NoteEditSidebar> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.note == null ? 'Add Note' : 'Edit Note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.note != null)
                TextButton(
                  onPressed: () async {
                    await Provider.of<NotesProvider>(context, listen: false).deleteNote(widget.note!);
                    widget.onClose();
                  },
                  child: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveNote,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Andika kitu kwenye kichwa au maelezo ya note.')),
      );
      return;
    }

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user != null ? authProvider.user!['id']?.toString() : null;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali kujiandika kwa kutumia app.')),
      );
      return;
    }

    Note savedNote;
    if (widget.note == null) {
      savedNote = Note(
        title: title,
        content: content,
        createdAt: DateTime.now(),
        userId: userId,
      );
      await notesProvider.addNote(savedNote);
    } else {
      savedNote = widget.note!.copyWith(
        title: title,
        content: content,
      );
      await notesProvider.updateNote(savedNote);
    }
    widget.onSave(savedNote);
    widget.onClose();
  }
}
