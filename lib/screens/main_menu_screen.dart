import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'expenses_screen.dart';
import 'checklist_screen.dart';
import 'summary_screen.dart';
import 'shared_expenses_screen.dart';
import 'calendar_screen.dart';
import '../data/settings_provider.dart';
import '../data/app_data.dart';

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
        actions: [
          // Currency selector
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: AppData.currency,
                icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary, size: 20),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: '€', child: Text('€')),
                  DropdownMenuItem(value: '\$', child: Text('\$')),
                  DropdownMenuItem(value: '£', child: Text('£')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    AppData.currency = val;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.primary),
            tooltip: 'Ajustes',
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
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
                subtitle: 'Organiza tus compras y analiza hábitos',
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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ajustes y Accesibilidad', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.indigo),
                    title: const Text('Tema'),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('Automático')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setThemeMode(v);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.color_lens, color: Colors.orange),
                    title: const Text('Color Principal'),
                    trailing: DropdownButton<int>(
                      value: settings.interfaceColor.toARGB32(),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 0xFF0F172A, child: Text('Midnight Blue')),
                        DropdownMenuItem(value: 0xFF4B0082, child: Text('Indigo')),
                        DropdownMenuItem(value: 0xFF800000, child: Text('Maroon')),
                        DropdownMenuItem(value: 0xFF2F4F4F, child: Text('Slate Gray')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setInterfaceColor(Color(v));
                      },
                    ),
                  ),
                  const Divider(),
                  const Text('Accesibilidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.teal),
                    title: const Text('Modo Daltonismo'),
                    trailing: DropdownButton<ColorBlindnessMode>(
                      value: settings.colorBlindnessMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ColorBlindnessMode.none, child: Text('Normal')),
                        DropdownMenuItem(value: ColorBlindnessMode.protanopia, child: Text('Protanopia')),
                        DropdownMenuItem(value: ColorBlindnessMode.deuteranopia, child: Text('Deuteranopia')),
                        DropdownMenuItem(value: ColorBlindnessMode.tritanopia, child: Text('Tritanopia')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setColorBlindnessMode(v);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.text_increase, color: Colors.teal),
                    title: const Text('Tamaño de Texto'),
                    subtitle: Slider(
                      value: settings.textScaleFactor,
                      min: 1.0,
                      max: 1.5,
                      divisions: 5,
                      label: '${settings.textScaleFactor}x',
                      onChanged: (v) => settings.setTextScaleFactor(v),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
