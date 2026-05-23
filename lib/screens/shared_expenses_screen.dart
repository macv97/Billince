import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_group.dart';
import '../models/expense.dart';
import '../data/app_data.dart';
import '../data/local_database.dart';
import '../data/supabase_repository.dart';
import 'shared_group_detail_screen.dart';
import '../utils/app_activity_logger.dart';
import 'qr_scanner_screen.dart';

class SharedExpensesScreen extends StatefulWidget {
  const SharedExpensesScreen({super.key});

  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {

  Future<void> _refreshGroups() async {
    if (SupabaseRepository.isAuthenticated) {
      try {
        final cloudGroups = await SupabaseRepository.fetchUserGroups();
        setState(() {
          AppData.sharedGroups.clear();
          AppData.sharedGroups.addAll(cloudGroups);
        });
      } catch (_) {}
    }
    setState(() {});
  }

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

  // _showAddGroupSheet removed - using CreateSharedGroupScreen now

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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSharedGroupScreen())).then((res) {
                      if (res == true) setState((){});
                    });
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
                  hintText: 'https://billince.app/join/ID...',
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
                      setState(() {});
                      
                      final joinedGroup = AppData.sharedGroups.firstWhere((g) => g.id == groupId);
                      AppActivityLogger.logJoinedEvent(joinedGroup.title);
                      
                      messenger.showSnackBar(const SnackBar(
                        content: Text('¡Unido con éxito!'),
                        backgroundColor: Color(0xFF10B981),
                      ));
                      
                      // Ask who they are
                      if (context.mounted) {
                        _showIdentityDialog(joinedGroup);
                      }
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


  void _showIdentityDialog(SharedExpenseGroup group) {
    if (group.members.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Quién eres?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona cuál de estos integrantes eres tú en este evento:'),
            const SizedBox(height: 16),
            ...group.members.map((m) => ListTile(
              title: Text(m),
              leading: const Icon(Icons.person),
              onTap: () {
                setState(() {
                  group.myMemberName = m;
                });
                SupabaseRepository.linkUserToMember(group.id, m);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _transferToBilling(SharedExpenseGroup group) {
    final myName = group.myMemberName ?? 'Tú';
    if (!group.members.contains(myName)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No estás asignado a ningún integrante en este grupo.')));
      return;
    }

    // Calcular la parte que le corresponde al usuario (su gasto real)
    double myShare = 0;
    for (var exp in group.expenses) {
      if (exp.participants.contains(myName)) {
        myShare += exp.amount / exp.participants.length;
      }
    }

    if (myShare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes ningún gasto pagado en este evento para traspasar.')));
      return;
    }

    String selectedModule = AppData.modules.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Traspasar a Gastos'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Te corresponde un total de ${myShare.toStringAsFixed(2)}${group.currency} en gastos.'),
                  const SizedBox(height: 16),
                  const Text('Selecciona el módulo para el gasto:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedModule,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: AppData.modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedModule = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final newExp = Expense(
                      id: const Uuid().v4(),
                      title: 'Evento: ${group.title}',
                      amount: myShare,
                      date: DateTime.now(),
                      module: selectedModule,
                    );
                    
                    await LocalDatabase.insertExpense(newExp);
                    AppData.expenses.insert(0, newExp);
                    AppData.expenses.sort((a, b) => b.date.compareTo(a.date));
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Se ha traspasado ${myShare.toStringAsFixed(2)}${group.currency} a Gastos.'),
                        backgroundColor: const Color(0xFF10B981),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Traspasar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEventSettingsSheet(SharedExpenseGroup group) {
    final titleController = TextEditingController(text: group.title);
    final memberController = TextEditingController();
    String selectedCurrency = group.currency;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ajustes del Evento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _transferToBilling(group);
                          },
                          icon: const Icon(Icons.account_balance_wallet, size: 18),
                          label: const Text('Traspasar Gastos'),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Título del evento', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Moneda del evento:', style: TextStyle(fontSize: 16)),
                        DropdownButton<String>(
                          value: selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                            DropdownMenuItem(value: '\$', child: Text('Dólar (\$)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCurrency = val);
                            }
                          },
                        ),
                      ],
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
                          onPressed: () async {
                            if (memberController.text.trim().isNotEmpty) {
                              final newMember = memberController.text.trim();
                              setModalState(() {
                                group.members.add(newMember);
                              });
                              setState((){});
                              await SupabaseRepository.client.from('group_members').insert({
                                'group_id': group.id,
                                'guest_name': newMember,
                                'user_id': null,
                              });
                              memberController.clear();
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Integrantes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...group.members.map((m) {
                      final isMe = m == (group.myMemberName ?? 'Tú');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text(m.isNotEmpty ? m[0].toUpperCase() : '?')),
                        title: Text(m + (isMe ? ' (Tú)' : '')),
                        trailing: isMe ? null : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            setModalState(() {
                              group.members.remove(m);
                            });
                            setState((){});
                            await SupabaseRepository.client.from('group_members').delete().eq('group_id', group.id).eq('guest_name', m);
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
                          final newTitle = titleController.text.trim();
                          if (newTitle.isNotEmpty && newTitle != group.title) {
                            setState(() => group.title = newTitle);
                            await SupabaseRepository.updateSharedGroupTitle(group.id, newTitle);
                          }
                          if (selectedCurrency != group.currency) {
                            setState(() => group.currency = selectedCurrency);
                            await SupabaseRepository.updateSharedGroupCurrency(group.id, selectedCurrency);
                          }
                          if (mounted) Navigator.pop(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos Compartidos', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshGroups,
        child: AppData.sharedGroups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No hay eventos creados.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Arrastra hacia abajo para actualizar', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: AppData.sharedGroups.length,
              itemBuilder: (context, index) {
                final group = AppData.sharedGroups[index];
                return Dismissible(
                    key: Key(group.id),
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
                          title: const Text('Eliminar Evento'),
                          content: Text('¿Seguro que quieres desvincularte de "${group.title}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      setState(() {
                        AppData.sharedGroups.remove(group);
                      });
                      SupabaseRepository.leaveSharedGroup(group.id);
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SharedGroupDetailScreen(group: group)),
                          ).then((_) {
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
                                  color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getIconForGroup(group.title), color: isDark ? Colors.amber : const Color(0xFFF59E0B)),
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
                                icon: Icon(Icons.settings, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                onPressed: () => _showEventSettingsSheet(group),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _showGroupOptionsSheet,
        icon: const Icon(Icons.add),
        label: const Text('Añadir Evento', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CreateSharedGroupScreen extends StatefulWidget {
  const CreateSharedGroupScreen({super.key});

  @override
  State<CreateSharedGroupScreen> createState() => _CreateSharedGroupScreenState();
}

class _CreateSharedGroupScreenState extends State<CreateSharedGroupScreen> {
  final _titleController = TextEditingController();
  String _selectedCurrency = '€';
  
  final List<TextEditingController> _participantControllers = [TextEditingController()];

  void _addParticipant() {
    setState(() {
      _participantControllers.add(TextEditingController());
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      final c = _participantControllers.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, indica un título.')));
      return;
    }

    List<String> members = [];
    String? myName;
    for (int i = 0; i < _participantControllers.length; i++) {
      final name = _participantControllers[i].text.trim();
      if (name.isNotEmpty) {
        if (!members.contains(name)) {
          members.add(name);
          if (i == 0) myName = name; // El primero es el creador
        }
      }
    }

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, indica al menos un participante.')));
      return;
    }

    myName ??= members.first;

    final newGroup = SharedExpenseGroup(
      id: const Uuid().v4(),
      title: title,
      members: members,
      expenses: [],
      files: [],
      currency: _selectedCurrency,
      myMemberName: myName,
    );

    AppData.sharedGroups.insert(0, newGroup);
    Navigator.pop(context, true); 

    try {
      await SupabaseRepository.createSharedGroup(newGroup);
      AppActivityLogger.logCreatedEvent(title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo creado localmente. Error en la nube: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _participantControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo evento', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Título', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: const Icon(Icons.event, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Por ejemplo, Viaje a la Ciudad',
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Opciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Moneda', style: TextStyle(fontSize: 16)),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            items: const [
                              DropdownMenuItem(value: '€', child: Text('euro (€)')),
                              DropdownMenuItem(value: '\$', child: Text('dólar (\$)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCurrency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Participantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _participantControllers.length; i++) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _participantControllers[i],
                                  decoration: InputDecoration(
                                    hintText: i == 0 ? 'Tu Nombre' : 'Añadir Participante',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              if (i > 0)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () => _removeParticipant(i),
                                )
                            ],
                          ),
                          if (i < _participantControllers.length - 1)
                            const Divider(height: 1, indent: 16),
                        ],
                        const Divider(height: 1),
                        InkWell(
                          onTap: _addParticipant,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Text('Añadir Participante', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _createEvent,
                  child: const Text('Crear evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
