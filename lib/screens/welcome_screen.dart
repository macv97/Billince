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
                  const Text('Ajustes y Accesibilidad', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.blueGrey),
                    title: const Text('Idioma'),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setLanguage(v);
                      },
                    ),
                  ),
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
                    title: const Text('Colores de Interfaz'),
                    trailing: DropdownButton<int>(
                      value: settings.interfaceColor.value,
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
                  const Text('Accesibilidad Visual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.teal),
                    title: const Text('Modo Daltonismo'),
                    subtitle: const Text('Ajuste de colores global'),
                    trailing: DropdownButton<ColorBlindnessMode>(
                      value: settings.colorBlindnessMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ColorBlindnessMode.none, child: Text('Desactivado')),
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
                      label: '${settings.textScaleFactor}',
                      onChanged: (v) {
                        settings.setTextScaleFactor(v);
                      },
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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isLogin ? 'Iniciar Sesión' : 'Registrarse', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.redAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                    ),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Contraseña', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (_isLoadingAuth) const CircularProgressIndicator(color: Colors.amber)
                  else Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          
                          if (email.isEmpty || password.isEmpty) {
                            setModalState(() => errorMessage = 'Por favor rellena ambos campos.');
                            return;
                          }

                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(email)) {
                            setModalState(() => errorMessage = 'El formato del email no es válido. Asegúrate de incluir "@" y un dominio (ej: usuario@gmail.com).');
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
                            await SupabaseRepository.loadUserSettings();
                            await SupabaseRepository.loadInitialData();
                            if (mounted) {
                              Navigator.pop(ctx);
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuScreen()));
                            }
                          } catch (e) {
                            final msg = e.toString();
                            setModalState(() {
                              if (msg.contains('Invalid login credentials')) {
                                errorMessage = 'Credenciales incorrectas. Comprueba tu email y contraseña.';
                              } else if (msg.contains('already registered')) {
                                errorMessage = 'Este correo ya está registrado. Prueba a iniciar sesión.';
                              } else if (msg.contains('invalid format') || msg.contains('validate email')) {
                                errorMessage = 'El formato del email no es válido.';
                              } else if (msg.contains('Email not confirmed')) {
                                errorMessage = 'Debes confirmar tu email antes de iniciar sesión. Revisa tu bandeja de entrada.';
                              } else if (msg.contains('Password should be at least')) {
                                errorMessage = 'La contraseña es demasiado corta. Usa al menos 6 caracteres.';
                              } else {
                                errorMessage = 'Ha ocurrido un error. Inténtalo de nuevo.';
                              }
                            });
                          } finally {
                            setModalState(() => _isLoadingAuth = false);
                          }
                        },
                        child: Text(isLogin ? 'Entrar' : 'Crear Cuenta', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            isLogin = !isLogin;
                            errorMessage = null;
                          });
                        },
                        child: Text(isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión', style: const TextStyle(color: Colors.amber)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () => _showMockSnack('Login con Google en desarrollo'),
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('Continuar con Google'),
                      ),
                    ],
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

  void _showProfileDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Mi Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Inicia sesión para guardar tus datos en la nube y sincronizar con otros dispositivos.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMockSnack('Inicio de sesión en desarrollo');
                },
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sincronizar en la Nube'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
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
                      'Visión experta para tus finanzas',
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
}
