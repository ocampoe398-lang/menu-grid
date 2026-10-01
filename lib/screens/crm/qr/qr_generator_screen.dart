import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../providers/auth_provider.dart';

class QRGeneratorScreen extends ConsumerStatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  ConsumerState<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends ConsumerState<QRGeneratorScreen> {
  bool _isSharing = false;

  Future<void> _compartirQRComoImagen(String url) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final painter = QrPainter(
        data: url,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/qr_menu_local.png';
        final file = File(path);
        await file.writeAsBytes(picData.buffer.asUint8List());
        await Share.shareXFiles(
          [XFile(path)],
          text: '¡Escaneá nuestro código QR para ver el menú digital!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir QR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final user = auth.usuarioActual;
    final url = user != null ? 'https://menuqr.com/menu/${user.uid}' : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Código QR del Menú')),
      body: Center(
        child: url.isEmpty
            ? const Text('Usuario no autenticado')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: QrImageView(data: url, size: 240),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '¡Imprimilo o envialo a tus clientes!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: _isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: const Text('Compartir QR (PNG)'),
                    onPressed: () => _compartirQRComoImagen(url),
                  ),
                ],
              ),
      ),
    );
  }
}
