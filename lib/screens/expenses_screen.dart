import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../data/app_data.dart';
import '../data/supabase_repository.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedFilterModule = 'Todos';
  DateTimeRange? _filterDateRange;

  List<Expense> get _filteredExpenses {
    return AppData.expenses.where((expense) {
      final matchModule = _selectedFilterModule == 'Todos' || expense.module == _selectedFilterModule;
      final matchDate = _filterDateRange == null || 
          (expense.date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) && 
           expense.date.isBefore(_filterDateRange!.end.add(const Duration(days: 1))));
      return matchModule && matchDate;
    }).toList();
  }

  double get _totalBalance {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _scanTicket() {
    if (!SupabaseRepository.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escanear Factura/Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Hacer una Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _processTicketReal(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.teal),
                title: const Text('Subir desde Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _processTicketReal(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Subir Archivo PDF'),
                subtitle: const Text('Max 5MB'),
                onTap: () {
                  Navigator.pop(context);
                  _processTicketSimulation('Factura_Digital.pdf');
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.lock_outline, color: Color(0xFFF59E0B), size: 48),
        title: const Text('Inicio de sesión necesario'),
        content: const Text(
          'Para usar las funciones de IA necesitas iniciar sesión con tu cuenta. '
          'Tus datos se guardarán de forma segura en la nube y no se perderán.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTicketReal(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Analizando ticket con IA...")),
          ],
        ),
      ),
    );

    try {
      final imageBytes = await pickedFile.readAsBytes();

      final prompt = 'Analiza este ticket de compra. Extrae el nombre del comercio (storeName), el importe total a pagar (totalAmount), y los productos comprados (items). Devuelve ÚNICAMENTE un objeto JSON con las claves "storeName" (string), "totalAmount" (número decimal, no string) y "items" (array de strings con nombres de productos). No añadas markdown ni texto adicional.';

      final responseText = await SupabaseRepository.callGemini(
        prompt: prompt,
        imageBytes: imageBytes,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (responseText == null || responseText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: No se pudo conectar con el servicio de IA.'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      final cleanText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> data = jsonDecode(cleanText);
      final String storeName = data['storeName'] ?? 'Comercio Desconocido';
      final num? totalAmountNum = data['totalAmount'] as num?;
      final double totalFound = totalAmountNum?.toDouble() ?? 0.0;
      final List<dynamic> itemsDynamic = data['items'] ?? [];
      final List<String> items = itemsDynamic.map((e) => e.toString()).toList();

      if (totalFound > 0) {
        final newExpense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: storeName,
          amount: totalFound,
          date: DateTime.now(),
          module: 'General',
          attachedFileName: pickedFile.path.split('/').last,
        );
        
        await SupabaseRepository.addExpense(newExpense);
        
        if (items.isNotEmpty) {
           await SupabaseRepository.createShoppingListWithItems('Ticket $storeName', items);
        }

        setState(() {}); // Refresh UI
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Gasto de ${AppData.currency}${totalFound.toStringAsFixed(2)} y productos añadidos!'),
          backgroundColor: const Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No detectamos el total. Rellena los datos manualmente.')));
        _showExpenseForm(initialTitle: storeName, attachedFileName: pickedFile.path.split('/').last);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar la imagen: $e')));
    }
  }

  void _processTicketSimulation(String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text("Analizando ticket con IA...")),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    final randomAmount = (Random().nextDouble() * 50) + 5;
    
    final storeMap = {
      "Supermercado": "Compras",
      "Restaurante": "Ocio",
      "Gasolinera": "Transporte",
      "Cafetería": "Ocio",
      "Papelería": "Compras",
      "Billetes de Tren": "Transporte",
      "Ferretería": "Hogar"
    };

    final stores = storeMap.keys.toList();
    final randomStore = stores[Random().nextInt(stores.length)];
    
    String assignedModule = storeMap[randomStore]!;

    if (!AppData.modules.contains(assignedModule)) {
      assignedModule = 'General';
      if (!AppData.modules.contains('General')) {
        AppData.modules.add('General');
      }
    }

    setState(() {
      AppData.expenses.insert(
        0,
        Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Gasto en $randomStore",
          amount: randomAmount,
          date: DateTime.now(),
          module: assignedModule,
          attachedFileName: fileName,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detectado: $randomStore. Archivo adjuntado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteExpense(String id) {
    setState(() {
      AppData.expenses.removeWhere((expense) => expense.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gasto eliminado.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final initialDateRange = _filterDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _filterDateRange = newDateRange;
      });
    }
  }

  void _showManageModulesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final newModuleController = TextEditingController();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Gestionar Categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Añade o elimina módulos para organizar tus gastos.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newModuleController,
                          decoration: const InputDecoration(
                            hintText: 'Nuevo módulo (ej. Regalos)', 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir'),
                        onPressed: () {
                          final newMod = newModuleController.text.trim();
                          if (newMod.isNotEmpty && !AppData.modules.contains(newMod)) {
                            setState(() {
                              AppData.modules.add(newMod);
                            });
                            setSheetState((){});
                            newModuleController.clear();
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
                      itemCount: AppData.modules.length,
                      itemBuilder: (context, index) {
                        final mod = AppData.modules[index];
                        final isGeneral = mod == 'General';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(mod, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: isGeneral 
                            ? const Text('Por defecto', style: TextStyle(color: Colors.grey, fontSize: 12))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    AppData.modules.remove(mod);
                                    if (_selectedFilterModule == mod) _selectedFilterModule = 'Todos';
                                    if (!AppData.modules.contains('General')) AppData.modules.insert(0, 'General');
                                    for (var exp in AppData.expenses) {
                                      if (exp.module == mod) exp.module = 'General';
                                    }
                                  });
                                  setSheetState((){});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Módulo "$mod" eliminado. Gastos movidos a "General".')),
                                  );
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

  void _showExpenseForm({
    Expense? existingExpense,
    String? initialTitle,
    double? initialAmount,
    String? initialModule,
    String? attachedFileName,
  }) {
    final titleController = TextEditingController(text: existingExpense?.title ?? initialTitle ?? '');
    final amountController = TextEditingController(
      text: existingExpense != null ? existingExpense.amount.toStringAsFixed(2) : (initialAmount != null ? initialAmount.toStringAsFixed(2) : ''),
    );
    
    String selectedModule = existingExpense?.module ?? initialModule ?? (AppData.modules.isNotEmpty ? AppData.modules.first : 'General');
    String? attachedFile = existingExpense?.attachedFileName ?? attachedFileName;

    if (!AppData.modules.contains(selectedModule)) {
       selectedModule = 'General';
       if (!AppData.modules.contains('General')) AppData.modules.insert(0, 'General');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingExpense == null ? 'Añadir Gasto Manual' : 'Editar Gasto',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Concepto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Importe (${AppData.currency})',
                        border: const OutlineInputBorder(),
                        prefixText: '${AppData.currency} ',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedModule,
                      decoration: const InputDecoration(
                        labelText: 'Módulo / Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppData.modules.map((String mod) {
                        return DropdownMenuItem<String>(
                          value: mod,
                          child: Text(mod),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            selectedModule = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(attachedFile == null ? Icons.attach_file : Icons.check_circle, color: attachedFile == null ? Theme.of(context).colorScheme.primary : Colors.green),
                      label: Text(attachedFile == null ? 'Adjuntar Factura/Ticket' : 'Archivo adjuntado: $attachedFile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: attachedFile == null ? Theme.of(context).colorScheme.primary : Colors.green),
                      ),
                      onPressed: () {
                        // Simulate attachment directly for simplicity in the manual form
                        setModalState(() {
                          attachedFile = 'Factura_Manual_${DateTime.now().millisecondsSinceEpoch}.pdf';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archivo adjuntado.')));
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amountText = amountController.text.replaceAll(',', '.');
                        final amount = double.tryParse(amountText) ?? 0.0;

                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor, introduce un concepto e importe válidos.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (existingExpense == null) {
                          final newExp = Expense(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            amount: amount,
                            date: DateTime.now(),
                            module: selectedModule,
                            attachedFileName: attachedFile,
                          );
                          SupabaseRepository.addExpense(newExp).then((_) {
                            if (mounted) setState(() {});
                          });
                        } else {
                          existingExpense.title = title;
                          existingExpense.amount = amount;
                          existingExpense.module = selectedModule;
                          existingExpense.attachedFileName = attachedFile;
                          // TODO: Add Supabase update support
                          setState(() {});
                        }

                        Navigator.of(context).pop();
                      },
                      child: Text(
                        existingExpense == null ? 'Guardar Gasto' : 'Actualizar Gasto',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.date_range),
          tooltip: 'Filtrar por fecha',
          onPressed: _pickDateRange,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir gasto manual',
            onPressed: () => _showExpenseForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total (según filtros)',
                  style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppData.currency}${_totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 16.0, top: 16.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtro por Categoría:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                TextButton.icon(
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Gestionar'),
                  onPressed: _showManageModulesSheet,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                ),
              ],
            ),
          ),
          
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _selectedFilterModule == 'Todos',
                  onSelected: (selected) {
                    setState(() => _selectedFilterModule = 'Todos');
                  },
                ),
                const SizedBox(width: 8),
                ...AppData.modules.map((mod) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(mod),
                    selected: _selectedFilterModule == mod,
                    onSelected: (selected) {
                      setState(() => _selectedFilterModule = mod);
                    },
                  ),
                )),
              ],
            ),
          ),

          if (_filterDateRange != null)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fechas: ${_filterDateRange!.start.day}/${_filterDateRange!.start.month} - ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _filterDateRange = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gastos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: _filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay gastos para estos filtros.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = _filteredExpenses[index];
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteExpense(expense.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () => _showExpenseForm(existingExpense: expense),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.receipt, color: Theme.of(context).colorScheme.onSecondaryContainer),
                            ),
                            title: Text(
                              expense.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${expense.date.day.toString().padLeft(2, '0')}/${expense.date.month.toString().padLeft(2, '0')}/${expense.date.year} ${expense.date.hour.toString().padLeft(2, '0')}:${expense.date.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '-${AppData.currency}${expense.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    if (expense.attachedFileName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Icon(Icons.attach_file, size: 16, color: Theme.of(context).colorScheme.primary),
                                      )
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () => _deleteExpense(expense.id),
                                  padding: const EdgeInsets.only(left: 8),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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
        onPressed: _scanTicket,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Escanear', style: TextStyle(fontWeight: FontWeight.bold)),
        tooltip: 'Escanear Ticket',
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
