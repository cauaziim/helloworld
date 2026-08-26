import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TempocApp());
}

// ============================================================
// APP COM SUPORTE A IDIOMAS
// ============================================================

class TempocApp extends StatefulWidget {
  const TempocApp({super.key});

  @override
  State<TempocApp> createState() => _TempocAppState();
}

class _TempocAppState extends State<TempocApp> {
  Locale _locale = const Locale('pt', 'BR');

  void changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tempoc',
      locale: _locale,
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF6F8FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2458FF),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2458FF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: AppController(
        onLanguageChange: changeLanguage,
      ),
    );
  }
}

// ============================================================
// MODELOS
// ============================================================

class Sensor {
  String name;
  String type;
  String location;
  String wifi;
  String password;
  double temperature;
  double targetTemperature;
  bool online;
  bool isFavorite;
  String ownerEmail;

  List<double> history;
  List<String> monitoredItems;

  Sensor({
    required this.name,
    required this.type,
    required this.location,
    required this.wifi,
    required this.password,
    required this.ownerEmail,
    this.temperature = 4.2,
    this.targetTemperature = 3.0,
    this.online = true,
    this.isFavorite = false,
    List<double>? history,
    List<String>? monitoredItems,
  })  : history = history ??
            [
              3.1,
              4.2,
              5.0,
              4.4,
              5.8,
              4.9,
              5.3,
              6.1,
              5.5,
              6.8,
              5.9,
              4.7,
              4.0,
              4.5,
              5.2,
              4.2
            ],
        monitoredItems = monitoredItems ??
            [
              'Leite',
              'Queijo',
              'Carne',
            ];
}

// ============================================================
// CONTROLADOR PRINCIPAL
// ============================================================

class AppController extends StatefulWidget {
  final Function(String) onLanguageChange;

  const AppController({super.key, required this.onLanguageChange});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  int currentPage = 0;

  bool loggedIn = false;
  bool registered = false;

  String registeredEmail = '';
  String registeredPassword = '';
  String userName = '';
  String userPhoto = '';
  String userLanguage = 'pt';
  bool isDarkMode = false;

  final List<Sensor> sensors = [];
  final Map<String, List<Sensor>> userSensors = {};

  Timer? temperatureTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    temperatureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (sensors.isEmpty) return;

        setState(() {
          for (final sensor in sensors) {
            final variation = (Random().nextDouble() - 0.5) * 0.6;

            sensor.temperature =
                (sensor.temperature + variation).clamp(0.0, 15.0).toDouble();

            sensor.history.add(sensor.temperature);

            if (sensor.history.length > 20) {
              sensor.history.removeAt(0);
            }
          }
        });
        _saveSensors();
      },
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      registeredEmail = prefs.getString('email') ?? '';
      registeredPassword = prefs.getString('password') ?? '';
      userName = prefs.getString('name') ?? '';
      userPhoto = prefs.getString('photo') ?? '';
      userLanguage = prefs.getString('language') ?? 'pt';
      isDarkMode = prefs.getBool('darkMode') ?? false;
      registered = registeredEmail.isNotEmpty && registeredPassword.isNotEmpty;
    });
    widget.onLanguageChange(userLanguage);
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', registeredEmail);
    await prefs.setString('password', registeredPassword);
    await prefs.setString('name', userName);
    await prefs.setString('photo', userPhoto);
    await prefs.setString('language', userLanguage);
    await prefs.setBool('darkMode', isDarkMode);
  }

  Future<void> _loadSensors() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sensorsData = prefs.getString('sensors_$registeredEmail');
    if (sensorsData != null && sensorsData.isNotEmpty) {
      // Aqui você implementaria a desserialização dos sensores
    }
  }

  Future<void> _saveSensors() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sensorNames = sensors.map((s) => s.name).toList();
    await prefs.setString('sensors_$registeredEmail', sensorNames.join(','));
  }

  @override
  void dispose() {
    temperatureTimer?.cancel();
    _saveSensors();
    super.dispose();
  }

  void login(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      showMessage(_getTranslation('preencha_email_senha'));
      return;
    }

    if (!registered) {
      showMessage(_getTranslation('cadastre_primeiro'));
      return;
    }

    if (email.trim() != registeredEmail || password != registeredPassword) {
      showMessage(_getTranslation('email_senha_incorretos'));
      return;
    }

    setState(() {
      loggedIn = true;
      currentPage = 0;
    });

    _loadSensorsForUser(email.trim());

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _loadSensorsForUser(String email) {
    if (userSensors.containsKey(email)) {
      setState(() {
        sensors.clear();
        sensors.addAll(userSensors[email]!);
      });
    } else {
      setState(() {
        sensors.clear();
        userSensors[email] = [];
      });
    }
  }

  void register(
    String name,
    String email,
    String password,
    String age,
  ) {
    final int? ageInt = int.tryParse(age.trim());
    if (ageInt == null || ageInt < 18) {
      showMessage(_getTranslation('idade_invalida'));
      return;
    }

    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        age.trim().isEmpty) {
      showMessage(_getTranslation('preencha_todos'));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      showMessage(_getTranslation('email_invalido'));
      return;
    }

    if (password.length < 6) {
      showMessage(_getTranslation('senha_curta'));
      return;
    }

    if (!password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      showMessage(_getTranslation('senha_forte'));
      return;
    }

    setState(() {
      registered = true;
      registeredEmail = email.trim();
      registeredPassword = password;
      userName = name.trim();
      userPhoto = '';
    });

    _saveUserData();
    showMessage(_getTranslation('cadastro_sucesso'));
    Navigator.pop(context);
  }

  void logout() {
    _saveSensors();
    setState(() {
      loggedIn = false;
      currentPage = 0;
      sensors.clear();
    });
  }

  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(
          onRegister: register,
          onBack: () => Navigator.pop(context),
          onLogin: () {
            Navigator.pop(context);
          },
          getTranslation: _getTranslation,
        ),
      ),
    );
  }

  String _getTranslation(String key) {
    final translations = {
      'pt': {
        'preencha_email_senha': 'Preencha e-mail e senha.',
        'cadastre_primeiro': 'Cadastre uma conta primeiro.',
        'email_senha_incorretos': 'E-mail ou senha incorretos.',
        'preencha_todos': 'Preencha todos os campos.',
        'email_invalido': 'Digite um e-mail válido.',
        'senha_curta': 'A senha deve ter pelo menos 6 caracteres.',
        'senha_forte': 'A senha deve ter letras maiúsculas, minúsculas e números.',
        'cadastro_sucesso': 'Cadastro realizado com sucesso!',
        'idade_invalida': 'Você deve ter 18 anos ou mais para se cadastrar.',
        'entrar': 'Entrar',
        'cadastrar': 'Cadastrar',
        'nome': 'Nome completo',
        'email': 'E-mail',
        'senha': 'Senha',
        'confirmar_senha': 'Confirmar senha',
        'idade': 'Idade',
        'ja_tem_conta': 'Já tem uma conta?',
        'nao_tem_conta': 'Não tem uma conta?',
        'esqueceu_senha': 'Esqueceu a senha?',
        'meus_sensores': 'Meus Sensores',
        'favoritos': 'Favoritos',
        'perfil': 'Perfil',
        'sair': 'Sair da conta',
        'ajustar': 'Ajustar',
        'graficos': 'Gráficos',
        'historico': 'Histórico',
        'adicionar_sensor': 'Adicionar Sensor',
        'nenhum_sensor': 'Nenhum sensor cadastrado',
        'clique_adicionar': 'Clique no botão + para adicionar seu primeiro sensor.',
      },
      'en': {
        'preencha_email_senha': 'Please fill in email and password.',
        'cadastre_primeiro': 'Please register an account first.',
        'email_senha_incorretos': 'Incorrect email or password.',
        'preencha_todos': 'Please fill in all fields.',
        'email_invalido': 'Please enter a valid email.',
        'senha_curta': 'Password must be at least 6 characters.',
        'senha_forte': 'Password must have uppercase, lowercase and numbers.',
        'cadastro_sucesso': 'Registration successful!',
        'idade_invalida': 'You must be 18 or older to register.',
        'entrar': 'Login',
        'cadastrar': 'Register',
        'nome': 'Full name',
        'email': 'Email',
        'senha': 'Password',
        'confirmar_senha': 'Confirm password',
        'idade': 'Age',
        'ja_tem_conta': 'Already have an account?',
        'nao_tem_conta': "Don't have an account?",
        'esqueceu_senha': 'Forgot password?',
        'meus_sensores': 'My Sensors',
        'favoritos': 'Favorites',
        'perfil': 'Profile',
        'sair': 'Logout',
        'ajustar': 'Adjust',
        'graficos': 'Charts',
        'historico': 'History',
        'adicionar_sensor': 'Add Sensor',
        'nenhum_sensor': 'No sensors registered',
        'clique_adicionar': 'Click the + button to add your first sensor.',
      },
      'es': {
        'preencha_email_senha': 'Complete correo y contraseña.',
        'cadastre_primeiro': 'Registre una cuenta primero.',
        'email_senha_incorretos': 'Correo o contraseña incorrectos.',
        'preencha_todos': 'Complete todos los campos.',
        'email_invalido': 'Ingrese un correo válido.',
        'senha_curta': 'La contraseña debe tener al menos 6 caracteres.',
        'senha_forte': 'La contraseña debe tener mayúsculas, minúsculas y números.',
        'cadastro_sucesso': '¡Registro exitoso!',
        'idade_invalida': 'Debes tener 18 años o más para registrarte.',
        'entrar': 'Entrar',
        'cadastrar': 'Registrarse',
        'nome': 'Nombre completo',
        'email': 'Correo',
        'senha': 'Contraseña',
        'confirmar_senha': 'Confirmar contraseña',
        'idade': 'Edad',
        'ja_tem_conta': '¿Ya tienes una cuenta?',
        'nao_tem_conta': '¿No tienes una cuenta?',
        'esqueceu_senha': '¿Olvidaste tu contraseña?',
        'meus_sensores': 'Mis Sensores',
        'favoritos': 'Favoritos',
        'perfil': 'Perfil',
        'sair': 'Cerrar sesión',
        'ajustar': 'Ajustar',
        'graficos': 'Gráficos',
        'historico': 'Historial',
        'adicionar_sensor': 'Agregar Sensor',
        'nenhum_sensor': 'No hay sensores registrados',
        'clique_adicionar': 'Haz clic en el botón + para agregar tu primer sensor.',
      },
      'fr': {
        'preencha_email_senha': 'Veuillez remplir l\'email et le mot de passe.',
        'cadastre_primeiro': 'Veuillez d\'abord créer un compte.',
        'email_senha_incorretos': 'Email ou mot de passe incorrect.',
        'preencha_todos': 'Veuillez remplir tous les champs.',
        'email_invalido': 'Veuillez entrer un email valide.',
        'senha_curta': 'Le mot de passe doit comporter au moins 6 caractères.',
        'senha_forte': 'Le mot de passe doit contenir des majuscules, minuscules et chiffres.',
        'cadastro_sucesso': 'Inscription réussie !',
        'idade_invalida': 'Vous devez avoir 18 ans ou plus pour vous inscrire.',
        'entrar': 'Se connecter',
        'cadastrar': "S'inscrire",
        'nome': 'Nom complet',
        'email': 'Email',
        'senha': 'Mot de passe',
        'confirmar_senha': 'Confirmer le mot de passe',
        'idade': 'Âge',
        'ja_tem_conta': 'Vous avez déjà un compte ?',
        'nao_tem_conta': "Vous n'avez pas de compte ?",
        'esqueceu_senha': 'Mot de passe oublié ?',
        'meus_sensores': 'Mes Capteurs',
        'favoritos': 'Favoris',
        'perfil': 'Profil',
        'sair': 'Se déconnecter',
        'ajustar': 'Ajuster',
        'graficos': 'Graphiques',
        'historico': 'Historique',
        'adicionar_sensor': 'Ajouter un capteur',
        'nenhum_sensor': 'Aucun capteur enregistré',
        'clique_adicionar': 'Cliquez sur le bouton + pour ajouter votre premier capteur.',
      },
    };

    final lang = translations[userLanguage] ?? translations['pt']!;
    return lang[key] ?? key;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void addSensor(Sensor sensor) {
    setState(() {
      sensor.ownerEmail = registeredEmail;
      sensors.add(sensor);
      if (!userSensors.containsKey(registeredEmail)) {
        userSensors[registeredEmail] = [];
      }
      userSensors[registeredEmail]!.add(sensor);
      currentPage = 0;
    });
    _saveSensors();
    showMessage(_getTranslation('cadastro_sucesso'));
  }

  void deleteSensor(Sensor sensor) {
    setState(() {
      sensors.remove(sensor);
      if (userSensors.containsKey(registeredEmail)) {
        userSensors[registeredEmail]!.remove(sensor);
      }
    });
    _saveSensors();
    showMessage('Sensor removido.');
  }

  void toggleFavorite(Sensor sensor) {
    setState(() {
      sensor.isFavorite = !sensor.isFavorite;
    });
    _saveSensors();
    showMessage(sensor.isFavorite ? 'Adicionado aos favoritos!' : 'Removido dos favoritos!');
  }

  void updateUserName(String newName) {
    setState(() {
      userName = newName.trim();
    });
    _saveUserData();
    showMessage('Nome atualizado com sucesso!');
  }

  void updateUserPhoto(String photo) {
    setState(() {
      userPhoto = photo;
    });
    _saveUserData();
    showMessage('Foto atualizada com sucesso!');
  }

  void updateUserEmail(String newEmail) {
    setState(() {
      registeredEmail = newEmail.trim();
    });
    _saveUserData();
    showMessage('E-mail atualizado com sucesso!');
  }

  void updateUserPassword(String newPassword) {
    setState(() {
      registeredPassword = newPassword;
    });
    _saveUserData();
    showMessage('Senha atualizada com sucesso!');
  }

  void updateUserLanguage(String language) {
    setState(() {
      userLanguage = language;
    });
    _saveUserData();
    widget.onLanguageChange(language);
    showMessage('Idioma atualizado para ${_getLanguageName(language)}!');
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'Português';
    }
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _saveUserData();
    showMessage(isDarkMode ? 'Modo escuro ativado!' : 'Modo claro ativado!');
  }

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return SplashPage(
        onLogin: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(
                onLogin: login,
                onRegister: openRegister,
                onBack: () => Navigator.pop(context),
                getTranslation: _getTranslation,
              ),
            ),
          );
        },
        onRegister: openRegister,
        getTranslation: _getTranslation,
      );
    }

    return HomeShell(
      sensors: sensors,
      userName: userName,
      userPhoto: userPhoto,
      currentPage: currentPage,
      onPageChanged: (page) {
        setState(() {
          currentPage = page;
        });
      },
      onAddSensor: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SensorTypePage(
              onSensorTypeSelected: (type) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConfigureSensorPage(
                      sensorType: type,
                      onSave: (sensor) {
                        addSensor(sensor);
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      },
                      getTranslation: _getTranslation,
                    ),
                  ),
                );
              },
              getTranslation: _getTranslation,
            ),
          ),
        );
      },
      onSensorTap: (sensor) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SensorDetailsPage(
              sensor: sensor,
              onDelete: () {
                deleteSensor(sensor);
                Navigator.pop(context);
              },
              onToggleFavorite: () {
                toggleFavorite(sensor);
              },
              getTranslation: _getTranslation,
            ),
          ),
        );
      },
      onLogout: logout,
      onUpdateName: updateUserName,
      onUpdatePhoto: updateUserPhoto,
      onUpdateEmail: updateUserEmail,
      onUpdatePassword: updateUserPassword,
      onUpdateLanguage: updateUserLanguage,
      onToggleDarkMode: toggleDarkMode,
      isDarkMode: isDarkMode,
      currentEmail: registeredEmail,
      currentPassword: registeredPassword,
      currentLanguage: userLanguage,
      getTranslation: _getTranslation,
    );
  }
}

// ============================================================
// SPLASH PAGE
// ============================================================

class SplashPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final String Function(String) getTranslation;

  const SplashPage({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF1F4FF),
              Color(0xFFDDE8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.thermostat_rounded,
                    size: 80,
                    color: Color(0xFF1756FF),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Tempoc',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF112B67),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SISTEMA IoT DE\nMONITORAMENTO\nDE TEMPERATURA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF334777),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                AppButton(
                  text: getTranslation('entrar'),
                  onPressed: onLogin,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: getTranslation('cadastrar'),
                  outlined: true,
                  onPressed: onRegister,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  final Function(String, String) onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;
  final String Function(String) getTranslation;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
    required this.getTranslation,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.getTranslation('entrar'),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Acesse sua conta',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 22),
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEAF0FF),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF1855FF),
                  size: 32,
                ),
              ),
              const SizedBox(height: 30),
              AppTextField(
                controller: emailController,
                label: widget.getTranslation('email'),
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: passwordController,
                label: widget.getTranslation('senha'),
                obscureText: hidePassword,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Recuperação de senha disponível na próxima versão.',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    widget.getTranslation('esqueceu_senha'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF164BFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AppButton(
                text: widget.getTranslation('entrar'),
                onPressed: () {
                  widget.onLogin(
                    emailController.text,
                    passwordController.text,
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.getTranslation('nao_tem_conta')),
                  GestureDetector(
                    onTap: widget.onRegister,
                    child: Text(
                      widget.getTranslation('cadastrar'),
                      style: const TextStyle(
                        color: Color(0xFF164BFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER PAGE
// ============================================================

class RegisterPage extends StatefulWidget {
  final Function(String, String, String, String) onRegister;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final String Function(String) getTranslation;

  const RegisterPage({
    super.key,
    required this.onRegister,
    required this.onBack,
    required this.onLogin,
    required this.getTranslation,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final ageController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirm = true;

  void submit() {
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('As senhas não são iguais.'),
        ),
      );
      return;
    }

    widget.onRegister(
      nameController.text,
      emailController.text,
      passwordController.text,
      ageController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.getTranslation('cadastrar'),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Crie sua conta',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE2F7FF),
                child: const Icon(
                  Icons.person_outline,
                  size: 35,
                  color: Color(0xFF1762FF),
                ),
              ),
              const SizedBox(height: 25),
              AppTextField(
                controller: nameController,
                label: widget.getTranslation('nome'),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: emailController,
                label: widget.getTranslation('email'),
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: passwordController,
                label: widget.getTranslation('senha'),
                obscureText: hidePassword,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: confirmController,
                label: widget.getTranslation('confirmar_senha'),
                obscureText: hideConfirm,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hideConfirm = !hideConfirm;
                    });
                  },
                  icon: Icon(
                    hideConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: ageController,
                label: widget.getTranslation('idade'),
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              AppButton(
                text: widget.getTranslation('cadastrar'),
                onPressed: submit,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.getTranslation('ja_tem_conta')),
                  GestureDetector(
                    onTap: widget.onLogin,
                    child: Text(
                      widget.getTranslation('entrar'),
                      style: const TextStyle(
                        color: Color(0xFF164BFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME SHELL
// ============================================================

class HomeShell extends StatelessWidget {
  final List<Sensor> sensors;
  final String userName;
  final String userPhoto;
  final int currentPage;
  final Function(int) onPageChanged;
  final VoidCallback onAddSensor;
  final Function(Sensor) onSensorTap;
  final VoidCallback onLogout;
  final Function(String) onUpdateName;
  final Function(String) onUpdatePhoto;
  final Function(String) onUpdateEmail;
  final Function(String) onUpdatePassword;
  final Function(String) onUpdateLanguage;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final String currentEmail;
  final String currentPassword;
  final String currentLanguage;
  final String Function(String) getTranslation;

  const HomeShell({
    super.key,
    required this.sensors,
    required this.userName,
    required this.userPhoto,
    required this.currentPage,
    required this.onPageChanged,
    required this.onAddSensor,
    required this.onSensorTap,
    required this.onLogout,
    required this.onUpdateName,
    required this.onUpdatePhoto,
    required this.onUpdateEmail,
    required this.onUpdatePassword,
    required this.onUpdateLanguage,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.currentEmail,
    required this.currentPassword,
    required this.currentLanguage,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (currentPage) {
      case 1:
        body = FavoritesPage(
          sensors: sensors.where((s) => s.isFavorite).toList(),
          onSensorTap: onSensorTap,
          getTranslation: getTranslation,
        );
        break;

      case 2:
        body = ProfilePage(
          name: userName,
          photo: userPhoto,
          onLogout: onLogout,
          onUpdateName: onUpdateName,
          onUpdatePhoto: onUpdatePhoto,
          onUpdateEmail: onUpdateEmail,
          onUpdatePassword: onUpdatePassword,
          onUpdateLanguage: onUpdateLanguage,
          onToggleDarkMode: onToggleDarkMode,
          isDarkMode: isDarkMode,
          currentEmail: currentEmail,
          currentPassword: currentPassword,
          currentLanguage: currentLanguage,
          getTranslation: getTranslation,
        );
        break;

      default:
        body = SensorsHomePage(
          sensors: sensors,
          onAddSensor: onAddSensor,
          onSensorTap: onSensorTap,
          getTranslation: getTranslation,
        );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: onPageChanged,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: getTranslation('meus_sensores'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: getTranslation('favoritos'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: getTranslation('perfil'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SENSORS HOME PAGE
// ============================================================

class SensorsHomePage extends StatelessWidget {
  final List<Sensor> sensors;
  final VoidCallback onAddSensor;
  final Function(Sensor) onSensorTap;
  final String Function(String) getTranslation;

  const SensorsHomePage({
    super.key,
    required this.sensors,
    required this.onAddSensor,
    required this.onSensorTap,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    getTranslation('meus_sensores'),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nenhuma nova notificação.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: sensors.isEmpty
                  ? EmptySensorView(
                      onAddSensor: onAddSensor,
                      getTranslation: getTranslation,
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              ...sensors.map(
                                (sensor) => SensorCard(
                                  sensor: sensor,
                                  onTap: () => onSensorTap(sensor),
                                  onFavoriteToggle: () {},
                                  getTranslation: getTranslation,
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: AddButton(
                            onPressed: onAddSensor,
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
}

class EmptySensorView extends StatelessWidget {
  final VoidCallback onAddSensor;
  final String Function(String) getTranslation;

  const EmptySensorView({
    super.key,
    required this.onAddSensor,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 65,
              color: Color(0xFF527EFF),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            getTranslation('nenhum_sensor'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            getTranslation('clique_adicionar'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          AddButton(
            onPressed: onAddSensor,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SENSOR CARD
// ============================================================

class SensorCard extends StatelessWidget {
  final Sensor sensor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final String Function(String) getTranslation;

  const SensorCard({
    super.key,
    required this.sensor,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  sensorIcon(sensor.type),
                  color: const Color(0xFF2458FF),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sensor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (sensor.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sensor.type,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: sensor.online ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sensor.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: sensor.online ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${sensor.temperature.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SENSOR TYPE PAGE
// ============================================================

class SensorTypePage extends StatelessWidget {
  final Function(String) onSensorTypeSelected;
  final String Function(String) getTranslation;

  const SensorTypePage({
    super.key,
    required this.onSensorTypeSelected,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      ['Sensor de Câmara Fria', 'câmara fria', Icons.ac_unit],
      ['Sensor de Geladeira', 'geladeira', Icons.kitchen],
      ['Sensor de Freezer', 'freezer', Icons.inventory_2],
      ['Sensor de Ambiente', 'ambiente', Icons.home_outlined],
      ['Outro Sensor', 'outro', Icons.sensors],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslation('adicionar_sensor'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione o tipo de sensor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ...types.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      onSensorTypeSelected(type[0] as String);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE4E8F0),
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              type[2] as IconData,
                              color: const Color(0xFF2458FF),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              type[0] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CONFIGURE SENSOR PAGE
// ============================================================

class ConfigureSensorPage extends StatefulWidget {
  final String sensorType;
  final Function(Sensor) onSave;
  final String Function(String) getTranslation;

  const ConfigureSensorPage({
    super.key,
    required this.sensorType,
    required this.onSave,
    required this.getTranslation,
  });

  @override
  State<ConfigureSensorPage> createState() => _ConfigureSensorPageState();
}

class _ConfigureSensorPageState extends State<ConfigureSensorPage> {
  final locationController = TextEditingController();
  final wifiController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool hidePassword = true;

  void save() {
    if (locationController.text.trim().isEmpty ||
        wifiController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos.'),
        ),
      );
      return;
    }

    final sensor = Sensor(
      name: nameController.text.trim(),
      type: widget.sensorType,
      location: locationController.text.trim(),
      wifi: wifiController.text.trim(),
      password: passwordController.text,
      ownerEmail: '',
      temperature: widget.sensorType.contains('Ambiente') ? 23.5 : 4.2,
      targetTemperature: widget.sensorType.contains('Ambiente') ? 22 : 3,
    );

    widget.onSave(sensor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configurar Sensor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preencha as informações',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: locationController,
              label: 'Local',
              hint: 'Ex: Cozinha, Estoque, Câmara 1',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 13),
            AppTextField(
              controller: wifiController,
              label: 'Rede Wi-Fi',
              hint: 'Selecione a rede Wi-Fi',
              icon: Icons.wifi,
            ),
            const SizedBox(height: 13),
            AppTextField(
              controller: passwordController,
              label: 'Senha da Rede',
              obscureText: hidePassword,
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 13),
            AppTextField(
              controller: nameController,
              label: 'Nome do Sensor',
              hint: 'Ex: Geladeira da Cozinha',
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 30),
            AppButton(
              text: 'Salvar e Conectar',
              onPressed: save,
              icon: Icons.wifi,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SENSOR DETAILS PAGE
// ============================================================

class SensorDetailsPage extends StatefulWidget {
  final Sensor sensor;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final String Function(String) getTranslation;

  const SensorDetailsPage({
    super.key,
    required this.sensor,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.getTranslation,
  });

  @override
  State<SensorDetailsPage> createState() => _SensorDetailsPageState();
}

class _SensorDetailsPageState extends State<SensorDetailsPage> {
  final TextEditingController _itemController = TextEditingController();

  void openTemperatureAdjust() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemperatureAdjustSheet(
        sensor: widget.sensor,
        onConfirm: (value) {
          setState(() {
            widget.sensor.targetTemperature = value;
          });
          Navigator.pop(context);
        },
        getTranslation: widget.getTranslation,
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar Item'),
        content: TextField(
          controller: _itemController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do item',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _itemController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (_itemController.text.trim().isNotEmpty) {
                setState(() {
                  widget.sensor.monitoredItems.add(_itemController.text.trim());
                });
                _itemController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item adicionado com sucesso!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeItem(String item) {
    setState(() {
      widget.sensor.monitoredItems.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$item" removido com sucesso!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensor = widget.sensor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          sensor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              widget.onToggleFavorite();
              setState(() {});
            },
            icon: Icon(
              sensor.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: sensor.isFavorite ? Colors.red : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir sensor?'),
                    content: const Text(
                      'O sensor será removido da lista.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete();
                        },
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Excluir sensor'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // TEMPERATURA ATUAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Temperatura Atual',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${sensor.temperature.toStringAsFixed(1)} °C',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    StatusChip(
                      temperature: sensor.temperature,
                      target: sensor.targetTemperature,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TemperatureStat(
                          title: 'Mínima',
                          value: '2 °C',
                        ),
                        TemperatureStat(
                          title: 'Máxima',
                          value: '8 °C',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // AJUSTAR TEMPERATURA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.getTranslation('ajustar'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${sensor.targetTemperature.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('−'),
                        Expanded(
                          child: Slider(
                            value: sensor.targetTemperature.clamp(0, 10),
                            min: 0,
                            max: 10,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                sensor.targetTemperature = value;
                              });
                            },
                          ),
                        ),
                        const Text('+'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ITENS MONITORADOS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Itens Monitorados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                    ...sensor.monitoredItems.map(
                      (item) => ItemRow(
                        item: item,
                        temperature: sensor.temperature,
                        onRemove: () => _removeItem(item),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // BOTÕES
              Row(
                children: [
                  Expanded(
                    child: SmallActionButton(
                      icon: Icons.tune,
                      text: widget.getTranslation('ajustar'),
                      onTap: openTemperatureAdjust,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SmallActionButton(
                      icon: Icons.show_chart,
                      text: widget.getTranslation('graficos'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GraphPage(sensor: sensor),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SmallActionButton(
                      icon: Icons.history,
                      text: widget.getTranslation('historico'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryPage(sensor: sensor),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TEMPERATURE ADJUST SHEET
// ============================================================

class TemperatureAdjustSheet extends StatefulWidget {
  final Sensor sensor;
  final Function(double) onConfirm;
  final String Function(String) getTranslation;

  const TemperatureAdjustSheet({
    super.key,
    required this.sensor,
    required this.onConfirm,
    required this.getTranslation,
  });

  @override
  State<TemperatureAdjustSheet> createState() => _TemperatureAdjustSheetState();
}

class _TemperatureAdjustSheetState extends State<TemperatureAdjustSheet> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.sensor.targetTemperature;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.getTranslation('ajustar'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${value.toStringAsFixed(0)} °C',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Alvo',
            style: TextStyle(color: Colors.grey),
          ),
          Slider(
            value: value.clamp(0, 10),
            min: 0,
            max: 10,
            divisions: 20,
            onChanged: (newValue) {
              setState(() {
                value = newValue;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0°C'),
              Text('Faixa recomendada: 2°C - 8°C'),
              Text('10°C'),
            ],
          ),
          const SizedBox(height: 22),
          AppButton(
            text: 'Confirmar',
            onPressed: () {
              widget.onConfirm(value);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GRAPH PAGE
// ============================================================

class GraphPage extends StatelessWidget {
  final Sensor sensor;

  const GraphPage({
    super.key,
    required this.sensor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gráficos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Temperatura (°C)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF1F4FA),
                        ),
                        child: const Text(
                          'Últimos 7 dias',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      painter: TemperatureChartPainter(sensor.history),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Mínima',
                    value:
                        '${sensor.history.reduce(min).toStringAsFixed(1)}°C',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Máxima',
                    value:
                        '${sensor.history.reduce(max).toStringAsFixed(1)}°C',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    title: 'Média',
                    value:
                        '${average(sensor.history).toStringAsFixed(1)}°C',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 17,
                ),
                SizedBox(width: 7),
                Text(
                  'Todos os dados estão atualizados',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTORY PAGE
// ============================================================

class HistoryPage extends StatelessWidget {
  final Sensor sensor;

  const HistoryPage({
    super.key,
    required this.sensor,
  });

  @override
  Widget build(BuildContext context) {
    final history = sensor.history.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: history.length,
        itemBuilder: (_, index) {
          final temp = history[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEAF0FF),
                child: const Icon(
                  Icons.thermostat,
                  color: Color(0xFF2458FF),
                ),
              ),
              title: Text(
                '${temp.toStringAsFixed(1)} °C',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Registro ${index + 1}'),
              trailing: Icon(
                temp >= 2 && temp <= 8
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: temp >= 2 && temp <= 8 ? Colors.green : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// FAVORITES PAGE
// ============================================================

class FavoritesPage extends StatelessWidget {
  final List<Sensor> sensors;
  final Function(Sensor) onSensorTap;
  final String Function(String) getTranslation;

  const FavoritesPage({
    super.key,
    required this.sensors,
    required this.onSensorTap,
    required this.getTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslation('favoritos'),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: sensors.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum sensor favorito.\nToque no ❤️ em um sensor para adicionar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: sensors
                          .map(
                            (sensor) => SensorCard(
                              sensor: sensor,
                              onTap: () => onSensorTap(sensor),
                              onFavoriteToggle: () {},
                              getTranslation: getTranslation,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatefulWidget {
  final String name;
  final String photo;
  final VoidCallback onLogout;
  final Function(String) onUpdateName;
  final Function(String) onUpdatePhoto;
  final Function(String) onUpdateEmail;
  final Function(String) onUpdatePassword;
  final Function(String) onUpdateLanguage;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final String currentEmail;
  final String currentPassword;
  final String currentLanguage;
  final String Function(String) getTranslation;

  const ProfilePage({
    super.key,
    required this.name,
    required this.photo,
    required this.onLogout,
    required this.onUpdateName,
    required this.onUpdatePhoto,
    required this.onUpdateEmail,
    required this.onUpdatePassword,
    required this.onUpdateLanguage,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.currentEmail,
    required this.currentPassword,
    required this.currentLanguage,
    required this.getTranslation,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        widget.onUpdatePhoto(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: widget.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite seu nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onUpdateName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog() {
    final controller = TextEditingController(text: widget.currentEmail);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar E-mail'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite seu novo e-mail',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  controller.text.contains('@')) {
                widget.onUpdateEmail(controller.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite um e-mail válido!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showEditPasswordDialog() {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    bool hidePass = true;
    bool hideConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Alterar Senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  obscureText: hidePass,
                  decoration: InputDecoration(
                    hintText: 'Nova senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          hidePass = !hidePass;
                        });
                      },
                      icon: Icon(
                        hidePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  obscureText: hideConfirm,
                  decoration: InputDecoration(
                    hintText: 'Confirmar nova senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('A senha deve ter pelo menos 6 caracteres!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (controller.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('As senhas não coincidem!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  widget.onUpdatePassword(controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = {
      'pt': 'Português',
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selecionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: widget.currentLanguage == entry.key
                  ? const Icon(Icons.check, color: Color(0xFF2458FF))
                  : null,
              onTap: () {
                widget.onUpdateLanguage(entry.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.getTranslation('perfil'),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Foto de perfil
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (widget.photo.isNotEmpty && File(widget.photo).existsSync()
                          ? FileImage(File(widget.photo))
                          : null),
                  child: _imageFile == null &&
                          (widget.photo.isEmpty || !File(widget.photo).existsSync())
                      ? const Icon(
                          Icons.person,
                          size: 55,
                          color: Color(0xFF2458FF),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2458FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.name.isEmpty ? 'Usuário' : widget.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _showEditNameDialog,
                  icon: const Icon(
                    Icons.edit,
                    size: 20,
                    color: Color(0xFF2458FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),

            // Opções do perfil
            ProfileOption(
              icon: Icons.person_outline,
              title: 'Editar Nome',
              onTap: _showEditNameDialog,
            ),
            ProfileOption(
              icon: Icons.photo_camera_outlined,
              title: 'Alterar Foto',
              onTap: _pickImage,
            ),
            ProfileOption(
              icon: Icons.email_outlined,
              title: 'Alterar E-mail',
              onTap: _showEditEmailDialog,
            ),
            ProfileOption(
              icon: Icons.lock_outline,
              title: 'Alterar Senha',
              onTap: _showEditPasswordDialog,
            ),
            ProfileOption(
              icon: Icons.language,
              title: 'Idioma',
              subtitle: _getLanguageName(widget.currentLanguage),
              onTap: _showLanguageDialog,
            ),
            ProfileOption(
              icon: widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: widget.isDarkMode ? 'Modo Escuro' : 'Modo Claro',
              onTap: widget.onToggleDarkMode,
              trailing: Switch(
                value: widget.isDarkMode,
                onChanged: (_) => widget.onToggleDarkMode(),
                activeColor: const Color(0xFF2458FF),
              ),
            ),
            ProfileOption(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configurações de notificação em breve!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ProfileOption(
              icon: Icons.help_outline,
              title: 'Ajuda',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajuda disponível em breve!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const Spacer(),

            AppButton(
              text: widget.getTranslation('sair'),
              outlined: true,
              icon: Icons.logout,
              onPressed: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'Português';
    }
  }
}

// ============================================================
// WIDGETS
// ============================================================

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool outlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
          label: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1855FF),
            side: const BorderSide(color: Color(0xFF1855FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF164BFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 19) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF2458FF),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(0xFF1749FF),
              Color(0xFF5427FF),
            ],
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final double temperature;
  final double target;

  const StatusChip({
    super.key,
    required this.temperature,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final normal = (temperature - target).abs() <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: normal ? const Color(0xFFE3F8E8) : const Color(0xFFFFE9D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normal ? 'Normal' : 'Atenção',
        style: TextStyle(
          color: normal ? Colors.green : Colors.orange.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class TemperatureStat extends StatelessWidget {
  final String title;
  final String value;

  const TemperatureStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ItemRow extends StatelessWidget {
  final String item;
  final double temperature;
  final VoidCallback onRemove;

  const ItemRow({
    super.key,
    required this.item,
    required this.temperature,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final good = temperature >= 2 && temperature <= 8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            good ? 'Bom estado' : 'Atenção',
            style: TextStyle(
              color: good ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: good ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close,
              size: 16,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const SmallActionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2458FF),
              size: 21,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: const Color(0xFF2458FF),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

// ============================================================
// TEMPERATURE CHART PAINTER
// ============================================================

class TemperatureChartPainter extends CustomPainter {
  final List<double> values;

  TemperatureChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF365CFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = const Color(0xFF365CFF)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF5)
      ..strokeWidth = 1;

    const horizontalLines = 5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height * i / horizontalLines;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;
    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final double x = values.length == 1
          ? 0.0
          : i * size.width / (values.length - 1);
      final double normalized = (values[i] - minValue) / range;
      final double y = size.height - (normalized * (size.height - 20)) - 10;
      final Offset point = Offset(x, y);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawCircle(point, 3.5, paintPoint);
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

// ============================================================
// FUNÇÕES AUXILIARES
// ============================================================

IconData sensorIcon(String type) {
  if (type.contains('Câmara')) return Icons.ac_unit;
  if (type.contains('Geladeira')) return Icons.kitchen;
  if (type.contains('Freezer')) return Icons.inventory_2;
  if (type.contains('Ambiente')) return Icons.home_outlined;
  return Icons.sensors;
}

double average(List<double> values) {
  if (values.isEmpty) return 0;
  double total = 0;
  for (final value in values) {
    total += value;
  }
  return total / values.length;
}