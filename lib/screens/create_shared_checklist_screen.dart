import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_checklist.dart';
import '../data/supabase_repository.dart';
import '../utils/app_activity_logger.dart';

class CreateSharedChecklistScreen extends StatefulWidget {
  const CreateSharedChecklistScreen({super.key});

  @override
  State<CreateSharedChecklistScreen> createState() => _CreateSharedChecklistScreenState();
}

class _CreateSharedChecklistScreenState extends State<CreateSharedChecklistScreen> {
  final _titleController = TextEditingController();
  final List<TextEditingController> _memberControllers = [
    TextEditingController(text: 'Tú'),
  ];
  bool _isLoading = false;

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length > 1) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  Future<void> _createList() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un título para la lista')));
      return;
    }

    final members = _memberControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade al menos un participante (Tú)')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newList = SharedChecklist(
        id: const Uuid().v4(),
        name: title,
        members: members,
        items: [],
        logs: [],
        myMemberName: members.first, // Assuming first is the creator "Tú"
      );

      await SupabaseRepository.createSharedChecklist(newList);
      AppActivityLogger.logCreatedChecklist(title);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Crear lista compartida'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextButton(
              onPressed: _createList,
              child: Text('Crear', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Título de la lista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej. Compra semanal',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Participantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Añade a las personas que tendrán acceso a esta lista. (El primero eres tú).', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            ...List.generate(_memberControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberControllers[index],
                        decoration: InputDecoration(
                          hintText: index == 0 ? 'Tu Nombre' : 'Nombre del participante',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                    ),
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeMemberField(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addMemberField,
              icon: const Icon(Icons.add),
              label: const Text('Añadir participante'),
            ),
          ],
        ),
      ),
    );
  }
}
