import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'categorias_provider.dart';

/// Instancia singleton de StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Stream de los productos del usuario autenticado.
final productosProvider = StreamProvider<List<Producto>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProductos(user.uid);
});

/// Contador de productos activos/disponibles.
final totalProductosActivosProvider = Provider<int>((ref) {
  final productos = ref.watch(productosProvider).value ?? [];
  return productos.where((p) => p.disponible).length;
});
