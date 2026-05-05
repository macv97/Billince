import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/checklist_item.dart';
import '../data/app_data.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ShoppingListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {

  // ── Add Item Options ─────────────────────────────────────
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Añadir Elemento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF0F172A)),
                  ),
                  title: const Text('Escribir manualmente', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Escribe el nombre del producto'),
                  onTap: () {
                    Navigator.pop(context);
                    _addItemManually();
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFFF59E0B)),
                  ),
                  title: const Text('Escanear con cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Haz una foto a una lista escrita'),
                  onTap: () {
                    Navigator.pop(context);
                    _processImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Subir imagen de galería', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Selecciona una foto de una lista'),
                  onTap: () {
                    Navigator.pop(context);
                    _processImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addItemManually() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Añadir producto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej. Leche, Pan, Huevos...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  widget.shoppingList.items.insert(0, ChecklistItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  // ── Toggle / Delete ──────────────────────────────────────
  void _toggleItem(int index) {
    setState(() {
      widget.shoppingList.items[index].isDone = !widget.shoppingList.items[index].isDone;
    });
  }

  void _deleteItem(String id) {
    setState(() {
      widget.shoppingList.items.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elemento eliminado'), duration: Duration(seconds: 1)),
    );
  }

  // ── OCR Scan (extracts product names, no prices) ─────────
  Future<void> _processImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Analizando con IA...')),
        ]),
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      List<ChecklistItem> extractedItems = [];
      final lines = recognizedText.blocks.expand((b) => b.lines).toList();

      for (var line in lines.take(20)) {
        final text = line.text.trim();
        // Skip very short lines, lines that are only numbers/symbols, or header-like lines
        if (text.length > 2 && !RegExp(r'^[\d\s\*\-\.,:€\$£]+$').hasMatch(text)) {
          // Remove trailing price patterns if present (e.g. "Leche 1.20" → "Leche")
          final cleanedText = text.replaceAll(RegExp(r'\s+\d+[\.,]\d+\s*$'), '').trim();
          if (cleanedText.length > 2) {
            extractedItems.add(ChecklistItem(
              id: '${DateTime.now().millisecondsSinceEpoch}${extractedItems.length}',
              title: cleanedText,
            ));
          }
        }
      }

      textRecognizer.close();
      Navigator.pop(context);

      if (extractedItems.isNotEmpty) {
        setState(() => widget.shoppingList.items.insertAll(0, extractedItems));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡${extractedItems.length} productos detectados!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se detectaron productos.')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = widget.shoppingList.items;
    final doneCount = items.where((i) => i.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shoppingList.title),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress bar
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: items.isEmpty ? 0 : doneCount / items.length,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$doneCount/${items.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'La lista está vacía.\n¡Añade productos o escanea una foto!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) => _deleteItem(item.id),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          color: item.isDone ? Colors.grey.shade100 : Colors.white,
                          child: ListTile(
                            onTap: () => _toggleItem(index),
                            leading: Checkbox(
                              value: item.isDone,
                              onChanged: (value) => _toggleItem(index),
                              activeColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                                color: item.isDone ? Colors.grey : Colors.black87,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                              onPressed: () => _deleteItem(item.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Añadir elemento'),
      ),
    );
  }
}
