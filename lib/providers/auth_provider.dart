import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// Instancia singleton del AuthService.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream del estado de autenticación (User? de Firebase).
/// null = no autenticado, User = autenticado.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).estadoAuth;
});
