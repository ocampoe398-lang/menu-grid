import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube la foto a Firebase Storage. Si el bucket no está habilitado o demora más
  /// de 2.5 segundos, utiliza almacenamiento Base64 de alta velocidad como fallback.
  Future<String> subirFotoProducto({
    required String uid,
    required String productoId,
    required Uint8List bytes,
  }) async {
    try {
      final ref = _storage.ref().child('usuarios/$uid/productos/$productoId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'subidoPor': uid},
      );

      final uploadTask = await ref
          .putData(bytes, metadata)
          .timeout(const Duration(milliseconds: 2500));
      final url = await uploadTask.ref
          .getDownloadURL()
          .timeout(const Duration(milliseconds: 2500));
      return url;
    } catch (e) {
      debugPrint('Firebase Storage no disponible o tardó demasiado: $e. Usando compresión Base64.');
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}
