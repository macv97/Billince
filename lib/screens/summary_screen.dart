import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../data/app_data.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTimeRange? _filterDateRange;

  List<Expense> get _filteredExpenses {
    return AppData.expenses.where((expense) {
      if (_filterDateRange == null) return true;
      return expense.date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) && 
             expense.date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  double get _totalBalance {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get _expensesByModule {
    final map = <String, double>{};
    for (var mod in AppData.modules) {
      map[mod] = 0.0;
    }
    for (var expense in _filteredExpenses) {
      final module = expense.module;
      if (map.containsKey(module)) {
        map[module] = map[module]! + expense.amount;
      } else {
        map[module] = expense.amount;
      }
    }
    // Remove modules with 0 expenses to keep the chart clean, unless total is 0
    map.removeWhere((key, value) => value == 0.0);
    return map;
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

  @override
  Widget build(BuildContext context) {
    final expensesMap = _expensesByModule;
    final sortedEntries = expensesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final double maxCategoryAmount = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen y Gráficos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filtrar por fecha',
            onPressed: _pickDateRange,
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
                  'Gasto Total',
                  style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppData.currency}${_totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          if (_filterDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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
            padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gastos por Categoría',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay gastos registrados en este periodo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final percentage = _totalBalance > 0 ? (entry.value / _totalBalance) * 100 : 0;
                      
                      // Alternate colors for aesthetic appeal
                      final colors = [const Color(0xFF0F172A), const Color(0xFFF59E0B), const Color(0xFF10B981), Colors.blueGrey, const Color(0xFFEF4444)];
                      final barColor = colors[index % colors.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${AppData.currency}${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: entry.value / maxCategoryAmount,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
