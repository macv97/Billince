import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  _buildCenteredSetting(
                    icon: Icons.language,
                    color: Colors.blueGrey,
                    title: 'Idioma',
                    child: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      alignment: Alignment.center,
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) { if (v != null) settings.setLanguage(v); },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCenteredSetting(
                    icon: Icons.dark_mode,
                    color: Colors.indigo,
                    title: 'Tema Visual',
                    child: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox(),
                      alignment: Alignment.center,
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('Automático')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
                      ],
                      onChanged: (v) { if (v != null) settings.setThemeMode(v); },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCenteredSetting(
                    icon: Icons.color_lens,
                    color: Colors.orange,
                    title: 'Color Principal',
                    child: DropdownButton<int>(
                      value: settings.interfaceColor.value,
                      underline: const SizedBox(),
                      alignment: Alignment.center,
                      items: const [
                        DropdownMenuItem(value: 0xFF0F172A, child: Text('Midnight Blue')),
                        DropdownMenuItem(value: 0xFF4B0082, child: Text('Indigo')),
                        DropdownMenuItem(value: 0xFF800000, child: Text('Maroon')),
                        DropdownMenuItem(value: 0xFF2F4F4F, child: Text('Slate Gray')),
                      ],
                      onChanged: (v) { if (v != null) settings.setInterfaceColor(Color(v)); },
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('Accesibilidad Visual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  _buildCenteredSetting(
                    icon: Icons.visibility,
                    color: Colors.teal,
                    title: 'Modo Daltonismo',
                    child: DropdownButton<ColorBlindnessMode>(
                      value: settings.colorBlindnessMode,
                      underline: const SizedBox(),
                      alignment: Alignment.center,
                      items: const [
                        DropdownMenuItem(value: ColorBlindnessMode.none, child: Text('Desactivado')),
                        DropdownMenuItem(value: ColorBlindnessMode.protanopia, child: Text('Protanopia')),
                        DropdownMenuItem(value: ColorBlindnessMode.deuteranopia, child: Text('Deuteranopia')),
                        DropdownMenuItem(value: ColorBlindnessMode.tritanopia, child: Text('Tritanopia')),
                      ],
                      onChanged: (v) { if (v != null) settings.setColorBlindnessMode(v); },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCenteredSetting(
                    icon: Icons.text_increase,
                    color: Colors.teal,
                    title: 'Tamaño de Texto',
                    child: Slider(
                      value: settings.textScaleFactor,
                      min: 1.0,
                      max: 1.5,
                      divisions: 5,
                      label: '${settings.textScaleFactor}',
                      onChanged: (v) { settings.setTextScaleFactor(v); },
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

  bool _isLoadingAuth = false;

  void _showAuthDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLogin = true;
    String? errorMessage;
    
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
                              });
                              
                              try {
                                if (isLogin) {
                                  await SupabaseRepository.signIn(email, password);
                                } else {
                                  await SupabaseRepository.signUp(email, password);
                                }
                                if (mounted) {
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
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                isLogin = !isLogin;
                                errorMessage = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión', 
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15)
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
      builder: (context) {
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
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.person_rounded, size: 50, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Modo Invitado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                'Actualmente tus datos solo se guardan en este dispositivo. Inicia sesión para activar el respaldo en la nube y sincronización.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade400, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAuthDialog();
                },
                icon: const Icon(Icons.cloud_sync_rounded),
                label: const Text('Iniciar Sesión / Registrarse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              )
            ],
          ),
        );
      }
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
                        ]
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.visibility, size: 80, color: Color(0xFF0F172A)), // Vision/Lynx Eye
                        ],
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
                    const SizedBox(height: 10),
                    Text(
                      'Tu control de gastos, simple y claro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey.shade300,
                        letterSpacing: 0.5,
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
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white70, size: 30),
                    onPressed: _showProfileDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 30),
                    onPressed: _showSettingsDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredSetting({required IconData icon, required Color color, required String title, required Widget child}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
