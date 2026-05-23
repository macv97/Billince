import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:io';
import '../models/shared_group.dart';
import '../models/shared_expense.dart';
import '../models/shared_file.dart';
import '../data/app_data.dart';
import '../data/supabase_repository.dart';
import 'welcome_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SharedGroupDetailScreen extends StatefulWidget {
  final SharedExpenseGroup group;
  
  const SharedGroupDetailScreen({super.key, required this.group});

  @override
  State<SharedGroupDetailScreen> createState() => _SharedGroupDetailScreenState();
}

class _SharedGroupDetailScreenState extends State<SharedGroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Gastos, Saldos, Archivos
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (SupabaseRepository.isAuthenticated) {
      final expenses = await SupabaseRepository.fetchSharedExpenses(widget.group.id);
      setState(() {
        widget.group.expenses = expenses;
        // Collect all distinct participants as members dynamically
        final memberSet = <String>{...widget.group.members};
        for (var e in expenses) {
          memberSet.add(e.payer);
          memberSet.addAll(e.participants);
        }
        widget.group.members = memberSet.toList();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, double> get _balances {
    final b = <String, double>{};
    for (var m in widget.group.members) {
      b[m] = 0.0;
    }
    
    for (var exp in widget.group.expenses) {
      if (!b.containsKey(exp.payer)) b[exp.payer] = 0.0;
      b[exp.payer] = b[exp.payer]! + exp.amount;
      
      if (exp.participants.isNotEmpty) {
        final split = exp.amount / exp.participants.length;
        for (var p in exp.participants) {
          if (!b.containsKey(p)) b[p] = 0.0;
          b[p] = b[p]! - split;
        }
      }
    }
    return b;
  }

  List<Map<String, dynamic>> get _settlements {
    final b = Map<String, double>.from(_balances);
    final settlements = <Map<String, dynamic>>[];

    b.removeWhere((k, v) => v.abs() < 0.01);

    while (b.isNotEmpty) {
      var maxDebtor = '';
      var minDebtor = '';
      var maxDebt = 0.0;
      var maxCredit = 0.0;

      b.forEach((person, balance) {
        if (balance < -0.01 && balance.abs() > maxDebt) {
          maxDebt = balance.abs();
          maxDebtor = person;
        }
        if (balance > 0.01 && balance > maxCredit) {
          maxCredit = balance;
          minDebtor = person;
        }
      });

      if (maxDebtor.isEmpty || minDebtor.isEmpty) break;

      final amount = min(maxDebt, maxCredit);
      settlements.add({
        'from': maxDebtor,
        'to': minDebtor,
        'amount': amount,
      });

      b[maxDebtor] = b[maxDebtor]! + amount;
      b[minDebtor] = b[minDebtor]! - amount;

      if (b[maxDebtor]!.abs() < 0.01) b.remove(maxDebtor);
      if (b[minDebtor]!.abs() < 0.01) b.remove(minDebtor);
    }
    
    return settlements;
  }

  void _showInfoPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('¿Cómo funciona?'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('El algoritmo calcula de forma inteligente cómo cuadrar el dinero para que todo el mundo pague lo mismo por lo que ha consumido, minimizando las transferencias.'),
                SizedBox(height: 12),
                Text('1. Gasto a Gasto:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('El importe se divide entre las personas seleccionadas. El que lo pagó recibe el importe a su favor, y a los que participaron se les resta su parte correspondiente.'),
                SizedBox(height: 12),
                Text('2. Balance Final:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Si estás en Verde (+), has pagado más de la cuenta y los demás te deben dinero. Si estás en Rojo (-), debes dinero al grupo.'),
                SizedBox(height: 12),
                Text('3. Liquidación:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('El sistema cruza al que más debe con el que más tiene que recibir para crear la ruta más rápida y con menos transferencias bancarias posibles para dejar a todos a 0.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  void _showManageMembersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final controller = TextEditingController();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Gestionar Integrantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Añade o elimina personas de este grupo.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Nombre de la persona', 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Añadir'),
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && !widget.group.members.contains(name)) {
                            setState(() {
                              widget.group.members.add(name);
                            });
                            setSheetState((){});
                            controller.clear();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.group.members.length,
                      itemBuilder: (context, index) {
                        final member = widget.group.members[index];
                        final isMe = member == widget.group.myMemberName || (widget.group.myMemberName == null && member == 'Tú');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primaryContainer,
                            child: Text(member.substring(0, 1).toUpperCase(), style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                          ),
                          title: Row(
                            children: [
                              Text(member, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500)),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Tú', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          trailing: isMe ? const SizedBox.shrink() : IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              if (widget.group.members.length <= 1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Debe haber al menos una persona en el grupo.')),
                                );
                                return;
                              }
                              setState(() {
                                widget.group.members.remove(member);
                              });
                              setSheetState((){});
                            },
                          ),
                        );
                      },
                    ),
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

  void _showEditNameSheet() {
    final controller = TextEditingController(text: widget.group.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar Nombre del Grupo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      widget.group.title = text;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  void _showShareModal() {
    final link = 'https://billince.app/join/${widget.group.id}';
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
              const Text('Invitar al Grupo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                        Share.share('¡Únete a mi grupo "${widget.group.title}" en Billince para compartir gastos!\n$link');
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

  void _showAttachmentOptions(Function(SharedFile) onFileAdded) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adjuntar Archivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F172A)),
                title: const Text('Hacer una Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onFileAdded);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Subir desde Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onFileAdded);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Subir Archivo PDF'),
                subtitle: const Text('Facturas o recibos (Max 5MB)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(onFileAdded);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _pickImage(ImageSource source, Function(SharedFile) onFileAdded) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;
      
      _processPickedFile(pickedFile.path, pickedFile.name, onFileAdded);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al obtener imagen: $e')));
    }
  }

  Future<void> _pickFile(Function(SharedFile) onFileAdded) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _processPickedFile(result.files.single.path!, result.files.single.name, onFileAdded);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar archivo: $e')));
    }
  }
  
  Future<void> _processPickedFile(String path, String name, Function(SharedFile) onFileAdded) async {
    final file = File(path);
    if (!file.existsSync()) return;
    
    final sizeInBytes = file.lengthSync();
    final sizeMb = sizeInBytes / (1024 * 1024);
    
    if (sizeMb > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: El archivo pesa ${sizeMb.toStringAsFixed(1)}MB. El límite es 5MB.'),
          backgroundColor: Colors.redAccent,
        )
      );
      return;
    }
    
    String type = 'pdf';
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) type = 'jpg';
    if (lowerName.endsWith('.png')) type = 'png';

    final sharedFile = SharedFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      sizeMb: sizeMb,
      type: type,
      dateAdded: DateTime.now(),
      uploadedBy: widget.group.myMemberName ?? 'Tú',
      localPath: path,
    );
    
    setState(() {
      widget.group.files.insert(0, sharedFile);
    });
    
    onFileAdded(sharedFile);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archivo adjuntado con éxito.')),
    );
  }

  void _showExpenseForm({SharedExpense? existingExpense}) {
    if (widget.group.members.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade miembros primero.')));
       return;
    }

    final titleController = TextEditingController(text: existingExpense?.title ?? '');
    final amountController = TextEditingController(
      text: existingExpense != null ? existingExpense.amount.toStringAsFixed(2) : ''
    );
    
    String selectedPayer = existingExpense?.payer ?? widget.group.members.first;
    if (!widget.group.members.contains(selectedPayer)) {
      selectedPayer = widget.group.members.first;
    }

    List<String> selectedParticipants = existingExpense != null 
      ? List.from(existingExpense.participants) 
      : List.from(widget.group.members);

    SharedFile? attachedFile;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingExpense == null ? 'Nuevo Gasto Compartido' : 'Editar Gasto', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Concepto', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                        prefixIcon: const Icon(Icons.description)
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Importe Total (${widget.group.currency})', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                        prefixIcon: const Icon(Icons.paid)
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: widget.group.members.contains(selectedPayer) ? selectedPayer : widget.group.members.first,
                      decoration: InputDecoration(
                        labelText: '¿Quién pagó?', 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                        prefixIcon: const Icon(Icons.payment)
                      ),
                      items: widget.group.members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedPayer = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('¿Para quién es el gasto? (Se dividirá en partes iguales)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Column(
                        children: widget.group.members.map((m) {
                          return CheckboxListTile(
                            title: Text(m),
                            value: selectedParticipants.contains(m),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selectedParticipants.add(m);
                                } else {
                                  selectedParticipants.remove(m);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(attachedFile == null ? Icons.attach_file : Icons.check_circle, color: attachedFile == null ? const Color(0xFF0F172A) : Colors.green),
                      label: Text(attachedFile == null ? 'Adjuntar Factura/Ticket' : 'Archivo adjuntado: ${attachedFile!.name}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: attachedFile == null ? const Color(0xFF0F172A) : Colors.green),
                      ),
                      onPressed: () {
                        _showAttachmentOptions((file) {
                          setSheetState(() {
                            attachedFile = file;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amountText = amountController.text.replaceAll(',', '.');
                        final amount = double.tryParse(amountText) ?? 0;
                        
                        if (title.isEmpty || amount <= 0 || selectedParticipants.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los datos y asegúrate de seleccionar al menos un participante.')));
                          return;
                        }

                        setState(() {
                          if (existingExpense == null) {
                            final newExp = SharedExpense(
                              id: const Uuid().v4(),
                              title: title,
                              amount: amount,
                              payer: selectedPayer,
                              participants: selectedParticipants,
                              date: DateTime.now(),
                            );
                            widget.group.expenses.insert(0, newExp);
                            SupabaseRepository.syncSharedExpense(newExp, widget.group.id);
                          } else {
                            existingExpense.title = title;
                            existingExpense.amount = amount;
                            existingExpense.payer = selectedPayer;
                            existingExpense.participants = selectedParticipants;
                            SupabaseRepository.syncSharedExpense(existingExpense, widget.group.id);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(existingExpense == null ? 'Guardar' : 'Actualizar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _deleteExpense(SharedExpense expense) {
    setState(() {
      widget.group.expenses.remove(expense);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto eliminado.')),
    );
  }

  void _showExpenseActionDialog(SharedExpense exp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Opciones del Gasto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Gasto'),
              onTap: () {
                Navigator.pop(context);
                _showExpenseForm(existingExpense: exp);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar Gasto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteExpense(exp);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      }
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg':
      case 'png': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'pdf': return Colors.redAccent;
      case 'jpg':
      case 'png': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances;
    final settlements = _settlements;
    final c = widget.group.currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.group.title, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'share') {
                if (!SupabaseRepository.isAuthenticated) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Inicio de sesión requerido'),
                      content: const Text('Para compartir este grupo mediante link o QR debes iniciar sesión en la nube.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
                          },
                          child: const Text('Ir a Iniciar Sesión'),
                        )
                      ],
                    )
                  );
                } else {
                  _showShareModal();
                }
              }
              if (value == 'members') _showManageMembersSheet();
              if (value == 'editName') _showEditNameSheet();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(children: [Icon(Icons.share_rounded, color: Colors.green), SizedBox(width: 10), Text('Compartir (Link/QR)')]),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Row(children: [Icon(Icons.people_alt_rounded, color: Colors.blue), SizedBox(width: 10), Text('Gestionar Integrantes')]),
              ),
              const PopupMenuItem(
                value: 'editName',
                child: Row(children: [Icon(Icons.edit_rounded, color: Colors.orange), SizedBox(width: 10), Text('Editar Nombre')]),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.blueGrey.shade300,
          indicatorColor: primaryColor,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Gastos'),
            Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Saldos'),
            Tab(icon: Icon(Icons.folder_shared_rounded), text: 'Archivos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: GASTOS
          widget.group.expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Aún no hay gastos en este grupo.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 16),
                  itemCount: widget.group.expenses.length,
                  itemBuilder: (context, index) {
                    final exp = widget.group.expenses[index];
                    return Dismissible(
                      key: Key(exp.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _deleteExpense(exp);
                      },
                      child: GestureDetector(
                        onLongPress: () => _showExpenseActionDialog(exp),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                          child: ListTile(
                            onTap: () => _showExpenseActionDialog(exp),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Pagó: ${exp.payer}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('Para: ${exp.participants.join(", ")}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$c${exp.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // PESTAÑA 2: SALDOS Y QUIÉN DEBE A QUIÉN
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Resumen de Saldos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Positivo: Le deben dinero | Negativo: Debe dinero', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              ...widget.group.members.map((m) {
                final isMe = m == widget.group.myMemberName || (widget.group.myMemberName == null && m == 'Tú');
                final bal = balances[m] ?? 0.0;
                final isPositive = bal > 0.01;
                final isNegative = bal < -0.01;
                final color = isPositive ? Colors.green : (isNegative ? Colors.red : Colors.grey);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Text(m.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                  title: Row(
                    children: [
                      Text(m, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500)),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Tú', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  trailing: Text(
                    '${bal > 0 ? '+' : ''}$c${bal.abs().toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              }),
              
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('¿Cómo liquidar?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Color(0xFFF59E0B)),
                    onPressed: _showInfoPopup,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              settlements.isEmpty
                  ? const Center(child: Text('¡Todas las cuentas están saldadas!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)))
                  : Column(
                      children: settlements.map((s) {
                        return Card(
                          color: const Color(0xFFFEF3C7),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFF59E0B))),
                          child: ListTile(
                            leading: const Icon(Icons.sync_alt, color: Color(0xFFF59E0B)),
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black87, fontSize: 15),
                                children: [
                                  TextSpan(text: s['from'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const TextSpan(text: ' debe pagar '),
                                  TextSpan(text: '$c${s['amount'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const TextSpan(text: ' a '),
                                  TextSpan(text: s['to'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),

          // PESTAÑA 3: ARCHIVOS
          widget.group.files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No hay archivos ni fotos de tickets.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Sube facturas o tickets al añadir gastos.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 16),
                  itemCount: widget.group.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.group.files[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getFileColor(file.type).withOpacity(0.2),
                          child: Icon(_getFileIcon(file.type), color: _getFileColor(file.type)),
                        ),
                        title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Añadido por ${file.uploadedBy} • ${file.sizeMb.toStringAsFixed(1)} MB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, color: Color(0xFF0F172A)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Descargando ${file.name}...')));
                          },
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: () => _showExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Añadir Gasto'),
      ),
    );
  }
}
