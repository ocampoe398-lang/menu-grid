import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Instancia singleton del FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Stream de las categorías del usuario actualmente autenticado.
final categoriasProvider = StreamProvider<List<Categoria>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCategorias(user.uid);
});

/// Contador de categorías activas.
final totalCategoriasActivasProvider = Provider<int>((ref) {
  final categorias = ref.watch(categoriasProvider).value ?? [];
  return categorias.where((c) => c.activa).length;
});
