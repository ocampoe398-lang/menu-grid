import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream del usuario autenticado actualmente (null si no hay sesión).
  Stream<User?> get estadoAuth => _auth.authStateChanges();

  /// Usuario de Firebase actualmente autenticado.
  User? get usuarioActual => _auth.currentUser;

  /// Inicia sesión con email y contraseña.
  /// Lanza [FirebaseAuthException] si las credenciales son incorrectas.
  Future<User> login({
    required String email,
    required String contrasena,
  }) async {
    final resultado = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: contrasena,
    );
    return resultado.user!;
  }

  /// Registra un nuevo usuario con email y contraseña.
  /// Crea el documento en Firestore con los datos iniciales.
  Future<User> registro({
    required String nombre,
    required String nombreNegocio,
    required String email,
    required String contrasena,
  }) async {
    // 1. Crear cuenta en Firebase Auth
    final resultado = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: contrasena,
    );
    final usuario = resultado.user!;

    // 2. Crear documento en Firestore
    await _firestore.collection('usuarios').doc(usuario.uid).set(
          Usuario(
            uid: usuario.uid,
            nombre: nombre.trim(),
            email: email.trim(),
            nombreNegocio: nombreNegocio.trim(),
            logoUrl: '',
            createdAt: DateTime.now(),
            activo: true,
            plan: 'free',
          ).toJson(),
        );

    return usuario;
  }

  /// Envía un email de recuperación de contraseña.
  Future<void> recuperarContrasena(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Cierra la sesión del usuario actual.
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  /// Traduce los códigos de error de Firebase a mensajes en español.
  static String mensajeDeError(String codigo) {
    switch (codigo) {
      case 'user-not-found':
        return 'No existe una cuenta con ese email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Verificá tu internet.';
      default:
        return 'Error inesperado. Intentá de nuevo.';
    }
  }
}
