import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense.dart';
import '../models/checklist_item.dart';
import '../data/app_data.dart';
import '../data/local_database.dart';
import '../services/ticket_scanner.dart';

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
                  _processTicketLocal(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.teal),
                title: const Text('Subir desde Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _processTicketLocal(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  /// Process ticket using 100% local ML Kit OCR + post-OCR algorithm.
  Future<void> _processTicketLocal(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Analizando ticket localmente...')),
          ],
        ),
      ),
    );

    try {
      final result = await TicketScanner.scanTicket(pickedFile.path);

      if (!mounted) return;
      Navigator.pop(context); // close loading

      // Option 2: Intelligent Price Carousel UX
      // We always open the form with the best guesses and the list of possible prices as a carousel
      _showExpenseForm(
        initialTitle: result.storeName != 'Comercio' ? result.storeName : null,
        initialAmount: result.totalAmount > 0 ? result.totalAmount : null,
        attachedFileName: pickedFile.path.split(Platform.pathSeparator).last,
        possiblePrices: result.possiblePrices,
        ticketItems: result.items,
      );
      
      if (mounted) {
        if (result.totalAmount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Revisa el gasto y guárdalo.'),
            backgroundColor: const Color(0xFF10B981),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No detectamos importes claros. Por favor, rellénalos.'),
          ));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al analizar la imagen: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _deleteExpense(String id) {
    setState(() {
      AppData.expenses.removeWhere((expense) => expense.id == id);
    });
    LocalDatabase.deleteExpense(id);
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
    List<double>? possiblePrices,
    List<TicketLineItem>? ticketItems,
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = Theme.of(context).colorScheme.primary;
            final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            existingExpense == null ? Icons.add_circle_outline_rounded : Icons.edit_rounded,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            existingExpense == null ? 'Nuevo Gasto' : 'Editar Gasto',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Concepto Field
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Concepto o Comercio',
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.storefront_rounded, color: primaryColor.withOpacity(0.7)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    
                    // Amount Field
                    TextFormField(
                      controller: amountController,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Importe Total',
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500, fontSize: 16),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixText: '${AppData.currency} ',
                        prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor),
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: primaryColor.withOpacity(0.7)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    if (possiblePrices != null && possiblePrices.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Precios detectados (Toca para usar):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: possiblePrices.map((price) {
                          return ActionChip(
                            label: Text('${AppData.currency} ${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () {
                              setModalState(() {
                                amountController.text = price.toStringAsFixed(2);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // Module Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedModule,
                      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.category_rounded, color: primaryColor.withOpacity(0.7)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
                    const SizedBox(height: 24),
                    
                    // Attachment
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          attachedFile = 'Factura_Manual_${DateTime.now().millisecondsSinceEpoch}.pdf';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archivo adjuntado con éxito.')));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: attachedFile == null ? Colors.transparent : Colors.green.withOpacity(0.1),
                          border: Border.all(
                            color: attachedFile == null ? Colors.blueGrey.shade200 : Colors.green,
                            width: 1.5,
                            style: attachedFile == null ? BorderStyle.solid : BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              attachedFile == null ? Icons.attach_file_rounded : Icons.check_circle_rounded,
                              color: attachedFile == null ? Colors.blueGrey.shade400 : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              attachedFile == null ? 'Adjuntar Recibo (Opcional)' : 'Recibo adjuntado',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: attachedFile == null ? Colors.blueGrey.shade500 : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amountText = amountController.text.replaceAll(',', '.');
                        final amount = double.tryParse(amountText) ?? 0.0;

                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Concepto o importe inválido.'),
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
                          AppData.expenses.insert(0, newExp);
                          LocalDatabase.insertExpense(newExp);
                          
                          // If it came from a ticket and had items, generate the list
                          if (ticketItems != null && ticketItems.isNotEmpty) {
                            final newList = ShoppingList(
                              id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
                              title: 'Ticket $title',
                              dateCreated: DateTime.now(),
                              items: ticketItems.map((item) => ChecklistItem(
                                id: '${DateTime.now().microsecondsSinceEpoch}_${item.name.hashCode}',
                                title: item.name,
                                isDone: true,
                                price: item.price,
                              )).toList(),
                            );
                            AppData.shoppingLists.insert(0, newList);
                            LocalDatabase.insertShoppingList(newList);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gasto y Lista de Compras guardados.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gasto guardado.')),
                            );
                          }
                          setState(() {});
                        } else {
                          existingExpense.title = title;
                          existingExpense.amount = amount;
                          existingExpense.module = selectedModule;
                          existingExpense.attachedFileName = attachedFile;
                          LocalDatabase.insertExpense(existingExpense);
                          setState(() {});
                        }

                        Navigator.of(context).pop();
                      },
                      child: Text(
                        existingExpense == null ? 'Guardar Gasto' : 'Actualizar Gasto',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppData.currency}${_totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                const Text('Filtro por Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
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
