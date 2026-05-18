import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/local_database.dart';
import '../models/checklist_item.dart';
import 'shopping_list_detail_screen.dart';
import 'shopping_insights_screen.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nueva Lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej. Compra semanal, Barbacoa...',
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
                final newList = ShoppingList(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  dateCreated: DateTime.now(),
                  items: [],
                );
                setState(() {
                  AppData.shoppingLists.insert(0, newList);
                });
                LocalDatabase.insertShoppingList(newList);
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
    setState(() => AppData.shoppingLists.remove(list));
    LocalDatabase.deleteShoppingList(list.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista eliminada')));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mis Listas', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              icon: Icon(Icons.insights_rounded, color: primaryColor, size: 20),
              label: Text('Insights', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingInsightsScreen()));
              },
            ),
          ),
        ],
      ),
      body: AppData.shoppingLists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.shopping_basket_rounded, size: 64, color: primaryColor.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sin listas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Crea tu primera lista de compras.', style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
              itemCount: AppData.shoppingLists.length,
              itemBuilder: (context, index) {
                final list = AppData.shoppingLists[index];
                final completedItems = list.items.where((i) => i.isDone).length;
                final totalItems = list.items.length;
                final progress = totalItems == 0 ? 0.0 : completedItems / totalItems;

                return Dismissible(
                  key: Key(list.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
                  ),
                  onDismissed: (direction) => _deleteList(list),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, spreadRadius: -5, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ShoppingListDetailScreen(shoppingList: list)),
                          ).then((_) => setState(() {}));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.shopping_cart_rounded, color: primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(list.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.blueGrey.withOpacity(0.1),
                                              valueColor: AlwaysStoppedAnimation(progress == 1.0 ? Colors.green : primaryColor),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          totalItems == 0 ? 'Vacía' : '$completedItems/$totalItems',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.shade300),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _createNewList,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Lista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
