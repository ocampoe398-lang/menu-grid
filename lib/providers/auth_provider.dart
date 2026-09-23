import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Instancia singleton del AuthService.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream del estado de autenticación (User? de Firebase).
/// null = no autenticado, User = autenticado.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).estadoAuth;
});

/// Stream con los datos completos del perfil de usuario desde Firestore.
final usuarioProfileProvider = StreamProvider<Usuario?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? Usuario.fromDoc(doc) : null);
});
