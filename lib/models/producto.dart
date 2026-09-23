import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final int precioEnCentavos;
  final String categoriaId;
  final String fotoUrl;
  final bool disponible;
  final int orden;
  final DateTime createdAt;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioEnCentavos,
    required this.categoriaId,
    required this.fotoUrl,
    required this.disponible,
    required this.orden,
    required this.createdAt,
  });

  /// Crea un Producto a partir de un documento de Firestore.
  factory Producto.fromDoc(DocumentSnapshot doc) {
    final datos = doc.data() as Map<String, dynamic>? ?? {};
    return Producto(
      id: doc.id,
      nombre: datos['nombre'] as String? ?? '',
      descripcion: datos['descripcion'] as String? ?? '',
      precioEnCentavos: (datos['precioEnCentavos'] as num?)?.toInt() ?? 0,
      categoriaId: datos['categoriaId'] as String? ?? '',
      fotoUrl: datos['fotoUrl'] as String? ?? '',
      disponible: datos['disponible'] as bool? ?? true,
      orden: (datos['orden'] as num?)?.toInt() ?? 0,
      createdAt: (datos['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convierte el Producto a un mapa para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precioEnCentavos': precioEnCentavos,
      'categoriaId': categoriaId,
      'fotoUrl': fotoUrl,
      'disponible': disponible,
      'orden': orden,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Producto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    int? precioEnCentavos,
    String? categoriaId,
    String? fotoUrl,
    bool? disponible,
    int? orden,
    DateTime? createdAt,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioEnCentavos: precioEnCentavos ?? this.precioEnCentavos,
      categoriaId: categoriaId ?? this.categoriaId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      disponible: disponible ?? this.disponible,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
