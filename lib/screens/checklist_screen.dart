import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/checklist_item.dart';
import 'shopping_list_detail_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  void _createNewList() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Lista de la Compra'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej. Compra Mercadona, Cumpleaños...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  AppData.shoppingLists.insert(0, ShoppingList(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    dateCreated: DateTime.now(),
                    items: [],
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _deleteList(ShoppingList list) {
    setState(() {
      AppData.shoppingLists.remove(list);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Listas de Compra'),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
      ),
      body: AppData.shoppingLists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes listas guardadas.\n¡Crea una para empezar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: AppData.shoppingLists.length,
              itemBuilder: (context, index) {
                final list = AppData.shoppingLists[index];
                final completedItems = list.items.where((i) => i.isDone).length;
                final totalItems = list.items.length;
                
                return Dismissible(
                  key: Key(list.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteList(list),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ShoppingListDetailScreen(shoppingList: list)),
                        ).then((_) => setState(() {})); // Refresh when coming back
                      },
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFEF3C7),
                        child: const Icon(Icons.shopping_cart, color: Color(0xFFF59E0B)),
                      ),
                      title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        totalItems == 0 ? 'Vacía' : '$completedItems de $totalItems completados',
                        style: TextStyle(color: totalItems > 0 && completedItems == totalItems ? const Color(0xFF10B981) : Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _createNewList,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Lista'),
      ),
    );
  }
}

