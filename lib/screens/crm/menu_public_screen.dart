import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';

class MenuPublicScreen extends ConsumerWidget {
  const MenuPublicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasProvider);
    final productosAsync = ref.watch(productosProvider);
    final List<Categoria> categorias = categoriasAsync.value ?? [];
    final productos = productosAsync.value ?? [];

    // Group products by category ID
    final Map<String, List<Producto>> productosPorCategoria = {};
    for (final p in productos) {
      productosPorCategoria.putIfAbsent(p.categoriaId, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Menú Público')),
      body: categorias.isEmpty
          ? const Center(child: Text('No hay categorías'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final items = productosPorCategoria[cat.id] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final prod = items[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: prod.fotoUrl,
                                  placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (c, u, e) => const Icon(Icons.image_not_supported),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('\${(prod.precioEnCentavos / 100).toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }
}
