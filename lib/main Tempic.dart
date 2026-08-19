import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const TempocApp());
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

  List<double> history;
  List<String> monitoredItems;

  Sensor({
    required this.name,
    required this.type,
    required this.location,
    required this.wifi,
    required this.password,
    this.temperature = 4.2,
    this.targetTemperature = 3.0,
    this.online = true,
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
// APP
// ============================================================

class TempocApp extends StatelessWidget {
  const TempocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tempoc',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF6F8FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2458FF),
        ),
      ),
      home: const AppController(),
    );
  }
}

// ============================================================
// CONTROLADOR PRINCIPAL
// ============================================================

class AppController extends StatefulWidget {
  const AppController({super.key});

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

  final List<Sensor> sensors = [];

  Timer? temperatureTimer;

  @override
  void initState() {
    super.initState();

    temperatureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (sensors.isEmpty) return;

        setState(() {
          for (final sensor in sensors) {
            final variation =
                (Random().nextDouble() - 0.5) * 0.6;

            sensor.temperature =
                (sensor.temperature + variation)
                    .clamp(0.0, 15.0)
                    .toDouble();

            sensor.history.add(sensor.temperature);

            if (sensor.history.length > 20) {
              sensor.history.removeAt(0);
            }
          }
        });
      },
    );
  }

  @override
  void dispose() {
    temperatureTimer?.cancel();
    super.dispose();
  }

  void login(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      showMessage('Preencha e-mail e senha.');
      return;
    }

    if (!registered) {
      showMessage('Cadastre uma conta primeiro.');
      return;
    }

    if (email.trim() != registeredEmail ||
        password != registeredPassword) {
      showMessage('E-mail ou senha incorretos.');
      return;
    }

    setState(() {
      loggedIn = true;
      currentPage = 0;
    });
  }

  void register(
    String name,
    String email,
    String password,
    String age,
  ) {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty ||
        age.trim().isEmpty) {
      showMessage('Preencha todos os campos.');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Digite um e-mail válido.');
      return;
    }

    if (password.length < 6) {
      showMessage('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      registered = true;
      registeredEmail = email.trim();
      registeredPassword = password;
      userName = name.trim();
    });

    showMessage('Cadastro realizado com sucesso!');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: login,
          onRegister: openRegister,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void logout() {
    setState(() {
      loggedIn = false;
      currentPage = 0;
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
        ),
      ),
    );
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
      sensors.add(sensor);
      currentPage = 0;
    });

    showMessage('Sensor adicionado com sucesso!');
  }

  void deleteSensor(Sensor sensor) {
    setState(() {
      sensors.remove(sensor);
    });

    showMessage('Sensor removido.');
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
              ),
            ),
          );
        },
        onRegister: openRegister,
      );
    }

    return HomeShell(
      sensors: sensors,
      userName: userName,
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
                    ),
                  ),
                );
              },
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
            ),
          ),
        );
      },
      onLogout: logout,
    );
  }
}

// ============================================================
// SPLASH
// ============================================================

class SplashPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const SplashPage({
    super.key,
    required this.onLogin,
    required this.onRegister,
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

                // LOGO
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.05),
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
                  text: 'Entrar',
                  onPressed: onLogin,
                ),

                const SizedBox(height: 12),

                AppButton(
                  text: 'Cadastrar',
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
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  final Function(String, String) onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
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

              const Text(
                'Entrar',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                'Acesse sua conta',
                style: TextStyle(
                  color: Colors.grey,
                ),
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
                label: 'E-mail',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 12),

              AppTextField(
                controller: passwordController,
                label: 'Senha',
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
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF164BFF),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              AppButton(
                text: 'Entrar',
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
                  const Text('Não tem uma conta? '),
                  GestureDetector(
                    onTap: widget.onRegister,
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(
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
// CADASTRO
// ============================================================

class RegisterPage extends StatefulWidget {
  final Function(String, String, String, String) onRegister;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  const RegisterPage({
    super.key,
    required this.onRegister,
    required this.onBack,
    required this.onLogin,
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
        const SnackBar(
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

              const Text(
                'Cadastrar',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
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
                label: 'Nome completo',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 10),

              AppTextField(
                controller: emailController,
                label: 'E-mail',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 10),

              AppTextField(
                controller: passwordController,
                label: 'Senha',
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
                label: 'Confirmar senha',
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
                label: 'Idade',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 18),

              AppButton(
                text: 'Cadastrar',
                onPressed: submit,
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem uma conta? '),
                  GestureDetector(
                    onTap: widget.onLogin,
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
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
// HOME
// ============================================================

class HomeShell extends StatelessWidget {
  final List<Sensor> sensors;
  final String userName;
  final int currentPage;
  final Function(int) onPageChanged;
  final VoidCallback onAddSensor;
  final Function(Sensor) onSensorTap;
  final VoidCallback onLogout;

  const HomeShell({
    super.key,
    required this.sensors,
    required this.userName,
    required this.currentPage,
    required this.onPageChanged,
    required this.onAddSensor,
    required this.onSensorTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (currentPage) {
      case 1:
        body = FavoritesPage(sensors: sensors);
        break;

      case 2:
        body = ProfilePage(
          name: userName,
          onLogout: onLogout,
        );
        break;

      default:
        body = SensorsHomePage(
          sensors: sensors,
          onAddSensor: onAddSensor,
          onSensorTap: onSensorTap,
        );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: onPageChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME SEM SENSOR
// ============================================================

class SensorsHomePage extends StatelessWidget {
  final List<Sensor> sensors;
  final VoidCallback onAddSensor;
  final Function(Sensor) onSensorTap;

  const SensorsHomePage({
    super.key,
    required this.sensors,
    required this.onAddSensor,
    required this.onSensorTap,
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
                const Expanded(
                  child: Text(
                    'Meus Sensores',
                    style: TextStyle(
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
                    )
                  : ListView(
                      children: [
                        ...sensors.map(
                          (sensor) => SensorCard(
                            sensor: sensor,
                            onTap: () => onSensorTap(sensor),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
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

  const EmptySensorView({
    super.key,
    required this.onAddSensor,
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

          const Text(
            'Nenhum sensor cadastrado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Clique no botão + para adicionar\nseu primeiro sensor.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
// CARD SENSOR
// ============================================================

class SensorCard extends StatelessWidget {
  final Sensor sensor;
  final VoidCallback onTap;

  const SensorCard({
    super.key,
    required this.sensor,
    required this.onTap,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
                            color: sensor.online
                                ? Colors.green
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sensor.online
                              ? 'Online'
                              : 'Offline',
                          style: TextStyle(
                            color: sensor.online
                                ? Colors.green
                                : Colors.red,
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
// TIPO DE SENSOR
// ============================================================

class SensorTypePage extends StatelessWidget {
  final Function(String) onSensorTypeSelected;

  const SensorTypePage({
    super.key,
    required this.onSensorTypeSelected,
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
        title: const Text(
          'Adicionar Sensor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione o tipo de sensor',
              style: TextStyle(
                color: Colors.grey,
              ),
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
                              borderRadius:
                                  BorderRadius.circular(10),
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
                          const Icon(
                            Icons.chevron_right,
                          ),
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
// CONFIGURAR SENSOR
// ============================================================

class ConfigureSensorPage extends StatefulWidget {
  final String sensorType;
  final Function(Sensor) onSave;

  const ConfigureSensorPage({
    super.key,
    required this.sensorType,
    required this.onSave,
  });

  @override
  State<ConfigureSensorPage> createState() =>
      _ConfigureSensorPageState();
}

class _ConfigureSensorPageState
    extends State<ConfigureSensorPage> {
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
      temperature:
          widget.sensorType.contains('Ambiente') ? 23.5 : 4.2,
      targetTemperature:
          widget.sensorType.contains('Ambiente') ? 22 : 3,
    );

    widget.onSave(sensor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurar Sensor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preencha as informações',
              style: TextStyle(
                color: Colors.grey,
              ),
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
// DETALHES DO SENSOR
// ============================================================

class SensorDetailsPage extends StatefulWidget {
  final Sensor sensor;
  final VoidCallback onDelete;

  const SensorDetailsPage({
    super.key,
    required this.sensor,
    required this.onDelete,
  });

  @override
  State<SensorDetailsPage> createState() =>
      _SensorDetailsPageState();
}

class _SensorDetailsPageState
    extends State<SensorDetailsPage> {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
                        onPressed: () =>
                            Navigator.pop(context),
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ajustar Temperatura',
                            style: TextStyle(
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
                            value: sensor.targetTemperature
                                .clamp(0, 10),
                            min: 0,
                            max: 10,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                sensor.targetTemperature =
                                    value;
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

              // ITENS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                          onPressed: () {
                            showAddItemDialog(context, sensor);
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    ...sensor.monitoredItems.map(
                      (item) => ItemRow(
                        item: item,
                        temperature: sensor.temperature,
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
                      text: 'Ajustar',
                      onTap: openTemperatureAdjust,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SmallActionButton(
                      icon: Icons.show_chart,
                      text: 'Gráficos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GraphPage(sensor: sensor),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SmallActionButton(
                      icon: Icons.history,
                      text: 'Histórico',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoryPage(sensor: sensor),
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
// AJUSTE DE TEMPERATURA
// ============================================================

class TemperatureAdjustSheet extends StatefulWidget {
  final Sensor sensor;
  final Function(double) onConfirm;

  const TemperatureAdjustSheet({
    super.key,
    required this.sensor,
    required this.onConfirm,
  });

  @override
  State<TemperatureAdjustSheet> createState() =>
      _TemperatureAdjustSheetState();
}

class _TemperatureAdjustSheetState
    extends State<TemperatureAdjustSheet> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.sensor.targetTemperature;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        25,
        24,
        30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ajustar Temperatura',
            style: TextStyle(
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
// GRÁFICOS
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                          borderRadius:
                              BorderRadius.circular(8),
                          color: const Color(0xFFF1F4FA),
                        ),
                        child: const Text(
                          'Últimos 7 dias',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      painter: TemperatureChartPainter(
                        sensor.history,
                      ),
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
                  style: TextStyle(
                    fontSize: 12,
                  ),
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
// HISTÓRICO
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Registro ${index + 1}',
              ),
              trailing: Icon(
                temp >= 2 && temp <= 8
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: temp >= 2 && temp <= 8
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// FAVORITOS
// ============================================================

class FavoritesPage extends StatelessWidget {
  final List<Sensor> sensors;

  const FavoritesPage({
    super.key,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Favoritos',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: sensors.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum sensor favorito.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView(
                      children: sensors
                          .map(
                            (sensor) => SensorCard(
                              sensor: sensor,
                              onTap: () {},
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
// PERFIL
// ============================================================

class ProfilePage extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFEAF0FF),
              child: Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF2458FF),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              name.isEmpty ? 'Usuário' : name,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            ProfileOption(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              onTap: () {},
            ),

            ProfileOption(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              onTap: () {},
            ),

            ProfileOption(
              icon: Icons.help_outline,
              title: 'Ajuda',
              onTap: () {},
            ),

            const Spacer(),

            AppButton(
              text: 'Sair da conta',
              outlined: true,
              icon: Icons.logout,
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
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
          icon: icon != null
              ? Icon(icon, size: 18)
              : const SizedBox.shrink(),
          label: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1855FF),
            side: const BorderSide(
              color: Color(0xFF1855FF),
            ),
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
        icon: icon != null
            ? Icon(icon, size: 18)
            : const SizedBox.shrink(),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
        prefixIcon:
            icon != null ? Icon(icon, size: 19) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE0E4EC),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE0E4EC),
          ),
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
    final normal =
        (temperature - target).abs() <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: normal
            ? const Color(0xFFE3F8E8)
            : const Color(0xFFFFE9D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normal ? 'Normal' : 'Atenção',
        style: TextStyle(
          color: normal
              ? Colors.green
              : Colors.orange.shade800,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ItemRow extends StatelessWidget {
  final String item;
  final double temperature;

  const ItemRow({
    super.key,
    required this.item,
    required this.temperature,
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
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          Text(
            good ? 'Bom estado' : 'Atenção',
            style: TextStyle(
              color: good
                  ? Colors.green
                  : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: good
                  ? Colors.green
                  : Colors.orange,
              shape: BoxShape.circle,
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
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
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
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
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
      trailing: const Icon(
        Icons.chevron_right,
      ),
    );
  }
}

// ============================================================
// GRÁFICO PERSONALIZADO
// ============================================================

class TemperatureChartPainter extends CustomPainter {
  final List<double> values;

  TemperatureChartPainter(this.values);

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
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

    for (int i = 0;
        i <= horizontalLines;
        i++) {
      final y =
          size.height * i / horizontalLines;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);

    final range =
        maxValue - minValue == 0
            ? 1
            : maxValue - minValue;

    final path = Path();

    for (int i = 0;
        i < values.length;
        i++) {
      final x = values.length == 1
          ? 0
          : i *
              size.width /
              (values.length - 1);

      final normalized =
          (values[i] - minValue) / range;

      final y =
          size.height -
          (normalized * (size.height - 20)) -
          10;

      final point = Offset(x.toDouble(), y.toDouble());

      if (i == 0) {
        path.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        path.lineTo(
          point.dx,
          point.dy,
        );
      }

      canvas.drawCircle(
        point,
        3.5,
        paintPoint,
      );
    }

    canvas.drawPath(
      path,
      paintLine,
    );
  }

  @override
  bool shouldRepaint(
    covariant TemperatureChartPainter oldDelegate,
  ) {
    return oldDelegate.values != values;
  }
}

// ============================================================
// FUNÇÕES AUXILIARES
// ============================================================

IconData sensorIcon(String type) {
  if (type.contains('Câmara')) {
    return Icons.ac_unit;
  }

  if (type.contains('Geladeira')) {
    return Icons.kitchen;
  }

  if (type.contains('Freezer')) {
    return Icons.inventory_2;
  }

  if (type.contains('Ambiente')) {
    return Icons.home_outlined;
  }

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

void showAddItemDialog(
  BuildContext context,
  Sensor sensor,
) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          'Adicionar item',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Frutas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                sensor.monitoredItems.add(
                  controller.text.trim(),
                );
              }

              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
}