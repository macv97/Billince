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

  double get _totalBalance => _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  int get _totalTransactions => _filteredExpenses.length;

  double get _averageExpense => _totalTransactions > 0 ? _totalBalance / _totalTransactions : 0;

  Map<String, double> get _expensesByModule {
    final map = <String, double>{};
    for (var expense in _filteredExpenses) {
      map[expense.module] = (map[expense.module] ?? 0) + expense.amount;
    }
    return map;
  }

  Future<void> _pickDateRange() async {
    final initial = _filterDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initial,
    );
    if (result != null) setState(() => _filterDateRange = result);
  }

  @override
  Widget build(BuildContext context) {
    final expensesMap = _expensesByModule;
    final sortedEntries = expensesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final double maxVal = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1.0;
    final colors = [const Color(0xFF0F172A), const Color(0xFFF59E0B), const Color(0xFF10B981), Colors.blueGrey, const Color(0xFFEF4444), Colors.deepPurple, Colors.teal];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen y Gráficos'),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.date_range, color: Color(0xFFF59E0B), size: 20),
            label: const Text('Filtrar', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Text('Gasto Total', style: TextStyle(fontSize: 14, color: Colors.white54)),
                  const SizedBox(height: 4),
                  Text(
                    '${AppData.currency}${_totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniStat(Icons.receipt_long, '$_totalTransactions', 'Gastos'),
                      Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      _miniStat(Icons.trending_down, '${AppData.currency}${_averageExpense.toStringAsFixed(2)}', 'Media'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Date filter chip ─────────────────────────────
            if (_filterDateRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Chip(
                  backgroundColor: const Color(0xFFFEF3C7),
                  avatar: const Icon(Icons.filter_alt, size: 16, color: Color(0xFFF59E0B)),
                  label: Text(
                    '${_filterDateRange!.start.day}/${_filterDateRange!.start.month} — ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _filterDateRange = null),
                ),
              ),

            // ── Bar Chart ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: const Text('Gastos por Categoría', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            if (sortedEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('No hay gastos registrados.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              )
            else
              ...sortedEntries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final pct = _totalBalance > 0 ? (entry.value / _totalBalance * 100) : 0;
                final barColor = colors[i % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('${AppData.currency}${entry.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(children: [
                          Container(height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: entry.value / maxVal,
                            child: Container(height: 10, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6))),
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              }),

            // ── Recent Expenses ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: const Text('Últimos Gastos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            if (_filteredExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Sin gastos aún.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...(_filteredExpenses.take(5).map((exp) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  color: Colors.grey.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F172A).withOpacity(0.1),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF0F172A), size: 20),
                    ),
                    title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${exp.date.day}/${exp.date.month}/${exp.date.year} · ${exp.module}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    trailing: Text(
                      '-${AppData.currency}${exp.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              })),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
