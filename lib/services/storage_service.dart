import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
      // Compresión obligatoria según AGENTS.md
      debugPrint('Comprimiendo imagen original de ${bytes.lengthInBytes} bytes...');
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 75,
      );
      
      final finalBytes = compressedBytes;
      debugPrint('Imagen comprimida a ${finalBytes.lengthInBytes} bytes.');

      final ref = _storage.ref().child('usuarios/$uid/productos/$productoId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'subidoPor': uid},
      );

      final uploadTask = await ref
          .putData(finalBytes, metadata)
          .timeout(const Duration(milliseconds: 2500));
      final url = await uploadTask.ref
          .getDownloadURL()
          .timeout(const Duration(milliseconds: 2500));
      return url;
    } catch (e) {
      debugPrint('Firebase Storage no disponible o tardó demasiado: $e. Usando compresión Base64.');
      
      // Asegurar que usamos bytes comprimidos si están disponibles, sino los originales
      Uint8List targetBytes = bytes;
      try {
        targetBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 75,
        );
      } catch (_) {}

      final base64String = base64Encode(targetBytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}
