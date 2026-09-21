import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String nombreNegocio;
  final String logoUrl;
  final DateTime createdAt;
  final bool activo;
  final String plan; // 'free' | 'pro'
  final DateTime? planVencimiento;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.nombreNegocio,
    required this.logoUrl,
    required this.createdAt,
    required this.activo,
    required this.plan,
    this.planVencimiento,
  });

  /// Crea un Usuario desde un documento de Firestore.
  factory Usuario.fromDoc(DocumentSnapshot doc) {
    final datos = doc.data() as Map<String, dynamic>;
    return Usuario(
      uid: doc.id,
      nombre: datos['nombre'] as String? ?? '',
      email: datos['email'] as String? ?? '',
      nombreNegocio: datos['nombreNegocio'] as String? ?? '',
      logoUrl: datos['logoUrl'] as String? ?? '',
      createdAt: (datos['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activo: datos['activo'] as bool? ?? true,
      plan: datos['plan'] as String? ?? 'free',
      planVencimiento:
          (datos['planVencimiento'] as Timestamp?)?.toDate(),
    );
  }

  /// Convierte el Usuario a un Map para guardar en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'nombreNegocio': nombreNegocio,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'activo': activo,
      'plan': plan,
      'planVencimiento':
          planVencimiento != null ? Timestamp.fromDate(planVencimiento!) : null,
    };
  }

  /// Crea una copia con campos modificados.
  Usuario copyWith({
    String? nombre,
    String? email,
    String? nombreNegocio,
    String? logoUrl,
    bool? activo,
    String? plan,
    DateTime? planVencimiento,
  }) {
    return Usuario(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt,
      activo: activo ?? this.activo,
      plan: plan ?? this.plan,
      planVencimiento: planVencimiento ?? this.planVencimiento,
    );
  }
}
