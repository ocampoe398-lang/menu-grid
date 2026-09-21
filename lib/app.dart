import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/crm/menu_grid_screen.dart';

class MenuQRApp extends ConsumerWidget {
  const MenuQRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoAuth = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'MenuQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: estadoAuth.when(
        // Cargando estado de auth (splash implícito)
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        // Error de Firebase
        error: (_, __) => const LoginScreen(),
        // Ruta según si hay sesión activa
        data: (usuario) =>
            usuario != null ? const MenuGridScreen() : const LoginScreen(),
      ),
    );
  }
}
