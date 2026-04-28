import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/setup_page.dart';
import 'pages/budgets_page.dart';
import 'pages/goals_page.dart';
import 'pages/statistics_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Habilitar persistencia offline explícitamente
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
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
    _setupQuickActions();
  }

  void _setupQuickActions() {
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_new_expense',
        localizedTitle: 'Nuevo Gasto',
        icon: 'ic_launcher',
      ),
      const ShortcutItem(
        type: 'action_new_card',
        localizedTitle: 'Compra con Tarjeta',
        icon: 'ic_launcher',
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
      title: 'Cuentas Personales',
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
        '/login': (context) => const LoginPage(),
      },
      home: StreamBuilder<User?>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          // Si hay error en el stream de auth
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Error de Autenticación: ${snapshot.error}')));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData) {
            final String? currentAction = shortcutType;
            // Consumimos el tipo de shortcut para que no se vuelva a abrir al reconstruir
            if (currentAction != null) shortcutType = null;
            return HomePage(initialAction: currentAction);
          }

          return const LoginPage();
        },
      ),
    );
  }
}
