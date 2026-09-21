import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../crm/menu_grid_screen.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nombreNegocioController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _cargando = false;
  bool _verContrasena = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreNegocioController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ref.read(authServiceProvider).registro(
            nombre: _nombreController.text,
            nombreNegocio: _nombreNegocioController.text,
            email: _emailController.text,
            contrasena: _contrasenaController.text,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MenuGridScreen()),
          (ruta) => false,
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
            content: Text('Error al registrarse: $e'),
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
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: esWeb ? 400 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Registrá tu negocio',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creá tu menú digital gratis',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    // Nombre personal
                    TextFormField(
                      controller: _nombreController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Ingresá tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Nombre del negocio
                    TextFormField(
                      controller: _nombreNegocioController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del negocio',
                        prefixIcon: Icon(Icons.store_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Ingresá el nombre de tu negocio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
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
                    // Contraseña
                    TextFormField(
                      controller: _contrasenaController,
                      obscureText: !_verContrasena,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _registrarse(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        helperText: 'Mínimo 6 caracteres',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verContrasena
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                              () => _verContrasena = !_verContrasena),
                        ),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Ingresá una contraseña';
                        }
                        if (valor.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Botón registrarse
                    FilledButton(
                      onPressed: _cargando ? null : _registrarse,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Crear cuenta gratis',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Volver al login
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
