import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/shared_checklist.dart';
import 'create_shared_checklist_screen.dart';
import 'shared_checklist_detail_screen.dart';
import '../data/supabase_repository.dart';
import '../utils/app_activity_logger.dart';
import 'qr_scanner_screen.dart';

class SharedChecklistsTab extends StatefulWidget {
  const SharedChecklistsTab({super.key});

  @override
  State<SharedChecklistsTab> createState() => _SharedChecklistsTabState();
}

class _SharedChecklistsTabState extends State<SharedChecklistsTab> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (SupabaseRepository.isAuthenticated) {
      final lists = await SupabaseRepository.fetchUserSharedChecklists();
      setState(() {
        AppData.sharedChecklists.clear();
        AppData.sharedChecklists.addAll(lists);
      });
    }
  }

  void _showJoinOrAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.add, color: Colors.blue)),
                title: const Text('Crear lista compartida', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Inicia una nueva lista de la compra con amigos o familia.'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSharedChecklistScreen())).then((_) => _loadData());
                },
              ),
              const Divider(height: 32),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.qr_code_scanner, color: Colors.green)),
                title: const Text('Unirse a una Lista', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Mediante Link o escaneando QR'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showJoinChecklistSheet();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showJoinChecklistSheet() {
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
              const Text('Unirse a una Lista', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                  );
                  if (result != null && result is String) {
                    linkController.text = result;
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text('O introduce el enlace:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://billince.com/join_checklist...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final link = linkController.text.trim();
                  if (link.isEmpty) return;
                  
                  String listId = link;
                  final match = RegExp(r'list_id=([a-zA-Z0-9-]+)').firstMatch(link);
                  if (match != null && match.groupCount > 0) {
                    listId = match.group(1)!;
                  }
                  
                  Navigator.pop(context);
                  
                  try {
                    await SupabaseRepository.joinSharedChecklist(listId);
                    
                    final joinedList = AppData.sharedChecklists.firstWhere((l) => l.id == listId, orElse: () => AppData.sharedChecklists.first);
                    AppActivityLogger.logJoinedChecklist(joinedList.name);
                    
                    if (context.mounted) {
                      _showIdentityDialog(joinedList);
                    }
                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Unirse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  void _showIdentityDialog(SharedChecklist list) {
    if (list.members.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Quién eres?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona cuál de estos integrantes eres tú en esta lista:'),
            const SizedBox(height: 16),
            ...list.members.map((m) => ListTile(
              title: Text(m),
              leading: const Icon(Icons.person),
              onTap: () {
                setState(() {
                  list.myMemberName = m;
                });
                SupabaseRepository.linkUserToChecklistMember(list.id, m);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!SupabaseRepository.isAuthenticated) {
      return const Center(child: Text('Debes iniciar sesión para usar listas compartidas.'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: AppData.sharedChecklists.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('Sin listas compartidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
                itemCount: AppData.sharedChecklists.length,
                itemBuilder: (context, index) {
                  final list = AppData.sharedChecklists[index];
                  return Dismissible(
                    key: Key(list.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Borrar lista?'),
                          content: const Text('¿Estás seguro que deseas eliminar esta lista compartida?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      setState(() {
                        AppData.sharedChecklists.remove(list);
                      });
                      SupabaseRepository.removeUserFromChecklist(list.id);
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Icon(Icons.list_alt, color: primaryColor),
                        ),
                        title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${list.members.length} participantes'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SharedChecklistDetailScreen(checklist: list)))
                              .then((_) => _loadData());
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showJoinOrAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Lista Compartida'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
