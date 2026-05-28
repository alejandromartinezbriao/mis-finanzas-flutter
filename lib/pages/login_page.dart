import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometrics();
  }

  // Cargar email y preferencia de recordatorio
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  // Verificar si el dispositivo soporta biometría
  Future<void> _checkBiometrics() async {
    if (kIsWeb) return; // La biometría no está soportada en Web vía este plugin
    try {
      bool canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      setState(() => _canCheckBiometrics = canCheck);
    } catch (e) {
      print("Error checkBiometrics: $e");
    }
  }

  // Lógica de Autenticación Biométrica
  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión de forma segura',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final savedEmail = _emailController.text;
        final savedPassword = await _secureStorage.read(key: 'password');

        if (savedEmail.isNotEmpty && savedPassword != null) {
          await _auth.signIn(savedEmail, savedPassword);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay credenciales guardadas para biometría.')),
          );
        }
      }
    } catch (e) {
      print("Error biometría: $e");
    }
  }

  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    try {
      if (_isLogin) {
        await _auth.signIn(_emailController.text, _passwordController.text);
        
        // Guardar credenciales si "Recordarme" está activo
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('saved_email', _emailController.text);
          await _secureStorage.write(key: 'password', value: _passwordController.text);
        } else {
          await prefs.setBool('remember_me', false);
          await _secureStorage.delete(key: 'password');
        }
      } else {
        await _auth.signUp(_emailController.text, _passwordController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Te enviaremos un correo electrónico con un enlace para restablecer tu contraseña.'),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Email de recuperación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await _auth.resetPassword(resetEmailController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email enviado. Revisa tu bandeja de entrada (y la de correo no deseado/spam).'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Enviar Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icono.png', width: 150, height: 150),
              const SizedBox(height: 10),
              Text(
                'Mis Finanzas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Text('Recordarme', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  if (_isLogin && _canCheckBiometrics)
                    IconButton(
                      icon: Icon(Icons.fingerprint, size: 36, color: Theme.of(context).colorScheme.primary),
                      onPressed: _authenticateWithBiometrics,
                      tooltip: 'Ingresar con biometría',
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child: Text(_isLogin ? 'INICIAR SESIÓN' : 'CREAR CUENTA', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
