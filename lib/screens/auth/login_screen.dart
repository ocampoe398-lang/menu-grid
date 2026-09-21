import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../crm/menu_grid_screen.dart';
import 'recuperar_password_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _cargando = false;
  bool _verContrasena = false;

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ref.read(authServiceProvider).login(
            email: _emailController.text,
            contrasena: _contrasenaController.text,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MenuGridScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.mensajeDeError(e.code)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // En web: max 400px centrado. En móvil: ancho completo.
              constraints: BoxConstraints(
                maxWidth: esWeb ? 400 : double.infinity,
              ),
              child: _ContenidoLogin(
                formKey: _formKey,
                emailController: _emailController,
                contrasenaController: _contrasenaController,
                cargando: _cargando,
                verContrasena: _verContrasena,
                onToggleContrasena: () =>
                    setState(() => _verContrasena = !_verContrasena),
                onLogin: _iniciarSesion,
                onIrRegistro: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                ),
                onIrRecuperar: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const RecuperarPasswordScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoLogin extends StatelessWidget {
  const _ContenidoLogin({
    required this.formKey,
    required this.emailController,
    required this.contrasenaController,
    required this.cargando,
    required this.verContrasena,
    required this.onToggleContrasena,
    required this.onLogin,
    required this.onIrRegistro,
    required this.onIrRecuperar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController contrasenaController;
  final bool cargando;
  final bool verContrasena;
  final VoidCallback onToggleContrasena;
  final VoidCallback onLogin;
  final VoidCallback onIrRegistro;
  final VoidCallback onIrRecuperar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Logo / título
          Icon(
            Icons.restaurant_menu,
            size: 72,
            color: tema.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'MenuQR',
            textAlign: TextAlign.center,
            style: tema.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: tema.colorScheme.primary,
            ),
          ),
          Text(
            'El menú digital de tu negocio',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          // Campo email
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Ingresá tu email';
              }
              if (!valor.contains('@')) {
                return 'El email no es válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Campo contraseña
          TextFormField(
            controller: contrasenaController,
            obscureText: !verContrasena,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  verContrasena ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleContrasena,
              ),
            ),
            validator: (valor) {
              if (valor == null || valor.isEmpty) {
                return 'Ingresá tu contraseña';
              }
              if (valor.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          // Olvidaste contraseña
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onIrRecuperar,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 16),
          // Botón iniciar sesión
          FilledButton(
            onPressed: cargando ? null : onLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 24),
          // Ir a registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tenés cuenta?'),
              TextButton(
                onPressed: onIrRegistro,
                child: const Text('Registrate gratis'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
