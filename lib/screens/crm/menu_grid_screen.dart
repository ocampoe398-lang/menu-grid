import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

// TODO: implementar dashboard completo — Feature [2] del MVP
class MenuGridScreen extends ConsumerWidget {
  const MenuGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final usuario = authService.usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MenuQR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authService.cerrarSesion();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              usuario?.email ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const Text(
              'Dashboard en construcción...\n(Feature [2] — próximo paso)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
