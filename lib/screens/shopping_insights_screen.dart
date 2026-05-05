import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/checklist_item.dart';

class ShoppingInsightsScreen extends StatelessWidget {
  const ShoppingInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Gather stats ─────────────────────────────────────
    int totalLists = AppData.shoppingLists.length;
    int totalProducts = 0;
    int completedProducts = 0;
    Map<String, int> productFrequency = {};
    Map<int, int> shoppingDays = {}; // weekday → count

    for (var list in AppData.shoppingLists) {
      // Track creation day of week
      final weekday = list.dateCreated.weekday;
      shoppingDays[weekday] = (shoppingDays[weekday] ?? 0) + 1;

      for (var item in list.items) {
        totalProducts++;
        if (item.isDone) completedProducts++;

        final normalized = item.title.trim().toLowerCase();
        if (normalized.isNotEmpty) {
          productFrequency[normalized] = (productFrequency[normalized] ?? 0) + 1;
        }
      }
    }

    // Top products
    final sortedProducts = productFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = sortedProducts.take(5).toList();

    // Most popular shopping day
    String mostPopularDay = '—';
    if (shoppingDays.isNotEmpty) {
      final topDay = shoppingDays.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      const dayNames = {1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves', 5: 'Viernes', 6: 'Sábado', 7: 'Domingo'};
      mostPopularDay = dayNames[topDay] ?? '—';
    }

    // Completion rate
    final completionRate = totalProducts > 0 ? (completedProducts / totalProducts * 100) : 0.0;

    // ── AI Advice ────────────────────────────────────────
    String aiAdvice = _generateAdvice(topProducts, mostPopularDay, completionRate, totalLists);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Compras'),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── AI Advisor Card ──────────────────────────
            _buildAIAdviceCard(aiAdvice),
            const SizedBox(height: 24),

            // ── Quick Stats ──────────────────────────────
            const Text('Tu Actividad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildStatChip(Icons.list_alt, '$totalLists', 'Listas creadas', const Color(0xFF0F172A))),
                const SizedBox(width: 10),
                Expanded(child: _buildStatChip(Icons.shopping_bag, '$totalProducts', 'Productos totales', const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
                Expanded(child: _buildStatChip(Icons.check_circle, '${completionRate.toStringAsFixed(0)}%', 'Completados', const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 24),

            // ── Shopping Patterns ────────────────────────
            const Text('Patrones de Compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Día favorito para comprar', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(mostPopularDay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Top Products Ranking ─────────────────────
            const Text('Tus Imprescindibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Productos que más repites en tus listas.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            topProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.auto_graph, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text('Aún no hay suficientes datos.\nCrea listas para empezar a ver patrones.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: topProducts.asMap().entries.map((e) {
                      final i = e.key;
                      final entry = e.value;
                      final medals = ['🥇', '🥈', '🥉'];
                      final medal = i < 3 ? medals[i] : '${i + 1}°';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.grey.shade50,
                        child: ListTile(
                          leading: Text(medal, style: const TextStyle(fontSize: 22)),
                          title: Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${entry.value}x', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

            // ── Weekly Distribution ──────────────────────
            if (shoppingDays.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Distribución Semanal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _buildWeeklyChart(shoppingDays),
            ],
          ],
        ),
      ),
    );
  }

  String _generateAdvice(List<MapEntry<String, int>> topProducts, String day, double rate, int totalLists) {
    if (totalLists == 0) {
      return '¡Bienvenido! Empieza creando tu primera lista de la compra. A medida que vayas comprando, el asistente IA aprenderá tus patrones y te dará consejos personalizados.';
    }
    final buffer = StringBuffer();
    if (topProducts.isNotEmpty) {
      buffer.write('Compras "${topProducts.first.key}" con frecuencia. ');
    }
    if (day != '—') {
      buffer.write('Tu día favorito para hacer la compra es el $day. ');
    }
    if (rate < 70) {
      buffer.write('Solo completas un ${rate.toStringAsFixed(0)}% de tus listas — intenta planificar mejor para reducir el desperdicio. ');
    } else {
      buffer.write('¡Buen trabajo! Completas el ${rate.toStringAsFixed(0)}% de tus listas. ');
    }
    if (topProducts.length >= 3) {
      buffer.write('Tus básicos son: ${topProducts.take(3).map((e) => e.key).join(", ")}. Busca packs u ofertas para estos productos.');
    }
    return buffer.toString();
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAIAdviceCard(String advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Lince IA Advisor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Text(advice, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('Beta IA', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<int, int> shoppingDays) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final maxCount = shoppingDays.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final count = shoppingDays[i + 1] ?? 0;
            final height = maxCount > 0 ? (count / maxCount) * 60 : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: height + 4,
                  decoration: BoxDecoration(
                    color: count > 0 ? const Color(0xFFF59E0B) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(days[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
