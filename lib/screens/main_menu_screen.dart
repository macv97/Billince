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
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProfileSheet(context),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Column(
                children: [
                  _buildListCard(
                    context,
                    title: 'Mis gastos e ingresos',
                    subtitle: 'Registra gastos, ingresos personales',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF3B82F6), // Blue
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                  ),
                  _buildListCard(
                    context,
                    title: 'Mis listas',
                    subtitle: 'Crea listas personales o compartidas',
                    icon: Icons.shopping_cart_rounded,
                    color: const Color(0xFF0D9488), // Teal
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistScreen())),
                  ),
                  _buildListCard(
                    context,
                    title: 'Mis eventos',
                    subtitle: 'Organiza tus grupos y eventos',
                    icon: Icons.group_rounded,
                    color: const Color(0xFFF59E0B), // Amber
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedExpensesScreen())),
                  ),
                  _buildListCard(
                    context,
                    title: 'Resumen general',
                    subtitle: 'Analiza tus movimientos',
                    icon: Icons.insights_rounded,
                    color: const Color(0xFF8B5CF6), // Purple
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Wide card for calendar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -2)
                  ]
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, size: 34, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Calendario', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                                SizedBox(height: 4),
                                Text('Eventos y vencimientos', style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
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

  Widget _buildListCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark 
      ? Theme.of(context).cardColor.withOpacity(0.8) 
      : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1), 
          width: 1.5
        ),
        boxShadow: isDark 
          ? [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 8))] 
          : [BoxShadow(color: color.withOpacity(0.12), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 12))],
        gradient: isDark 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                Colors.transparent,
              ],
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: color.withOpacity(0.1),
          splashColor: color.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Icon(icon, size: 30, color: isDark ? color.withOpacity(0.9) : color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -0.5)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? color.withOpacity(0.1) : Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? color.withOpacity(0.7) : Colors.grey.shade400, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredSetting(BuildContext context, {required IconData icon, required Color color, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
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
                  const Text('Ajustes y Accesibilidad', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  _buildCenteredSetting(context,
                    icon: Icons.language,
                    color: Colors.blueGrey,
                    title: 'Idioma',
                    child: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      alignment: Alignment.centerRight,
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (v) { if (v != null) settings.setLanguage(v); },
                    ),
                  ),
                  _buildCenteredSetting(context,
                    icon: Icons.dark_mode,
                    color: Colors.indigo,
                    title: 'Tema Visual',
                    child: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox(),
                      alignment: Alignment.centerRight,
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('Auto', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Claro', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Oscuro', style: TextStyle(fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (v) { if (v != null) settings.setThemeMode(v); },
                    ),
                  ),
                  _buildCenteredSetting(context,
                    icon: Icons.color_lens,
                    color: Colors.orange,
                    title: 'Color Principal',
                    child: DropdownButton<int>(
                      value: settings.interfaceColor.value,
                      underline: const SizedBox(),
                      alignment: Alignment.centerRight,
                      items: const [
                        DropdownMenuItem(value: 0xFF0F172A, child: Text('Midnight', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: 0xFF4B0082, child: Text('Indigo', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: 0xFF800000, child: Text('Maroon', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: 0xFF2F4F4F, child: Text('Slate', style: TextStyle(fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (v) { if (v != null) settings.setInterfaceColor(Color(v)); },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                    child: Text('Accesibilidad Visual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                  ),
                  _buildCenteredSetting(context,
                    icon: Icons.visibility,
                    color: Colors.teal,
                    title: 'Daltonismo',
                    child: DropdownButton<ColorBlindnessMode>(
                      value: settings.colorBlindnessMode,
                      underline: const SizedBox(),
                      alignment: Alignment.centerRight,
                      items: const [
                        DropdownMenuItem(value: ColorBlindnessMode.none, child: Text('No', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: ColorBlindnessMode.protanopia, child: Text('Protanopia', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: ColorBlindnessMode.deuteranopia, child: Text('Deuteranopia', style: TextStyle(fontWeight: FontWeight.w500))),
                        DropdownMenuItem(value: ColorBlindnessMode.tritanopia, child: Text('Tritanopia', style: TextStyle(fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (v) { if (v != null) settings.setColorBlindnessMode(v); },
                    ),
                  ),
                  _buildCenteredSetting(context,
                    icon: Icons.text_increase,
                    color: Colors.teal,
                    title: 'Tamaño Texto',
                    child: Slider(
                      value: settings.textScaleFactor,
                      min: 1.0,
                      max: 1.5,
                      divisions: 5,
                      label: '${settings.textScaleFactor}',
                      onChanged: (v) { settings.setTextScaleFactor(v); },
                    ),
                  ),
                  _buildCenteredSetting(context,
                    icon: Icons.fingerprint,
                    color: Colors.teal,
                    title: 'Huella Dactilar',
                    child: Switch(
                      value: settings.useBiometrics,
                      onChanged: (v) { settings.setUseBiometrics(v); },
                      activeColor: Colors.teal,
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

  void _showProfileSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
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
                      backgroundColor: isLogged ? Colors.red.shade50 : Theme.of(parentContext).colorScheme.primary,
                      foregroundColor: isLogged ? Colors.red : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(isLogged ? Icons.logout : Icons.login),
                    label: Text(isLogged ? 'Cerrar sesión' : 'Iniciar sesión / Registrarse'),
                    onPressed: () {
                      Navigator.pop(sheetCtx); // Close sheet
                      if (isLogged) {
                        SupabaseRepository.signOut();
                      }
                      Navigator.pushAndRemoveUntil(
                        parentContext,
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                if (isLogged) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _showDeleteAccountConfirmation(parentContext, sheetCtx),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    label: const Text('Eliminar cuenta permanentemente', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext parentContext, BuildContext sheetCtx) {
    showDialog(
      context: parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('¿Eliminar cuenta?'),
          content: const Text('Esta acción es irreversible. Eliminará por completo tu cuenta y todos tus datos (gastos, listas y participación en eventos) de la nube de forma permanente.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(sheetCtx); // Close profile sheet
                
                // Mostrar indicador de carga
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                );
                
                try {
                  await SupabaseRepository.deleteUserAccount();
                  if (parentContext.mounted) {
                    Navigator.of(parentContext).pop(); // Close loading dialog
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Cuenta eliminada con éxito.')),
                    );
                    Navigator.pushAndRemoveUntil(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (parentContext.mounted) {
                    Navigator.of(parentContext).pop(); // Close loading dialog
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Error al eliminar la cuenta. Por favor, inténtelo más tarde.')),
                    );
                  }
                }
              },
              child: const Text('Eliminar definitivamente', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
