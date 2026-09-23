import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/auth_provider.dart';

class QRGeneratorScreen extends ConsumerWidget {
  const QRGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final user = auth.usuarioActual;
    // Placeholder URL; replace with your domain as needed
    final url = user != null ? 'https://example.com/menu/${user.uid}' : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Código QR del Menú')),
      body: Center(
        child: url.isEmpty
            ? const Text('Usuario no autenticado')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(data: url, size: 240),
                  const SizedBox(height: 16),
                  Text(url, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir enlace'),
                    onPressed: () => Share.share(url),
                  ),
                ],
              ),
      ),
    );
  }
}
