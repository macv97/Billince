import 'package:flutter/material.dart';
import '../models/checklist_item.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ShoppingListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  void _addItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir a la lista'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej. Leche, Pan, Huevos...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
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
      const SnackBar(
        content: Text('Elemento eliminado'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _scanChecklist() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escanear Lista con IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F172A)),
                title: const Text('Hacer Foto a una lista'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFFF59E0B)),
                title: const Text('Subir Foto de Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _processImage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Analizando imagen y extrayendo elementos...")),
          ],
        ),
      )
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // close dialog
      setState(() {
        widget.shoppingList.items.insert(0, ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString() + "1", title: "Plátanos de Canarias"));
        widget.shoppingList.items.insert(0, ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString() + "2", title: "Pan integral"));
        widget.shoppingList.items.insert(0, ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString() + "3", title: "Huevos camperos (Docena)"));
        widget.shoppingList.items.insert(0, ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString() + "4", title: "Leche desnatada"));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡4 elementos extraídos con éxito!')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.shoppingList.items;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shoppingList.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Escanear Lista',
            onPressed: _scanChecklist,
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'La lista está vacía.\n¡Añade cosas o escanea una foto!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteItem(item.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    color: item.isDone ? Colors.grey.shade100 : Colors.white,
                    child: ListTile(
                      onTap: () => _toggleItem(index),
                      leading: Checkbox(
                        value: item.isDone,
                        onChanged: (value) => _toggleItem(index),
                        activeColor: Theme.of(context).colorScheme.primary,
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
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Añadir elemento'),
      ),
    );
  }
}
