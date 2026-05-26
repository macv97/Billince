import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_data.dart';
import '../data/settings_provider.dart';
import '../data/supabase_repository.dart';
import 'main_menu_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedCurrency = '€';
  late StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        try {
          final cloudGroups = await SupabaseRepository.fetchUserGroups();
          AppData.sharedGroups.clear();
          AppData.sharedGroups.addAll(cloudGroups);
          
          final cloudChecklists = await SupabaseRepository.fetchUserSharedChecklists();
          AppData.sharedChecklists.clear();
          AppData.sharedChecklists.addAll(cloudChecklists);
          
          final cloudExpenses = await SupabaseRepository.fetchUserExpenses();
          for (var ce in cloudExpenses) {
            if (!AppData.expenses.any((e) => e.id == ce.id)) {
              AppData.expenses.add(ce);
            }
          }
          AppData.expenses.sort((a, b) => b.date.compareTo(a.date));
        } catch (_) {}
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _showSettingsDialog() {
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
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Nota: Los cambios fuera de línea pueden tardar en sincronizarse.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
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

  bool _isLoadingAuth = false;

  void _showAuthDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLogin = true;
    String? errorMessage;
    String? successMessage;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final primaryColor = Theme.of(context).colorScheme.primary;
            return Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF0F172A) 
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                ]
              ),
              padding: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin ? 'Inicia sesión para sincronizar tus gastos.' : 'Únete a Billince y sincroniza en la nube.',
                      style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1), 
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)), 
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    if (successMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1), 
                          border: Border.all(color: Colors.green.withOpacity(0.3)), 
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(child: Text(successMessage!, style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    TextField(
                      controller: emailController,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico', 
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600),
                        prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Contraseña', 
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    if (_isLoadingAuth) 
                      const CircularProgressIndicator(color: Colors.amber)
                    else 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor, 
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();
                              
                              if (email.isEmpty || password.isEmpty) {
                                setModalState(() => errorMessage = 'Por favor rellena ambos campos.');
                                return;
                              }

                              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                              if (!emailRegex.hasMatch(email)) {
                                setModalState(() => errorMessage = 'Formato de correo no válido.');
                                return;
                              }
                              
                              if (!isLogin && password.length < 6) {
                                setModalState(() => errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
                                return;
                              }

                              setModalState(() {
                                _isLoadingAuth = true;
                                errorMessage = null;
                                successMessage = null;
                              });
                              
                              try {
                                if (isLogin) {
                                  await SupabaseRepository.signIn(email, password);
                                } else {
                                  await SupabaseRepository.signUp(email, password);
                                  if (SupabaseRepository.currentUser == null) {
                                    setModalState(() {
                                      successMessage = 'Cuenta creada con éxito. Revisa tu correo electrónico para verificarla.';
                                      _isLoadingAuth = false;
                                    });
                                    return;
                                  }
                                }
                                if (mounted) {
                                  // Recargar datos de la nube tras login
                                  try {
                                    final cloudGroups = await SupabaseRepository.fetchUserGroups();
                                    AppData.sharedGroups.clear();
                                    AppData.sharedGroups.addAll(cloudGroups);
                                    
                                    final cloudChecklists = await SupabaseRepository.fetchUserSharedChecklists();
                                    AppData.sharedChecklists.clear();
                                    AppData.sharedChecklists.addAll(cloudChecklists);
                                    
                                    final cloudExpenses = await SupabaseRepository.fetchUserExpenses();
                                    for (var ce in cloudExpenses) {
                                      if (!AppData.expenses.any((e) => e.id == ce.id)) {
                                        AppData.expenses.add(ce);
                                      }
                                    }
                                    AppData.expenses.sort((a, b) => b.date.compareTo(a.date));
                                  } catch (_) {}
                                  
                                  Navigator.pop(ctx);
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuScreen()));
                                }
                              } catch (e) {
                                final msg = e.toString();
                                setModalState(() {
                                  if (msg.contains('Invalid login credentials')) {
                                    errorMessage = 'Credenciales incorrectas.';
                                  } else if (msg.contains('already registered')) {
                                    errorMessage = 'Este correo ya está registrado.';
                                  } else {
                                    errorMessage = 'Ha ocurrido un error. Inténtalo de nuevo.';
                                  }
                                });
                              } finally {
                                setModalState(() => _isLoadingAuth = false);
                              }
                            },
                            child: Text(isLogin ? 'Entrar a mi cuenta' : 'Crear mi cuenta', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              setModalState(() {
                                _isLoadingAuth = true;
                                errorMessage = null;
                                successMessage = null;
                              });
                              try {
                                await SupabaseRepository.signInWithGoogle();
                                if (mounted) {
                                  Navigator.pop(ctx);
                                }
                              } catch (e) {
                                setModalState(() {
                                  if (e.toString().contains('sign_in_canceled') || e.toString().contains('cancelado')) {
                                    errorMessage = 'Inicio de sesión cancelado.';
                                  } else {
                                    errorMessage = 'Error al conectar con Google. Verifica tu conexión o configuración.';
                                  }
                                  _isLoadingAuth = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.g_mobiledata, size: 30),
                            label: const Text('Continuar con Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                isLogin = !isLogin;
                                errorMessage = null;
                                successMessage = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión', 
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.amber : primaryColor, fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showProfileDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isLogged = SupabaseRepository.isAuthenticated;
        final userEmail = SupabaseRepository.currentUser?.email ?? 'Usuario no identificado';

        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF0F172A) 
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isLogged ? const Color(0xFF10B981) : Colors.amber, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Icon(
                        Icons.person_rounded, 
                        size: 50, 
                        color: isLogged ? const Color(0xFF10B981) : Colors.amber
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogged ? 'Perfil Sincronizado' : 'Modo Invitado', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLogged ? userEmail : 'Actualmente tus datos solo se guardan en este dispositivo. Inicia sesión para activar el respaldo en la nube y sincronización.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade400, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      if (isLogged) {
                        await SupabaseRepository.signOut();
                        if (mounted) {
                          setState(() {});
                        }
                      } else {
                        _showAuthDialog();
                      }
                    },
                    icon: Icon(isLogged ? Icons.logout : Icons.cloud_sync_rounded),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isLogged ? 'Cerrar Sesión' : 'Iniciar Sesión / Registrarse', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLogged ? Colors.red.shade50 : Theme.of(context).colorScheme.primary,
                      foregroundColor: isLogged ? Colors.red : Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                  if (isLogged) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _showDeleteAccountConfirmation(sheetCtx),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      label: const Text('Eliminar cuenta permanentemente', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showDeleteAccountConfirmation(BuildContext sheetCtx) {
    showDialog(
      context: sheetCtx,
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
                  context: this.context,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                );
                
                try {
                  await SupabaseRepository.deleteUserAccount();
                  if (mounted) {
                    Navigator.of(this.context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Cuenta eliminada con éxito.')),
                    );
                    setState(() {}); // Refresh WelcomeScreen state
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(this.context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(this.context).showSnackBar(
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

  void _showMockSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate/Midnight
      body: SafeArea(
        child: Column(
          children: [
            // Currency Selector Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.amber),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                          DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                          DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                            AppData.currency = val; // Global update
                            _showMockSnack('Moneda cambiada a $val');
                          }
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // LOGO: Lynx + Bill Concept
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.amber, // Sharp Lynx Eye color
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text(
                      'Billince',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber, // Sharp action color
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                            ),
                            onPressed: _showAuthDialog,
                            child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                              );
                            },
                            child: const Text('Continuar sin iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'En modo invitado los datos solo se guardarán localmente en este dispositivo. Inicia sesión para disponer de copia de seguridad en la nube y acceder a eventos compartidos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            
            // Bottom Submenu (Profile & Settings)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: IconButton(
                      icon: Icon(
                        SupabaseRepository.isAuthenticated ? Icons.person_rounded : Icons.person_outline, 
                        color: SupabaseRepository.isAuthenticated ? const Color(0xFF10B981) : Colors.white70, 
                        size: 24
                      ),
                      onPressed: _showProfileDialog,
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
                      onPressed: _showSettingsDialog,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
