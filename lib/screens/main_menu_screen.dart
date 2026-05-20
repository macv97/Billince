import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'expenses_screen.dart';
import 'checklist_screen.dart';
import 'summary_screen.dart';
import 'shared_expenses_screen.dart';
import 'calendar_screen.dart';
import '../data/settings_provider.dart';
import '../data/app_data.dart';
import '../data/supabase_repository.dart';
import 'welcome_screen.dart';

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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProfileSheet(context),
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: SupabaseRepository.isAuthenticated ? const Color(0xFF10B981).withOpacity(0.2) : colorScheme.primary.withOpacity(0.15),
                    radius: 18,
                    child: Icon(Icons.person_rounded, color: SupabaseRepository.isAuthenticated ? const Color(0xFF10B981) : colorScheme.primary, size: 20),
                  ),
                  if (SupabaseRepository.isAuthenticated)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus finanzas,',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary, height: 1.1),
              ),
              Text(
                'bajo control experto.',
                style: TextStyle(fontSize: 22, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.85,
                children: [
                  _buildGridCard(
                    context,
                    title: 'Facturación',
                    subtitle: 'Escaneo Inteligente',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF3B82F6), // Blue
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                  ),
                  _buildGridCard(
                    context,
                    title: 'Checklists',
                    subtitle: 'Listas de Compra',
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF0D9488), // Teal
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistScreen())),
                  ),
                  _buildGridCard(
                    context,
                    title: 'Grupos',
                    subtitle: 'Gastos Compartidos',
                    icon: Icons.group_rounded,
                    color: const Color(0xFFF59E0B), // Amber
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedExpensesScreen())),
                  ),
                  _buildGridCard(
                    context,
                    title: 'Analíticas',
                    subtitle: 'Insights',
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF8B5CF6), // Purple
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Wide card for calendar
              Card(
                elevation: 4,
                shadowColor: colorScheme.primary.withOpacity(0.2),
                color: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Calendario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(height: 4),
                              Text('Eventos y vencimientos', style: TextStyle(fontSize: 14, color: Colors.white70)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? color.withOpacity(0.15) : Colors.white;
    final borderColor = isDark ? color.withOpacity(0.3) : color.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark ? [] : [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final isLogged = SupabaseRepository.isAuthenticated;
        final userEmail = SupabaseRepository.currentUser?.email ?? 'Usuario no identificado';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: isLogged ? const Color(0xFF10B981).withOpacity(0.2) : Colors.blueGrey.withOpacity(0.2),
                  radius: 40,
                  child: Icon(Icons.person_rounded, size: 40, color: isLogged ? const Color(0xFF10B981) : Colors.blueGrey),
                ),
                const SizedBox(height: 16),
                Text(
                  isLogged ? 'Perfil Sincronizado' : 'Modo Offline',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogged ? userEmail : 'Los datos se guardan solo en este dispositivo.',
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLogged ? Colors.red.shade50 : Theme.of(context).colorScheme.primary,
                      foregroundColor: isLogged ? Colors.red : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(isLogged ? Icons.logout : Icons.login),
                    label: Text(isLogged ? 'Cerrar sesión' : 'Iniciar sesión / Registrarse'),
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      if (isLogged) {
                        SupabaseRepository.signOut();
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
