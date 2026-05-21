import 'package:flutter/material.dart';
import '../models/shared_group.dart';
import '../data/app_data.dart';
import '../data/supabase_repository.dart';
import 'shared_group_detail_screen.dart';

class SharedExpensesScreen extends StatefulWidget {
  const SharedExpensesScreen({super.key});

  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {

  IconData _getIconForGroup(String title) {
    final t = title.toLowerCase();
    if (t.contains('viaj') || t.contains('vuel')) return Icons.flight_takeoff;
    if (t.contains('restaurante') || t.contains('cena') || t.contains('comid') || t.contains('bar')) return Icons.restaurant;
    if (t.contains('piso') || t.contains('casa') || t.contains('hogar') || t.contains('alquiler')) return Icons.home;
    if (t.contains('regalo') || t.contains('cumple') || t.contains('sorpresa')) return Icons.card_giftcard;
    if (t.contains('fiesta') || t.contains('copas')) return Icons.local_bar;
    if (t.contains('compra') || t.contains('super')) return Icons.shopping_cart;
    if (t.contains('coche') || t.contains('gasolina') || t.contains('transporte')) return Icons.directions_car;
    return Icons.event; // Default
  }

  void _showAddGroupSheet() {
    final titleController = TextEditingController();
    String selectedCurrency = '€'; // Default for new groups

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nuevo Grupo/Evento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Ejemplo: Viaje a Asturias, Piso Compartido...', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Nombre del Evento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event)),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(labelText: 'Moneda', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                      DropdownMenuItem(value: '\$', child: Text('Dólar (\$)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedCurrency = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          AppData.sharedGroups.insert(0, SharedExpenseGroup(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            members: ['Tú'], // You start as the only member by default
                            expenses: [],
                            files: [],
                            currency: selectedCurrency,
                          ));
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Crear Grupo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showGroupOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, size: 28, color: Colors.blue),
                  title: const Text('Crear Nuevo Evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Para organizar un viaje, piso, etc.'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddGroupSheet();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.green),
                  title: const Text('Unirse a un Evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text('Mediante Link o escaneando QR'),
                  onTap: () {
                    Navigator.pop(context);
                    _showJoinGroupSheet();
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showJoinGroupSheet() {
    final linkController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Unirse a un Evento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Escanear QR'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usa tu cámara nativa para leer el QR y pega el enlace aquí.')));
                },
              ),
              const SizedBox(height: 24),
              const Text('O introduce el enlace:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://billince.app/join/ID...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final link = linkController.text.trim();
                  if (link.isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context); // close sheet
                    
                    if (!SupabaseRepository.isAuthenticated) {
                      messenger.showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para unirte.')));
                      return;
                    }
                    
                    String groupId = link;
                    if (link.contains('/join/')) {
                      groupId = link.split('/join/').last;
                    } else if (link.contains('/')) {
                      groupId = link.split('/').last;
                    }
                    
                    try {
                      await SupabaseRepository.joinSharedGroup(groupId);
                      messenger.showSnackBar(const SnackBar(content: Text('Unido con éxito. (Datos en la nube)')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Unirse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  void _deleteGroup(SharedExpenseGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: Text('¿Seguro que quieres eliminar "${group.title}" y todos sus gastos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() {
                AppData.sharedGroups.remove(group);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Compartidos'),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
      ),
      body: AppData.sharedGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No hay eventos creados.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: AppData.sharedGroups.length,
              itemBuilder: (context, index) {
                final group = AppData.sharedGroups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SharedGroupDetailScreen(group: group)),
                      ).then((_) {
                        // Refresh state when coming back
                        setState(() {});
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getIconForGroup(group.title), color: const Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${group.members.length} integrantes | ${group.expenses.length} gastos', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteGroup(group),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _showGroupOptionsSheet,
        icon: const Icon(Icons.event_available),
        label: const Text('Opciones de Evento'),
      ),
    );
  }
}
