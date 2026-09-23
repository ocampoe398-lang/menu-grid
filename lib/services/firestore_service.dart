import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';
import '../models/producto.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------------------------------------
  // CATEGORÍAS
  // -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _categoriasRef(String uid) {
    return _firestore.collection('usuarios').doc(uid).collection('categorias');
  }

  /// Retorna un Stream con todas las categorías ordenadas por 'orden'.
  Stream<List<Categoria>> streamCategorias(String uid) {
    return _categoriasRef(uid)
        .orderBy('orden', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Categoria.fromDoc(doc)).toList();
    });
  }

  /// Crea una nueva categoría.
  Future<void> crearCategoria({
    required String uid,
    required String nombre,
    int? orden,
  }) async {
    final categoriasCol = _categoriasRef(uid);
    int ordenFinal = orden ?? 0;

    if (orden == null) {
      final snapshot = await categoriasCol.orderBy('orden', descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final maxOrden = (snapshot.docs.first.data()['orden'] as num?)?.toInt() ?? 0;
        ordenFinal = maxOrden + 1;
      }
    }

    await categoriasCol.add({
      'nombre': nombre.trim(),
      'orden': ordenFinal,
      'activa': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza los datos de una categoría.
  Future<void> actualizarCategoria({
    required String uid,
    required String categoriaId,
    String? nombre,
    int? orden,
    bool? activa,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre.trim();
    if (orden != null) data['orden'] = orden;
    if (activa != null) data['activa'] = activa;

    if (data.isNotEmpty) {
      await _categoriasRef(uid).doc(categoriaId).update(data);
    }
  }

  /// Alterna el estado activo/inactivo (soft-delete).
  Future<void> toggleActivaCategoria({
    required String uid,
    required String categoriaId,
    required bool activa,
  }) async {
    await _categoriasRef(uid).doc(categoriaId).update({'activa': activa});
  }

  /// Elimina una categoría.
  Future<void> eliminarCategoria({
    required String uid,
    required String categoriaId,
  }) async {
    await _categoriasRef(uid).doc(categoriaId).delete();
  }

  // -------------------------------------------------------------
  // PRODUCTOS
  // -------------------------------------------------------------
  CollectionReference<Map<String, dynamic>> _productosRef(String uid) {
    return _firestore.collection('usuarios').doc(uid).collection('productos');
  }

  /// Retorna un Stream con todos los productos de un usuario.
  Stream<List<Producto>> streamProductos(String uid, {String? categoriaId}) {
    Query<Map<String, dynamic>> query = _productosRef(uid).orderBy('orden', descending: false);
    if (categoriaId != null && categoriaId.isNotEmpty) {
      query = query.where('categoriaId', isEqualTo: categoriaId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Producto.fromDoc(doc)).toList();
    });
  }

  /// Crea un nuevo producto y devuelve el ID generado.
  Future<String> crearProducto({
    required String uid,
    required String nombre,
    required String descripcion,
    required int precioEnCentavos,
    required String categoriaId,
    String fotoUrl = '',
    int? orden,
  }) async {
    final col = _productosRef(uid);
    int ordenFinal = orden ?? 0;

    if (orden == null) {
      final snapshot = await col.orderBy('orden', descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final maxOrden = (snapshot.docs.first.data()['orden'] as num?)?.toInt() ?? 0;
        ordenFinal = maxOrden + 1;
      }
    }

    final docRef = await col.add({
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'precioEnCentavos': precioEnCentavos,
      'categoriaId': categoriaId,
      'fotoUrl': fotoUrl,
      'disponible': true,
      'orden': ordenFinal,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Actualiza un producto existente.
  Future<void> actualizarProducto({
    required String uid,
    required String productoId,
    String? nombre,
    String? descripcion,
    int? precioEnCentavos,
    String? categoriaId,
    String? fotoUrl,
    bool? disponible,
    int? orden,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre.trim();
    if (descripcion != null) data['descripcion'] = descripcion.trim();
    if (precioEnCentavos != null) data['precioEnCentavos'] = precioEnCentavos;
    if (categoriaId != null) data['categoriaId'] = categoriaId;
    if (fotoUrl != null) data['fotoUrl'] = fotoUrl;
    if (disponible != null) data['disponible'] = disponible;
    if (orden != null) data['orden'] = orden;

    if (data.isNotEmpty) {
      await _productosRef(uid).doc(productoId).update(data);
    }
  }

  /// Alterna la disponibilidad del producto (disponible/agotado).
  Future<void> toggleDisponibleProducto({
    required String uid,
    required String productoId,
    required bool disponible,
  }) async {
    await _productosRef(uid).doc(productoId).update({'disponible': disponible});
  }

  /// Elimina físicamente un producto.
  Future<void> eliminarProducto({
    required String uid,
    required String productoId,
  }) async {
    await _productosRef(uid).doc(productoId).delete();
  }
}
