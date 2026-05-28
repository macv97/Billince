import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/checklist_item.dart';
import '../data/local_database.dart';
import '../services/ticket_scanner.dart';
import 'package:image_cropper/image_cropper.dart';

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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Text('Añadir Producto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.edit_rounded, color: Colors.blue),
                ),
                title: const Text('Escribir manualmente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Escribe el nombre del producto'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditItemDialog();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.amber),
                ),
                title: const Text('Escanear con cámara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Haz una foto a una lista escrita'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.green),
                ),
                title: const Text('Subir de galería', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Selecciona una foto de tu móvil'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditItemDialog({ChecklistItem? existingItem}) {
    final controller = TextEditingController(text: existingItem?.title ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existingItem == null ? 'Añadir producto' : 'Editar producto'),
        content: TextField(
          controller: controller,
          autofocus: existingItem == null,
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
                if (existingItem != null) {
                  setState(() {
                    existingItem.title = title;
                  });
                  LocalDatabase.updateChecklistItem(existingItem, widget.shoppingList.id);
                } else {
                  final newItem = ChecklistItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                  );
                  setState(() {
                    widget.shoppingList.items.insert(0, newItem);
                  });
                  LocalDatabase.insertChecklistItem(newItem, widget.shoppingList.id);
                }
              }
              Navigator.pop(context);
            },
            child: Text(existingItem == null ? 'Añadir' : 'Guardar'),
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
    LocalDatabase.updateChecklistItem(widget.shoppingList.items[index], widget.shoppingList.id);
  }

  void _deleteItem(String id) {
    setState(() {
      widget.shoppingList.items.removeWhere((item) => item.id == id);
    });
    LocalDatabase.deleteChecklistItem(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elemento eliminado'), duration: Duration(seconds: 1)),
    );
  }

  // ── OCR Scan (local ML Kit, extracts product names) ─────────
  Future<void> _processImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Recortar lista',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Recortar lista',
        ),
      ],
    );

    if (croppedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Escaneando lista localmente...')),
        ]),
      ),
    );

    try {
      final productNames = await TicketScanner.scanShoppingList(croppedFile.path);

      if (!mounted) return;
      Navigator.pop(context);

      if (productNames.isNotEmpty) {
        final newItems = productNames.map((name) => ChecklistItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${name.hashCode}',
          title: name,
        )).toList();

        setState(() => widget.shoppingList.items.insertAll(0, newItems));

        // Persist to SQLite
        for (final item in newItems) {
          LocalDatabase.insertChecklistItem(item, widget.shoppingList.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡${newItems.length} productos detectados!'),
          backgroundColor: const Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se detectaron productos.')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = widget.shoppingList.items;
    final doneCount = items.where((i) => i.isDone).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.shoppingList.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress bar
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progreso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$doneCount / ${items.length}', style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: items.isEmpty ? 0 : doneCount / items.length,
                      backgroundColor: Colors.blueGrey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(doneCount == items.length && items.isNotEmpty ? Colors.green : primaryColor),
                      minHeight: 10,
                    ),
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.shopping_cart_rounded, size: 64, color: primaryColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Lista vacía', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Añade productos manualmente\no escanea una lista escrita.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 8, left: 16, right: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) => _deleteItem(item.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark 
                              ? (item.isDone ? const Color(0xFF0F172A) : const Color(0xFF1E293B))
                              : (item.isDone ? Colors.grey.shade100 : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isDone ? Colors.transparent : primaryColor.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            onTap: () => _toggleItem(index),
                            leading: Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: item.isDone,
                                onChanged: (value) => _toggleItem(index),
                                activeColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(color: primaryColor.withOpacity(0.5), width: 2),
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: item.isDone ? FontWeight.normal : FontWeight.w600,
                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                                color: item.isDone ? Colors.blueGrey.shade300 : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () => _showEditItemDialog(existingItem: item),
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
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir Elemento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
