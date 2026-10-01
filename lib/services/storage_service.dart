import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> subirFotoProducto({
    required String uid,
    required String productoId,
    required Uint8List bytes,
  }) async {
    try {
      Uint8List finalBytes = bytes;
      
      // flutter_image_compress no soporta Web nativamente, así que lo saltamos en Web
      if (!kIsWeb) {
        debugPrint('Comprimiendo imagen original de ${bytes.lengthInBytes} bytes...');
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 75,
        );
        finalBytes = compressed;
        debugPrint('Imagen comprimida a ${finalBytes.lengthInBytes} bytes.');
      } else {
        debugPrint('Entorno Web detectado. Subiendo ${bytes.lengthInBytes} bytes sin compresión local.');
      }

      final ref = _storage.ref().child('usuarios/$uid/productos/$productoId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'subidoPor': uid},
      );

      final uploadTask = await ref.putData(finalBytes, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Firebase Storage no disponible o tardó demasiado: $e. Usando compresión Base64.');
      
      // Asegurar que usamos bytes comprimidos si están disponibles, sino los originales
      Uint8List targetBytes = bytes;
      if (!kIsWeb) {
        try {
          targetBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 800,
            minHeight: 800,
            quality: 75,
          );
        } catch (_) {}
      }

      final base64String = base64Encode(targetBytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}
