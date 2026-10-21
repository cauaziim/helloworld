import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.140.170.19/pdm_api/tarefas.php',
);


String foldText(String input) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString().trim();
}


enum TaskPriority {
  baixa('Baixa'),
  media('Média'),
  alta('Alta');

  const TaskPriority(this.label);
  final String label;

  static TaskPriority parse(Object? value) {
    final text = foldText(value?.toString() ?? '');
    for (final priority in TaskPriority.values) {
      if (priority.name == text) return priority;
    }
    return TaskPriority.media;
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    this.priority = TaskPriority.media,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final bool completed;
  final TaskPriority priority;
  final DateTime? createdAt;

  /// Converte o JSON da API para o modelo. Aceita o formato da documentação
  /// (`status`, `prioridade`, `criado_em`) e os formatos alternativos do
  /// código original (`concluida`, `id_tarefa`, `title`, ...).
  
  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['id_tarefa'];
    if (id == null) throw const FormatException('Tarefa sem identificador.');
    final created = (json['criado_em'] ?? json['created_at'] ?? '').toString();
    return Task(
      id: id.toString(),
      title: (json['titulo'] ?? json['title'] ?? json['nome'] ?? 'Sem título')
          .toString(),
      description: (json['descricao'] ?? json['description'] ?? '').toString(),
      priority: TaskPriority.parse(json['prioridade'] ?? json['priority']),
      completed: _parseCompleted(json),
      createdAt: DateTime.tryParse(created.replaceFirst(' ', 'T')),
    );
  }

  static bool _isTrue(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    return const {
      '1',
      'true',
      'concluida',
      'concluido',
      'completed',
      'done',
    }.contains(foldText(value.toString()));
  }

  static bool _parseCompleted(Map<String, dynamic> json) {
    if (json['status'] != null) return _isTrue(json['status']);
    return _isTrue(json['concluida'] ?? json['completed'] ?? json['concluído']);
  }

  /// Corpo enviado ao PHP. Segue a documentação (`prioridade` e `status`) e
  /// mantém `id` e `concluida` do código original por compatibilidade.
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': title,
    'descricao': description,
    'prioridade': priority.name,
    'status': completed ? 'concluida' : 'pendente',
    'concluida': completed,
  };
}

/// Dados digitados no formulário antes de serem enviados à API.
class TaskDraft {
  const TaskDraft(this.title, this.description, this.priority);
  final String title;
  final String description;
  final TaskPriority priority;
}

class TaskApiException implements Exception {
  const TaskApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Centraliza URLs, métodos HTTP, JSON e erros de comunicação.
class TaskApi {
  TaskApi({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      endpoint = endpoint ?? Uri.parse(apiUrl);

  final http.Client _client;
  final Uri endpoint;

  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  /// GET: busca a lista. Aceita `{"sucesso": true, "dados": [...]}` (formato da
  /// documentação), outros envelopes conhecidos ou uma lista direta.
  
  Future<List<Task>> getTasks() async {
    final response = await _send(_client.get(endpoint));
    final data = _handle(response, expectJson: true);
    final dynamic items = data is List
        ? data
        : data is Map
        ? data['dados'] ?? data['tarefas'] ?? data['data'] ?? data['tasks']
        : null;
    if (items is! List) {
      throw const TaskApiException('A API não retornou uma lista de tarefas.');
    }
    try {
      return items
          .map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      throw const TaskApiException(
        'Os dados de tarefas recebidos são inválidos.',
      );
    }
  }

  /// POST: envia uma nova tarefa em JSON.
  Future<void> createTask(TaskDraft draft) async {
    final response = await _send(
      _client.post(
        endpoint,
        headers: _headers,
        body: jsonEncode({
          'titulo': draft.title,
          'descricao': draft.description,
          'prioridade': draft.priority.name,
          'status': 'pendente',
          'concluida': false,
        }),
      ),
    );
    _handle(response);
  }

  /// PUT: envia todos os campos (os que não mudaram mantêm o valor atual).
  Future<void> updateTask(
    Task task, {
    String? title,
    String? description,
    TaskPriority? priority,
    bool? completed,
  }) async {
    final updated = Task(
      id: task.id,
      title: title ?? task.title,
      description: description ?? task.description,
      priority: priority ?? task.priority,
      completed: completed ?? task.completed,
    );
    final response = await _send(
      _client.put(
        _uriForTask(task.id),
        headers: _headers,
        body: jsonEncode(updated.toJson()),
      ),
    );
    _handle(response);
  }

  /// DELETE: o ID vai na query string (`?id=7`) e também no corpo, como no
  /// código original.
  Future<void> deleteTask(Task task) async {
    final response = await _send(
      _client.delete(
        _uriForTask(task.id),
        headers: _headers,
        body: jsonEncode({'id': task.id}),
      ),
    );
    _handle(response);
  }

  Uri _uriForTask(String id) => endpoint.replace(
    queryParameters: {...endpoint.queryParameters, 'id': id},
  );

  /// Aplica limite de tempo e traduz falhas de transporte em mensagens claras.
  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const TaskApiException(
        'A API demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      // No navegador, CORS bloqueado, HTTP em página HTTPS e servidor fora do
      // ar aparecem todos como "Failed to fetch".
      throw const TaskApiException(
        'Não foi possível conectar à API. Confira o endereço, a rede e se o '
        'servidor PHP permite acesso do navegador (CORS).',
      );
    }
  }

  /// Valida status HTTP e o campo `sucesso` da API; devolve o JSON decodificado.
  dynamic _handle(http.Response response, {bool expectJson = false}) {
    final success = response.statusCode >= 200 && response.statusCode < 300;
    // Decodifica como UTF-8 sempre, mesmo que o PHP não envie o charset.
    var text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (text.startsWith('\uFEFF')) text = text.substring(1).trim();

    dynamic data;
    var validJson = false;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
        validJson = true;
      } on FormatException {
        validJson = false;
      }
    }

    final refused =
        data is Map && (data['sucesso'] == false || data['success'] == false);
    if (!success || refused) {
      final raw = data is Map
          ? (data['mensagem'] ?? data['message'] ?? data['erro'] ?? data['error'])
          : null;
      var detail = (raw?.toString() ?? '').trim();
      if (detail.isEmpty) {
        detail = text.length > 180 ? text.substring(0, 180) : text;
      }
      if (!success) {
        throw TaskApiException(
          detail.isEmpty
              ? 'A API respondeu com HTTP ${response.statusCode}.'
              : 'Erro HTTP ${response.statusCode}: $detail',
        );
      }
      throw TaskApiException(detail.isEmpty ? 'A API recusou a operação.' : detail);
    }

    if (expectJson && !validJson) {
      throw const TaskApiException('A resposta da API não contém JSON válido.');
    }
    return data;
  }
}

// ===== theme/app_theme.dart =====
/// Paleta extraída de css/style.css e css/theme.css do site da NovaEra Code.
class AppColors {
  static const primary = Color(0xFF007BFF);
  static const primaryDark = Color(0xFF0056B3);
  static const slate = Color(0xFF6B7C8C);
  static const primarySoft = Color(0xFFEEF4FF);
  static const background = Color(0xFFF5F7FB);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFDECEA);
  static const warning = Color(0xFF9A5B00);
  static const warningSoft = Color(0xFFFEF3DC);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFE7F6EC);
  static const shadow = Color(0x0F0F172A);
  static const glow = Color(0x40007BFF);
}

const _headingFont = 'Montserrat';
const _bodyFont = 'Roboto';
const _fontFallback = [
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Arial',
  'sans-serif',
];

/// Títulos e destaques: Montserrat, como no site.
TextStyle headingStyle(
  double size, {
  Color color = AppColors.text,
  FontWeight weight = FontWeight.w800,
  double height = 1.2,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: _headingFont,
  fontFamilyFallback: _fontFallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// Texto de apoio: Roboto, como no site.
TextStyle bodyStyle(
  double size, {
  Color color = AppColors.muted,
  FontWeight weight = FontWeight.w400,
  double height = 1.55,
}) => TextStyle(
  fontFamily: _bodyFont,
  fontFamilyFallback: _fontFallback,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primaryDark,
    error: AppColors.danger,
    surface: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: _bodyFont,
    fontFamilyFallback: _fontFallback,
  );

  const shape = StadiumBorder();
  const labelStyle = TextStyle(
    fontFamily: _headingFont,
    fontFamilyFallback: _fontFallback,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  const padding = EdgeInsets.symmetric(horizontal: 24);

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: padding,
            shape: shape,
            textStyle: labelStyle,
            foregroundColor: Colors.white,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFFB6D4F5);
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)) {
                return AppColors.primaryDark;
              }
              return AppColors.primary;
            }),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: padding,
            shape: shape,
            foregroundColor: AppColors.primaryDark,
            backgroundColor: Colors.white,
            textStyle: labelStyle,
          ).copyWith(
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return const BorderSide(color: AppColors.primary, width: 1.4);
              }
              return const BorderSide(color: AppColors.border);
            }),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: padding,
        shape: shape,
        foregroundColor: AppColors.primaryDark,
        textStyle: labelStyle,
      ),
    ),
  );
}

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

/// Estilo único dos campos de texto.
InputDecoration appInputDecoration({
  required String label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: Colors.white,
  labelStyle: bodyStyle(15),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: _border(AppColors.border),
  enabledBorder: _border(AppColors.border),
  focusedBorder: _border(AppColors.primary, 2),
  errorBorder: _border(AppColors.danger),
  focusedErrorBorder: _border(AppColors.danger, 2),
);

// ===== widgets/common.dart =====
/// Centraliza o conteúdo com largura máxima e margens responsivas.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
          child: child,
        ),
      ),
    );
  }
}

/// Entrada suave (fade + deslocamento). Respeita "reduzir movimento".
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final total = 500 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Informa se o ponteiro está sobre o componente (hover no desktop).
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hovering) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovering = true),
    onExit: (_) => setState(() => _hovering = false),
    child: widget.builder(context, _hovering),
  );
}

// ===== widgets/nova_logo.dart =====
/// Logotipo da NovaEra Code (monograma "N" + "E" com circuitos e </>),
/// reproduzido em vetor a partir de img/logonova.png do site.
class NovaLogo extends StatelessWidget {
  const NovaLogo({
    super.key,
    this.size = 44,
    this.showName = true,
    this.subtitle,
  });

  final double size;
  final bool showName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NovaEra Code',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _LogoPainter()),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NovaEra Code',
                  style: headingStyle(
                    size * 0.46,
                    color: AppColors.primary,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: bodyStyle(
                      11.5,
                      color: AppColors.slate,
                      weight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  // Coordenadas na área útil da imagem original do logotipo (x 560–1410,
  // y 385–1215).
  static const double _w = 850;
  static const double _h = 830;

  Path _poly(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _w, size.height / _h);
    canvas.translate(
      (size.width - _w * scale) / 2,
      (size.height - _h * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-560, -385);

    final black = Paint()..color = const Color(0xFF111111);
    canvas.drawPath(
      _poly(const [
        Offset(565, 560),
        Offset(850, 752),
        Offset(998, 645),
        Offset(998, 702),
        Offset(885, 790),
        Offset(885, 897),
        Offset(652, 735),
        Offset(652, 1075),
        Offset(565, 1075),
      ]),
      black,
    );
    canvas.drawPath(
      _poly(const [
        Offset(740, 865),
        Offset(968, 1035),
        Offset(895, 1090),
        Offset(740, 975),
      ]),
      black,
    );

    final blue = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A93FF), Color(0xFF0062F5)],
      ).createShader(const Rect.fromLTWH(1030, 590, 380, 490));
    canvas.drawPath(
      _poly(const [
        Offset(1095, 597),
        Offset(1405, 597),
        Offset(1350, 683),
        Offset(1130, 683),
        Offset(1130, 790),
        Offset(1040, 722),
        Offset(1040, 655),
        Offset(1095, 655),
      ]),
      blue,
    );
    canvas.drawPath(
      _poly(const [
        Offset(1130, 787),
        Offset(1355, 787),
        Offset(1300, 870),
        Offset(1130, 870),
      ]),
      blue,
    );
    canvas.drawPath(
      _poly(const [
        Offset(1130, 915),
        Offset(1130, 990),
        Offset(1397, 990),
        Offset(1342, 1075),
        Offset(1035, 1075),
        Offset(1035, 985),
      ]),
      blue,
    );

    final line = Paint()
      ..color = const Color(0xFF0A7CF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void trace(Offset node, List<Offset> route) {
      final path = Path()..moveTo(route.first.dx, route.first.dy);
      for (final p in route.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
      canvas.drawCircle(node, 20, line);
    }

    trace(const Offset(1152, 415), const [
      Offset(1135, 438),
      Offset(1105, 472),
      Offset(990, 555),
      Offset(990, 640),
    ]);
    trace(const Offset(1225, 502), const [
      Offset(1205, 502),
      Offset(1140, 502),
      Offset(1042, 580),
      Offset(1042, 632),
    ]);
    trace(const Offset(817, 1155), const [
      Offset(837, 1155),
      Offset(885, 1155),
      Offset(975, 1080),
    ]);
    trace(const Offset(937, 1195), const [
      Offset(950, 1178),
      Offset(1005, 1120),
      Offset(1005, 1030),
    ]);

    final code = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(
      Path()
        ..moveTo(948, 822)
        ..lineTo(918, 858)
        ..lineTo(948, 892),
      code,
    );
    canvas.drawPath(
      Path()
        ..moveTo(1050, 822)
        ..lineTo(1082, 858)
        ..lineTo(1050, 892),
      code,
    );
    canvas.drawLine(const Offset(1003, 800), const Offset(978, 912), code);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===== pages/landing_page.dart =====
void openPanel(BuildContext context) =>
    Navigator.of(context).pushNamed('/painel');

void goHome(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed('/');
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  final _aboutKey = GlobalKey();
  final _featuresKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  Future<void> _goTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _top() {
    if (!_scroll.hasClients) return;
    if (_reduceMotion) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _LandingHeader(
              onHome: _top,
              onAbout: () => _goTo(_aboutKey),
              onFeatures: () => _goTo(_featuresKey),
              onOpen: () => openPanel(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  children: [
                    _Hero(
                      onStart: () => openPanel(context),
                      onFeatures: () => _goTo(_featuresKey),
                    ),
                    _AboutSection(key: _aboutKey),
                    _FeaturesSection(key: _featuresKey),
                    _CtaSection(onStart: () => openPanel(context)),
                    _Footer(
                      onHome: _top,
                      onFeatures: () => _goTo(_featuresKey),
                      onOpen: () => openPanel(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({
    required this.onHome,
    required this.onAbout,
    required this.onFeatures,
    required this.onOpen,
  });

  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onFeatures;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 860;

    Widget link(String label, VoidCallback onTap) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(0, 44),
      ),
      child: Text(label),
    );

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ContentWidth(
        child: Row(
          children: [
            InkWell(
              onTap: onHome,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: NovaLogo(size: 44, showName: width >= 480),
              ),
            ),
            Expanded(
              child: wide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        link('Início', onHome),
                        const SizedBox(width: 8),
                        link('Sobre', onAbout),
                        const SizedBox(width: 8),
                        link('Recursos', onFeatures),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(width < 420 ? 'Acessar' : 'Acessar organizador'),
            ),
            if (!wide)
              PopupMenuButton<String>(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'home':
                      onHome();
                    case 'about':
                      onAbout();
                    case 'features':
                      onFeatures();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'home', child: Text('Início')),
                  PopupMenuItem(value: 'about', child: Text('Sobre')),
                  PopupMenuItem(value: 'features', child: Text('Recursos')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x33007BFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: headingStyle(
            12.5,
            color: AppColors.primaryDark,
            weight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onStart, required this.onFeatures});

  final VoidCallback onStart;
  final VoidCallback onFeatures;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;
    final titleSize = width >= 1100 ? 52.0 : (width >= 640 ? 42.0 : 32.0);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Reveal(child: _Tag('Uma solução NovaEra')),
        const SizedBox(height: 22),
        Reveal(
          delay: 80,
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                style: headingStyle(titleSize, height: 1.12),
                children: const [
                  TextSpan(text: 'Organize suas tarefas.\n'),
                  TextSpan(
                    text: 'Transforme sua rotina.',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Reveal(
          delay: 160,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'Uma ferramenta da NovaEra Code para você acompanhar suas '
              'atividades, manter o foco nas prioridades e visualizar seu '
              'progresso em um só lugar.',
              style: bodyStyle(width < 640 ? 16 : 18, height: 1.65),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Reveal(
          delay: 240,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.arrow_forward_rounded),
                iconAlignment: IconAlignment.end,
                label: const Text('Começar agora'),
              ),
              OutlinedButton(
                onPressed: onFeatures,
                child: const Text('Conhecer recursos'),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF4FF), Color(0xFFF7FBFF)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _GeoPainter())),
          Padding(
            padding: EdgeInsets.symmetric(vertical: wide ? 88 : 48),
            child: ContentWidth(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 11, child: text),
                        const SizedBox(width: 56),
                        const Expanded(
                          flex: 10,
                          child: Reveal(delay: 200, child: _HeroPreview()),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        text,
                        const SizedBox(height: 40),
                        const Reveal(delay: 200, child: _HeroPreview()),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formas geométricas sutis do fundo do hero.
class _GeoPainter extends CustomPainter {
  const _GeoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x1A007BFF);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), 200, ring);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.12), 270, ring);
    canvas.drawCircle(Offset(size.width * 0.02, size.height * 0.95), 160, ring);

    final dot = Paint()..color = const Color(0x2A007BFF);
    for (var i = 0; i < 8; i++) {
      for (var j = 0; j < 5; j++) {
        canvas.drawCircle(
          Offset(size.width * 0.03 + i * 18, size.height * 0.08 + j * 18),
          1.6,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Barra cinza que representa texto (apenas ilustrativa).
class _Skel extends StatelessWidget {
  const _Skel(this.factor, {this.height = 8, this.color = AppColors.border});

  final double factor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: factor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );
}

/// Prévia ilustrativa do painel. Não usa dados reais nem textos de tarefas.
class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  Widget _statBlock(Color accent) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Skel(0.55, height: 6, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          _Skel(0.8, height: 14, color: accent),
        ],
      ),
    ),
  );

  Widget _row({required bool done}) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: done ? AppColors.surfaceMuted : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? AppColors.primary : AppColors.slate,
          size: 22,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Skel(0.6, height: 9, color: Color(0xFFCBD5E1)),
              SizedBox(height: 8),
              _Skel(0.9, height: 6),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            children: [
              Positioned(
                left: 18,
                top: 18,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x14007BFF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x26007BFF)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 18, bottom: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24007BFF),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (final c in const [
                            Color(0xFFCBD5E1),
                            Color(0xFFCBD5E1),
                            Color(0xFFCBD5E1),
                          ])
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Prévia ilustrativa',
                              style: headingStyle(
                                10.5,
                                color: AppColors.primaryDark,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _statBlock(const Color(0xFF99C9FF)),
                          const SizedBox(width: 10),
                          _statBlock(const Color(0xFFCBD5E1)),
                          const SizedBox(width: 10),
                          _statBlock(AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.6,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(done: true),
                      _row(done: false),
                      _row(done: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Prévia ilustrativa da interface. Não exibe dados reais.',
          textAlign: TextAlign.center,
          style: bodyStyle(12.5, color: AppColors.slate),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.overline,
    required this.title,
    this.subtitle,
  });

  final String overline;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline.toUpperCase(),
          style: headingStyle(
            12.5,
            color: AppColors.primary,
            weight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(title, style: headingStyle(compact ? 26 : 34, height: 1.18)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(subtitle!, style: bodyStyle(16.5, height: 1.65)),
          ),
        ],
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});

  Widget _point(IconData icon, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: headingStyle(16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(text, style: bodyStyle(15.5)),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          overline: 'Sobre a NovaEra Code',
          title: 'Tecnologia aplicada à organização do dia a dia.',
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'A NovaEra Code é uma empresa focada no desenvolvimento de '
            'soluções digitais modernas, eficientes e pensadas para as '
            'necessidades reais de cada projeto. O organizador de tarefas '
            'segue essa ideia: tecnologia com propósito, que simplifica '
            'processos e torna a rotina mais clara.',
            style: bodyStyle(16.5, height: 1.7),
          ),
        ),
      ],
    );

    final points = Column(
      children: [
        _point(
          Icons.memory_rounded,
          'Nossa proposta',
          'Transformar ideias em soluções digitais que fazem a diferença.',
        ),
        _point(
          Icons.task_alt_rounded,
          'O organizador',
          'Uma ferramenta para registrar, acompanhar e concluir atividades '
              'com clareza.',
        ),
        _point(
          Icons.trending_up_rounded,
          'Para você',
          'Mais visibilidade sobre o que falta fazer e sobre o quanto já '
              'foi concluído.',
        ),
      ],
    );

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: wide ? 96 : 56),
      child: ContentWidth(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: intro),
                  const SizedBox(width: 72),
                  Expanded(child: points),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [intro, const SizedBox(height: 32), points],
              ),
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key});

  static const _features = [
    _Feature(
      Icons.checklist_rounded,
      'Organização de tarefas',
      'Registre atividades com título, descrição e prioridade e mantenha '
          'tudo em um só lugar.',
    ),
    _Feature(
      Icons.rule_rounded,
      'Pendentes e concluídas',
      'Marque tarefas como concluídas ou reabra quando precisar. O estado '
          'fica salvo no servidor.',
    ),
    _Feature(
      Icons.edit_note_rounded,
      'Cadastro e edição',
      'Crie e ajuste tarefas em formulários com validação e mensagens '
          'claras.',
    ),
    _Feature(
      Icons.manage_search_rounded,
      'Busca e filtros',
      'Encontre atividades pelo título ou descrição e filtre por todas, '
          'pendentes ou concluídas.',
    ),
    _Feature(
      Icons.insights_rounded,
      'Acompanhamento do progresso',
      'Veja total, pendentes, concluídas e o percentual de conclusão '
          'calculados com os seus dados.',
    ),
    _Feature(
      Icons.dashboard_customize_rounded,
      'Gerenciamento centralizado',
      'Visualize, pesquise e gerencie tudo em uma única interface, no '
          'computador ou no celular.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(vertical: screen >= 900 ? 96 : 56),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              overline: 'Recursos',
              title: 'Tudo o que você precisa para organizar sua rotina.',
              subtitle:
                  'Funcionalidades pensadas para deixar o acompanhamento das '
                  'tarefas simples e visual.',
            ),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 20.0;
                final w = constraints.maxWidth;
                final columns = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
                final itemWidth = (w - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final feature in _features)
                      SizedBox(
                        width: itemWidth,
                        child: _FeatureCard(feature: feature),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hover ? const Color(0x66007BFF) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: hover ? const Color(0x1F007BFF) : AppColors.shadow,
              blurRadius: hover ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hover ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                feature.icon,
                color: hover ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              feature.title,
              style: headingStyle(17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(feature.description, style: bodyStyle(15)),
          ],
        ),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: compact ? 48 : 80),
      child: ContentWidth(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 56,
            vertical: compact ? 36 : 56,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: AppColors.glow,
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Pronto para organizar suas atividades?',
                  textAlign: TextAlign.center,
                  style: headingStyle(
                    compact ? 24 : 32,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Acesse o painel e acompanhe suas tarefas de forma simples, '
                  'visual e organizada.',
                  textAlign: TextAlign.center,
                  style: bodyStyle(
                    16.5,
                    color: const Color(0xE6FFFFFF),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                iconAlignment: IconAlignment.end,
                label: const Text('Começar agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onHome,
    required this.onFeatures,
    required this.onOpen,
  });

  final VoidCallback onHome;
  final VoidCallback onFeatures;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;

    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NovaLogo(size: 40, subtitle: 'Organizador de Tarefas'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            'Uma solução NovaEra Code para organizar, acompanhar e gerenciar '
            'tarefas. Tecnologia com propósito. Resultados de verdade.',
            style: bodyStyle(14),
          ),
        ),
      ],
    );

    final links = Wrap(
      spacing: 4,
      children: [
        TextButton(onPressed: onHome, child: const Text('Início')),
        TextButton(onPressed: onFeatures, child: const Text('Recursos')),
        TextButton(onPressed: onOpen, child: const Text('Acessar organizador')),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: about), links],
              )
            else ...[about, const SizedBox(height: 16), links],
            const SizedBox(height: 24),
            Text(
              '© ${DateTime.now().year} NovaEra Code. Todos os direitos '
              'reservados.',
              style: bodyStyle(13, color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== widgets/panel_header.dart =====
/// Cabeçalho compacto do painel: marca, volta à apresentação, atualizar e
/// criar tarefa.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.loading,
    required this.onHome,
    required this.onRefresh,
    required this.onCreate,
  });

  final bool loading;
  final VoidCallback onHome;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;

    final refreshIcon = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.refresh_rounded);

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ContentWidth(
        child: compact
            ? Row(
                children: [
                  InkWell(
                    onTap: onHome,
                    borderRadius: BorderRadius.circular(12),
                    child: const NovaLogo(size: 40, showName: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Organizador',
                        overflow: TextOverflow.ellipsis,
                        style: headingStyle(
                          16,
                          color: AppColors.primary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Voltar à apresentação',
                    onPressed: onHome,
                    icon: const Icon(Icons.home_outlined),
                  ),
                  IconButton(
                    tooltip: 'Atualizar tarefas',
                    onPressed: loading ? null : onRefresh,
                    icon: refreshIcon,
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova'),
                  ),
                ],
              )
            : Row(
                children: [
                  InkWell(
                    onTap: onHome,
                    borderRadius: BorderRadius.circular(12),
                    child: const NovaLogo(size: 44),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Organizador de Tarefas',
                        overflow: TextOverflow.ellipsis,
                        style: headingStyle(
                          16,
                          weight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onHome,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: AppColors.muted,
                    ),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Início'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: loading ? null : onRefresh,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: refreshIcon,
                    label: const Text('Atualizar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova tarefa'),
                  ),
                ],
              ),
      ),
    );
  }
}

// ===== widgets/summary_cards.dart =====
/// Indicadores calculados a partir das tarefas reais retornadas pela API.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final pending = total - completed;
    // Evita divisão por zero quando não há tarefas.
    final ratio = total == 0 ? 0.0 : completed / total;
    final percent = (ratio * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        Widget item(Widget child) => SizedBox(width: width, child: child);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            item(
              _StatCard(
                label: 'Total de tarefas',
                value: '$total',
                leading: const _IconBadge(
                  icon: Icons.list_alt_rounded,
                  color: AppColors.primary,
                  background: AppColors.primarySoft,
                ),
              ),
            ),
            item(
              _StatCard(
                label: 'Pendentes',
                value: '$pending',
                leading: const _IconBadge(
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                ),
              ),
            ),
            item(
              _StatCard(
                label: 'Concluídas',
                value: '$completed',
                leading: const _IconBadge(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  background: AppColors.successSoft,
                ),
              ),
            ),
            item(
              _StatCard(
                label: 'Conclusão',
                value: '$percent%',
                leading: SizedBox(
                  width: 44,
                  height: 44,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio),
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      backgroundColor: AppColors.primarySoft,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.leading,
  });

  final String label;
  final String value;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: headingStyle(24, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== widgets/task_toolbar.dart =====
enum TaskFilter { all, pending, done }

/// Campo de pesquisa e filtros (aplicados localmente aos dados da API).
class TaskToolbar extends StatelessWidget {
  const TaskToolbar({
    super.key,
    required this.searchController,
    required this.onQueryChanged,
    required this.filter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.pendingCount,
    required this.doneCount,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final TaskFilter filter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final int totalCount;
  final int pendingCount;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onQueryChanged,
      textInputAction: TextInputAction.search,
      decoration: appInputDecoration(
        label: 'Pesquisar tarefas',
        hint: 'Título ou descrição',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar pesquisa',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();
                  onQueryChanged('');
                },
              ),
      ),
    );

    Widget chip(TaskFilter value, String label, int count) {
      final selected = filter == value;
      return ChoiceChip(
        label: Text('$label · $count'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onFilterChanged(value),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        labelStyle: headingStyle(
          13,
          weight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.muted,
          height: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
    }

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(TaskFilter.all, 'Todas', totalCount),
        chip(TaskFilter.pending, 'Pendentes', pendingCount),
        chip(TaskFilter.done, 'Concluídas', doneCount),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              SizedBox(width: 360, child: search),
              const SizedBox(width: 16),
              Expanded(child: chips),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 12), chips],
        );
      },
    );
  }
}

// ===== widgets/task_card.dart =====
String _two(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

/// Item da lista: conclusão, título, descrição, selos e ações.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.completed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        final actions = compact
            ? PopupMenuButton<String>(
                tooltip: 'Ações da tarefa',
                onSelected: (action) =>
                    action == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                      title: Text('Excluir'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar tarefa',
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Excluir tarefa',
                    onPressed: busy ? null : onDelete,
                    color: AppColors.danger,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              );

        return HoverBuilder(
          builder: (context, hover) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(6, 8, compact ? 2 : 6, 8),
            decoration: BoxDecoration(
              color: done ? AppColors.surfaceMuted : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hover ? const Color(0x66007BFF) : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: hover ? const Color(0x1F007BFF) : AppColors.shadow,
                  blurRadius: hover ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: done
                              ? 'Reabrir tarefa'
                              : 'Marcar como concluída',
                          onPressed: onToggle,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              done
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(done),
                              color: done ? AppColors.success : AppColors.slate,
                              size: 26,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: headingStyle(
                            15,
                            weight: FontWeight.w700,
                            color: done ? AppColors.muted : AppColors.text,
                            height: 1.3,
                          ).copyWith(
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle(14),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _PriorityPill(priority: task.priority),
                            _StatusPill(done: done),
                            if (task.createdAt != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppColors.slate,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(task.createdAt!),
                                    style: bodyStyle(
                                      12,
                                      color: AppColors.slate,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (priority) {
      TaskPriority.alta => (AppColors.danger, AppColors.dangerSoft),
      TaskPriority.media => (AppColors.warning, AppColors.warningSoft),
      TaskPriority.baixa => (AppColors.primaryDark, AppColors.primarySoft),
    };
    return _Pill(
      label: 'Prioridade ${priority.label.toLowerCase()}',
      color: fg,
      background: bg,
      icon: Icons.flag_rounded,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => _Pill(
    label: done ? 'Concluída' : 'Pendente',
    color: done ? AppColors.success : AppColors.muted,
    background: done ? AppColors.successSoft : const Color(0xFFEEF1F5),
  );
}

// ===== widgets/state_views.dart =====
/// Mensagem centralizada para lista vazia, sem resultados e erro de conexão.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySoft,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;
  final Color iconBackground;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: headingStyle(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: bodyStyle(14.5),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: actions),
          ],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// Aviso exibido quando uma atualização falha, mantendo as tarefas na tela.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
    decoration: BoxDecoration(
      color: AppColors.dangerSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF3C2BD)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

// ===== widgets/task_form_dialog.dart =====
/// Formulário de cadastro/edição. Chama [onSubmit] (a requisição à API) e só
/// fecha quando ela termina com sucesso; em caso de erro, mostra a mensagem e
/// mantém o que foi digitado.
class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({super.key, this.task, required this.onSubmit});

  final Task? task;
  final Future<void> Function(TaskDraft draft) onSubmit;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // Ao editar, inicia os campos com os valores atuais; ao criar, ficam vazios.
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _priority = widget.task?.priority ?? TaskPriority.media;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await widget.onSubmit(
        TaskDraft(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _priority,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = error is TaskApiException
            ? error.message
            : 'Erro inesperado ao comunicar com a API.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      scrollable: true,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              editing ? Icons.edit_note_rounded : Icons.add_task_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              editing ? 'Editar tarefa' : 'Nova tarefa',
              style: headingStyle(20),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(label: 'Título *'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe o título da tarefa.';
                  if (text.length > 120) {
                    return 'Use no máximo 120 caracteres no título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: appInputDecoration(
                  label: 'Descrição (opcional)',
                ).copyWith(alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              Text(
                'Prioridade',
                style: headingStyle(
                  13,
                  color: AppColors.muted,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskPriority>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primarySoft,
                    selectedForegroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  segments: [
                    for (final priority in TaskPriority.values)
                      ButtonSegment<TaskPriority>(
                        value: priority,
                        label: Text(priority.label),
                      ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) =>
                            setState(() => _priority = selection.first),
                ),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}

// ===== pages/tasks_page.dart =====
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.api});
  final TaskApi api;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();

  // Dados e estados usados para desenhar carregamento, erro e lista.
  List<Task> _tasks = const [];
  bool _loading = true;
  String? _error;
  TaskFilter _filter = TaskFilter.all;
  String _query = '';
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    // Busca os dados assim que a tela aparece.
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _messageFor(Object error) => error is TaskApiException
      ? error.message
      : 'Erro inesperado ao comunicar com a API.';

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: width > 560 ? 480 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: error ? AppColors.danger : AppColors.primaryDark,
          duration: Duration(seconds: error ? 5 : 3),
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  // GET: se falhar, as tarefas já exibidas são mantidas e o erro aparece num aviso.
  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await widget.api.getTasks();
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // POST (sem tarefa) ou PUT (com tarefa). O diálogo executa a requisição e
  // só fecha com sucesso.
  Future<void> _openForm([Task? task]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskFormDialog(
        task: task,
        onSubmit: (draft) => task == null
            ? widget.api.createTask(draft)
            : widget.api.updateTask(
                task,
                title: draft.title,
                description: draft.description,
                priority: draft.priority,
              ),
      ),
    );
    if (saved != true || !mounted) return;
    _toast(task == null ? 'Tarefa cadastrada.' : 'Tarefa alterada.');
    await _loadTasks();
  }

  // PUT alterando apenas o status.
  Future<void> _toggleCompleted(Task task) async {
    if (_busyIds.contains(task.id)) return;
    final done = !task.completed;
    setState(() => _busyIds.add(task.id));
    try {
      await widget.api.updateTask(task, completed: done);
      _toast(done ? 'Tarefa concluída.' : 'Tarefa reaberta.');
      await _loadTasks();
    } catch (error) {
      _toast(_messageFor(error), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(task.id));
    }
  }

  // Pede confirmação antes de executar uma operação irreversível.
  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 32,
        ),
        title: Text('Excluir tarefa?', style: headingStyle(20)),
        content: Text(
          '“${task.title}” será removida permanentemente.',
          style: bodyStyle(15, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyIds.add(task.id));
    try {
      await widget.api.deleteTask(task);
      _toast('Tarefa excluída.');
      await _loadTasks();
    } catch (error) {
      // Falhou: nada muda na lista exibida.
      _toast(_messageFor(error), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(task.id));
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = TaskFilter.all;
    });
  }

  // Filtro e pesquisa locais, sem acento e sem diferenciar maiúsculas.
  List<Task> get _visibleTasks {
    final query = foldText(_query);
    return _tasks.where((task) {
      if (_filter == TaskFilter.pending && task.completed) return false;
      if (_filter == TaskFilter.done && !task.completed) return false;
      if (query.isEmpty) return true;
      return foldText(task.title).contains(query) ||
          foldText(task.description).contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final completed = _tasks.where((task) => task.completed).length;
    final hasData = _tasks.isNotEmpty || (!_loading && _error == null);
    final visible = _visibleTasks;
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PanelHeader(
              loading: _loading,
              onHome: () => goHome(context),
              onRefresh: _loadTasks,
              onCreate: () => _openForm(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTasks,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ContentWidth(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: compact ? 20 : 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Reveal(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vamos organizar suas atividades?',
                                  style: headingStyle(compact ? 22 : 30),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Acompanhe o que precisa ser feito, '
                                  'registre novas tarefas e visualize o seu '
                                  'progresso em um só lugar.',
                                  style: bodyStyle(compact ? 14.5 : 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (hasData) ...[
                            Reveal(
                              delay: 80,
                              child: SummaryCards(
                                total: total,
                                completed: completed,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (_tasks.isNotEmpty) ...[
                            TaskToolbar(
                              searchController: _searchController,
                              onQueryChanged: (value) =>
                                  setState(() => _query = value),
                              filter: _filter,
                              onFilterChanged: (value) =>
                                  setState(() => _filter = value),
                              totalCount: total,
                              pendingCount: total - completed,
                              doneCount: completed,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 12,
                              ),
                              child: Text(
                                visible.length == 1
                                    ? 'Exibindo 1 de $total tarefas'
                                    : 'Exibindo ${visible.length} de $total '
                                          'tarefas',
                                style: bodyStyle(13.5, color: AppColors.slate),
                              ),
                            ),
                          ],
                          if (_loading && _tasks.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                                child: LinearProgressIndicator(minHeight: 4),
                              ),
                            ),
                          if (_error != null && _tasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ErrorBanner(
                                message: _error!,
                                onRetry: _loadTasks,
                              ),
                            ),
                          _buildContent(visible),
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

  // Escolhe a interface conforme o estado atual da requisição e da lista.
  Widget _buildContent(List<Task> visible) {
    if (_loading && _tasks.isEmpty) return const LoadingView();

    if (_error != null && _tasks.isEmpty) {
      return StateMessage(
        icon: Icons.cloud_off_outlined,
        iconColor: AppColors.danger,
        iconBackground: AppColors.dangerSoft,
        title: 'Não foi possível carregar as tarefas',
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_tasks.isEmpty) {
      return StateMessage(
        icon: Icons.checklist_rounded,
        title: 'Nenhuma tarefa por aqui',
        message:
            'Cadastre sua primeira tarefa para começar a acompanhar o progresso.',
        actions: [
          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar primeira tarefa'),
          ),
        ],
      );
    }

    if (visible.isEmpty) {
      return StateMessage(
        icon: Icons.search_off_rounded,
        title: 'Nenhuma tarefa encontrada',
        message: 'Ajuste a pesquisa ou o filtro para ver outras tarefas.',
        actions: [
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar filtros'),
          ),
        ],
      );
    }

    // Em telas largas a lista usa duas colunas para mostrar mais tarefas.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 980 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final task in visible)
              SizedBox(
                width: itemWidth,
                child: TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  busy: _busyIds.contains(task.id),
                  onToggle: () => _toggleCompleted(task),
                  onEdit: () => _openForm(task),
                  onDelete: () => _confirmDelete(task),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ===== main.dart =====
// Ponto de entrada: cria a raiz da interface Flutter Web.
void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.api});

  // Permite injetar uma API simulada nos testes.
  final TaskApi? api;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TaskApi _api = widget.api ?? TaskApi();

  /// Rotas nomeadas: '/' (apresentação) e '/painel' (organizador). Funcionam
  /// com URL direta, botões voltar/avançar e atualização do navegador.
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final isPanel = settings.name == '/painel';
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: isPanel ? '/painel' : '/'),
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          isPanel ? TasksPage(api: _api) : const LandingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Organizador de Tarefas | NovaEra Code',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    initialRoute: '/',
    onGenerateRoute: _onGenerateRoute,
  );
}