import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

class RecuperarPasswordScreen extends ConsumerStatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  ConsumerState<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState
    extends ConsumerState<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _cargando = false;
  bool _emailEnviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ref.read(authServiceProvider).recuperarContrasena(
            _emailController.text,
          );
      if (mounted) {
        setState(() => _emailEnviado = true);
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
            content: Text('Error al enviar el email: $e'),
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
        title: const Text('Recuperar contraseña'),
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
              child: _emailEnviado
                  ? _ConfirmacionEnviada(
                      email: _emailController.text,
                      onVolver: () => Navigator.of(context).pop(),
                    )
                  : _FormularioRecuperar(
                      formKey: _formKey,
                      emailController: _emailController,
                      cargando: _cargando,
                      onEnviar: _enviarEmail,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormularioRecuperar extends StatelessWidget {
  const _FormularioRecuperar({
    required this.formKey,
    required this.emailController,
    required this.cargando,
    required this.onEnviar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool cargando;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Recuperar contraseña',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Te enviamos un link para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onEnviar(),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: cargando ? null : onEnviar,
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
                    'Enviar link de recuperación',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmacionEnviada extends StatelessWidget {
  const _ConfirmacionEnviada({
    required this.email,
    required this.onVolver,
  });

  final String email;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: Colors.green.shade600,
        ),
        const SizedBox(height: 16),
        Text(
          '¡Email enviado!',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Revisá tu bandeja de entrada en\n$email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onVolver,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Volver al login', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
