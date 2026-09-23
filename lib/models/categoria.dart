import 'package:cloud_firestore/cloud_firestore.dart';

class Categoria {
  final String id;
  final String nombre;
  final int orden;
  final bool activa;
  final DateTime createdAt;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.activa,
    required this.createdAt,
  });

  /// Crea una Categoria a partir de un documento de Firestore.
  factory Categoria.fromDoc(DocumentSnapshot doc) {
    final datos = doc.data() as Map<String, dynamic>? ?? {};
    return Categoria(
      id: doc.id,
      nombre: datos['nombre'] as String? ?? '',
      orden: (datos['orden'] as num?)?.toInt() ?? 0,
      activa: datos['activa'] as bool? ?? true,
      createdAt: (datos['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convierte la Categoria en un mapa para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'orden': orden,
      'activa': activa,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Categoria copyWith({
    String? id,
    String? nombre,
    int? orden,
    bool? activa,
    DateTime? createdAt,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
