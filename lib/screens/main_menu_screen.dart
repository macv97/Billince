import 'package:flutter/material.dart';
import 'expenses_screen.dart';
import 'checklist_screen.dart';
import 'summary_screen.dart';
import 'shared_expenses_screen.dart';

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
            // Tiny Logo in AppBar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.tertiary, // Amber
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility, color: Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Billince', 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.2, 
                color: colorScheme.primary,
                fontSize: 24,
              )
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Tu control financiero',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.primary), // Dark slate
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '¿Qué necesitas gestionar hoy?',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              _buildMenuCard(
                context,
                title: 'Gestión de Gastos',
                subtitle: 'Escanea tickets y controla tus finanzas diarias',
                icon: Icons.receipt_long,
                color: colorScheme.primary, // Dark Slate
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Gastos Compartidos',
                subtitle: 'Comparte cuentas y calcula quién debe a quién',
                icon: Icons.group,
                color: colorScheme.tertiary, // Amber
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SharedExpensesScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Lista de la Compra',
                subtitle: 'Organiza tus compras con IA y OCR',
                icon: Icons.checklist_rtl,
                color: colorScheme.secondary, // Emerald Green
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChecklistScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Resumen y Gráficos',
                subtitle: 'Visualiza en qué te gastas el dinero',
                icon: Icons.pie_chart,
                color: Colors.blueGrey, // Neutral color for statistics
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SummaryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
