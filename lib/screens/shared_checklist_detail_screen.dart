import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../models/shared_checklist.dart';
import '../data/supabase_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/ticket_scanner.dart';

class SharedChecklistDetailScreen extends StatefulWidget {
  final SharedChecklist checklist;

  const SharedChecklistDetailScreen({super.key, required this.checklist});

  @override
  State<SharedChecklistDetailScreen> createState() => _SharedChecklistDetailScreenState();
}

class _SharedChecklistDetailScreenState extends State<SharedChecklistDetailScreen> {
  late SharedChecklist _checklist;
  bool _isLoading = true;
  String _selectedTag = 'Todos';
  StreamSubscription? _itemsSub;
  StreamSubscription? _logsSub;

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _startStreams();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_checklist.myMemberName == null && _checklist.members.length > 1) {
        _showIdentityDialog();
      }
    });
  }

  void _showIdentityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Quién eres?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _checklist.members.map((m) => ListTile(
            title: Text(m),
            onTap: () {
              setState(() => _checklist.myMemberName = m);
              SupabaseRepository.linkUserToChecklistMember(_checklist.id, m);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _startStreams() {
    _itemsSub = SupabaseRepository.streamSharedChecklistItems(_checklist.id).listen((items) {
      if (!mounted) return;
      setState(() {
        _checklist.items.clear();
        _checklist.items.addAll(items);
        _isLoading = false;
      });
    });

    _logsSub = SupabaseRepository.streamSharedChecklistLogs(_checklist.id).listen((logs) {
      if (!mounted) return;
      setState(() {
        _checklist.logs.clear();
        _checklist.logs.addAll(logs);
      });
    });
  }

  Future<void> _loadData() async {
    // Left for pull-to-refresh fallback
    if (!_isLoading) setState(() => _isLoading = true);
    final items = await SupabaseRepository.fetchSharedChecklistItems(_checklist.id);
    final logs = await SupabaseRepository.fetchSharedChecklistLogs(_checklist.id);
    if (mounted) {
      setState(() {
        _checklist.items.clear();
        _checklist.items.addAll(items);
        _checklist.logs.clear();
        _checklist.logs.addAll(logs);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _logsSub?.cancel();
    super.dispose();
  }

  void _showShareModal() {
    final link = 'https://billince.com/join_checklist?list_id=${_checklist.id}';
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              const Text('Invitar a la Lista', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Escanea el QR o comparte el enlace:', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: primaryColor, width: 2),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado al portapapeles')));
                      },
                      icon: Icon(Icons.copy_rounded, color: primaryColor),
                      label: Text('Copiar Link', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Share.share('Únete a mi lista de compra compartida en Billince:\n$link');
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Future<void> _deleteItem(SharedChecklistItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final bool dontShowAgain = prefs.getBool('dont_show_delete_checklist_item') ?? false;

    if (!dontShowAgain) {
      bool skipNextTime = false;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('¿Borrar producto?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Estás seguro que deseas borrar este elemento?'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: skipNextTime,
                        onChanged: (val) => setState(() => skipNextTime = val ?? false),
                      ),
                      const Expanded(child: Text('No volver a mostrar')),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (skipNextTime) prefs.setBool('dont_show_delete_checklist_item', true);
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Borrar'),
                ),
              ],
            );
          }
        )
      );

      if (confirm != true) {
        _loadData(); // Reload to restore swiped item if cancelled
        return;
      }
    }

    setState(() => _checklist.items.remove(item));
    await SupabaseRepository.deleteSharedChecklistItem(_checklist.id, item.id);
    await _addLog('Eliminado', item.title);
  }

  Future<void> _toggleItem(SharedChecklistItem item, bool isDone) async {
    setState(() => item.isDone = isDone);
    await SupabaseRepository.syncSharedChecklistItem(_checklist.id, item);
    await _addLog(isDone ? 'Completado' : 'Desmarcado', item.title);
  }

  Future<void> _addLog(String action, String title) async {
    final log = SharedChecklistLog(
      id: const Uuid().v4(),
      action: action,
      userName: _checklist.myMemberName ?? 'Alguien',
      itemTitle: title,
      createdAt: DateTime.now(),
    );
    await SupabaseRepository.addSharedChecklistLog(_checklist.id, log);
    _checklist.logs.insert(0, log);
    if (mounted) setState(() {});
  }

  void _showEditItemDialog({SharedChecklistItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final tagController = TextEditingController(text: existingItem?.tags.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingItem == null ? 'Añadir producto' : 'Editar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: existingItem == null,
              decoration: const InputDecoration(labelText: 'Producto (ej. Huevos)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(labelText: 'Etiqueta (ej. Desayuno, Cenas)'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              
              final tagText = tagController.text.trim();
              final tags = tagText.isEmpty ? <String>[] : [tagText];

              if (existingItem != null) {
                final oldTitle = existingItem.title;
                setState(() {
                  existingItem.title = title;
                  existingItem.tags = tags;
                });
                Navigator.pop(context);
                await SupabaseRepository.syncSharedChecklistItem(_checklist.id, existingItem);
                await _addLog('Editado', '$oldTitle -> $title');
              } else {
                final newItem = SharedChecklistItem(
                  id: const Uuid().v4(),
                  title: title,
                  isDone: false,
                  tags: tags,
                  addedBy: _checklist.myMemberName ?? 'Tú',
                  createdAt: DateTime.now(),
                );

                setState(() => _checklist.items.add(newItem));
                Navigator.pop(context);

                await SupabaseRepository.syncSharedChecklistItem(_checklist.id, newItem);
                await _addLog('Añadido', newItem.title);
              }
            },
            child: Text(existingItem == null ? 'Añadir' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Historial de acciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _checklist.logs.length,
                  itemBuilder: (context, index) {
                    final log = _checklist.logs[index];
                    Color actionColor;
                    IconData actionIcon;
                    switch (log.action) {
                      case 'Añadido':
                        actionColor = Colors.green;
                        actionIcon = Icons.add_circle;
                        break;
                      case 'Eliminado':
                        actionColor = Colors.red;
                        actionIcon = Icons.delete;
                        break;
                      case 'Completado':
                        actionColor = Colors.blue;
                        actionIcon = Icons.check_circle;
                        break;
                      default:
                        actionColor = Colors.grey;
                        actionIcon = Icons.info;
                    }
                    return ListTile(
                      leading: Icon(actionIcon, color: actionColor),
                      title: Text('${log.userName} ha ${log.action.toLowerCase()} "${log.itemTitle}"'),
                      subtitle: Text(_formatDate(log.createdAt)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
        int addedCount = 0;
        for (final name in productNames) {
          final newItem = SharedChecklistItem(
            id: const Uuid().v4(),
            title: name,
            isDone: false,
            tags: [], 
            addedBy: _checklist.myMemberName ?? 'Tú',
            createdAt: DateTime.now(),
          );

          setState(() => _checklist.items.add(newItem));
          await SupabaseRepository.syncSharedChecklistItem(_checklist.id, newItem);
          addedCount++;
        }
        
        await _addLog('Añadido', 'Escaneo: $addedCount productos');

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡$addedCount productos detectados!'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSettingsModal() {
    final titleController = TextEditingController(text: _checklist.name);
    final memberController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ajustes de la Lista', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Título de la lista', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: memberController,
                            decoration: const InputDecoration(labelText: 'Nuevo integrante', isDense: true),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () {
                            if (memberController.text.trim().isNotEmpty) {
                              final newMember = memberController.text.trim();
                              setModalState(() {
                                _checklist.members.add(newMember);
                              });
                              setState((){});
                              SupabaseRepository.addSharedChecklistMember(_checklist.id, newMember);
                              memberController.clear();
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Integrantes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._checklist.members.map((m) {
                      final isMe = m == (_checklist.myMemberName ?? 'Tú');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text(m.isNotEmpty ? m[0].toUpperCase() : '?')),
                        title: Text(m + (isMe ? ' (Tú)' : '')),
                        trailing: isMe ? null : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              _checklist.members.remove(m);
                            });
                            setState((){});
                            SupabaseRepository.removeSharedChecklistMemberByGuestName(_checklist.id, m);
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () async {
                            final newName = titleController.text.trim();
                            if (newName.isNotEmpty && newName != _checklist.name) {
                              setState(() {
                                _checklist.name = newName;
                              });
                              Navigator.pop(context);
                              await SupabaseRepository.updateSharedChecklistTitle(_checklist.id, newName);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get unique tags
    final Set<String> allTags = {'Todos'};
    for (var item in _checklist.items) {
      if (item.tags.isNotEmpty) {
        allTags.addAll(item.tags);
      }
    }

    final filteredItems = _selectedTag == 'Todos'
        ? _checklist.items
        : _checklist.items.where((i) => i.tags.contains(_selectedTag)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_checklist.name),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsModal),
          IconButton(icon: const Icon(Icons.history), onPressed: _showAuditLogs),
          IconButton(icon: const Icon(Icons.share), onPressed: _showShareModal),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  if (allTags.length > 1)
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: allTags.map((tag) {
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedTag = tag);
                              },
                              selectedColor: colorScheme.primary.withOpacity(0.2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No hay productos en esta etiqueta.')),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return Dismissible(
                                key: Key(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteItem(item),
                                child: CheckboxListTile(
                                  title: Text(
                                    item.title,
                                    style: TextStyle(decoration: item.isDone ? TextDecoration.lineThrough : null),
                                  ),
                                  subtitle: item.tags.isNotEmpty
                                      ? Text(item.tags.join(', '), style: const TextStyle(color: Colors.blue, fontSize: 12))
                                      : null,
                                  value: item.isDone,
                                  onChanged: (val) {
                                    if (val != null) _toggleItem(item, val);
                                  },
                                  secondary: IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                                    onPressed: () => _showEditItemDialog(existingItem: item),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir Elemento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
