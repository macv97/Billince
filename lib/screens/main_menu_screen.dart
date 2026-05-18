import 'package:flutter/material.dart';
import 'expenses_screen.dart';
import 'checklist_screen.dart';
import 'summary_screen.dart';
import 'shared_expenses_screen.dart';
import 'calendar_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
              child: Icon(Icons.visibility, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Billince',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: colorScheme.primary, fontSize: 24),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Text(
                'Tu control financiero',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '¿Qué necesitas gestionar hoy?',
                style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              _buildMenuCard(
                context,
                title: 'Gestión de Gastos',
                subtitle: 'Escanea tickets y controla tus finanzas',
                icon: Icons.receipt_long,
                color: colorScheme.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
              ),
              const SizedBox(height: 14),
              _buildMenuCard(
                context,
                title: 'Gastos Compartidos',
                subtitle: 'Comparte cuentas y cuadra saldos',
                icon: Icons.group,
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedExpensesScreen())),
              ),
              const SizedBox(height: 14),
              _buildMenuCard(
                context,
                title: 'Lista de la Compra',
                subtitle: 'Organiza tus compras con análisis IA',
                icon: Icons.checklist_rtl,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistScreen())),
              ),
              const SizedBox(height: 14),
              _buildMenuCard(
                context,
                title: 'Resumen y Gráficos',
                subtitle: 'Visualiza en qué te gastas el dinero',
                icon: Icons.pie_chart,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())),
              ),
              const SizedBox(height: 14),
              _buildMenuCard(
                context,
                title: 'Calendario y Eventos',
                subtitle: 'Agenda personal y tareas diarias',
                icon: Icons.calendar_month,
                color: Colors.deepPurple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
