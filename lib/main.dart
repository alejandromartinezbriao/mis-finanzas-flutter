import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Añadido para verificar entorno Web
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/setup_page.dart';
import 'pages/budgets_page.dart';
import 'pages/goals_page.dart';
import 'pages/statistics_page.dart';
import 'pages/about_page.dart';
import 'pages/user_manual_page.dart';
import 'pages/maintenance_page.dart';
import 'pages/ai_history_page.dart';
import 'pages/ai_advisor_selector_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // MODIFICACIÓN DE SEGURIDAD: Solo habilitamos persistencia offline si NO es entorno Web
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      // Configuración ligera y segura para el caché de Firestore en Navegadores Web
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error inicializando Firebase: $e')),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final QuickActions quickActions = const QuickActions();
  String? shortcutType;

  @override
  void initState() {
    super.initState();
    // 1. Detección Nativa (Android/iOS)
    if (!kIsWeb) {
      _setupQuickActions();
    } else {
      // 2. Detección Web (PWA para iPhone/Safari)
      _setupWebQuickActions();
    }
  }

  void _setupWebQuickActions() {
    // Escuchamos los parámetros de la URL al inicio
    final Uri uri = Uri.base;
    if (uri.queryParameters.containsKey('action')) {
      setState(() {
        shortcutType = uri.queryParameters['action'];
      });
    }
  }

  void _setupQuickActions() {
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_new_movement_v5',
        localizedTitle: 'Ingreso / Gasto',
        icon: 'shortcut_simple',
      ),
      const ShortcutItem(
        type: 'action_new_card_v5',
        localizedTitle: 'Gasto con Tarjeta',
        icon: 'shortcut_card',
      ),
    ]);

    quickActions.initialize((type) {
      setState(() {
        shortcutType = type;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mis Finanzas',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routes: {
        '/home': (context) => const HomePage(),
        '/setup': (context) => const SetupPage(),
        '/budgets': (context) => const BudgetsPage(),
        '/goals': (context) => const GoalsPage(),
        '/statistics': (context) => const StatisticsPage(),
        '/about': (context) => const AboutPage(),
        '/manual': (context) => const UserManualPage(),
        '/maintenance': (context) => const MaintenancePage(),
        '/ai_history': (context) => const AiHistoryPage(),
        '/ai_advisor': (context) => const AiAdvisorSelectorPage(),
        '/login': (context) => const LoginPage(),
      },
      home: StreamBuilder<User?>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Error de Autenticación: ${snapshot.error}')));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            final String? currentAction = shortcutType;
            if (currentAction != null) shortcutType = null;
            return HomePage(initialAction: currentAction);
          }

          return const LoginPage();
        },
      ),
    );
  }
}
