import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';
import '../../utils/formato.dart';

class MenuPublicScreen extends ConsumerStatefulWidget {
  const MenuPublicScreen({super.key});

  @override
  ConsumerState<MenuPublicScreen> createState() => _MenuPublicScreenState();
}

class _MenuPublicScreenState extends ConsumerState<MenuPublicScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoriaKeys = {};

  void _scrollToCategoria(String id) {
    final key = _categoriaKeys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);
    final productosAsync = ref.watch(productosProvider);
    final List<Categoria> categoriasAll = categoriasAsync.value ?? [];
    final productos = productosAsync.value ?? [];

    // Solo mostramos categorías activas
    final categorias = categoriasAll.where((c) => c.activa).toList();

    // Agrupar productos por categoría
    final Map<String, List<Producto>> productosPorCategoria = {};
    for (final p in productos) {
      productosPorCategoria.putIfAbsent(p.categoriaId, () => []).add(p);
    }

    // Asegurarse de que cada categoría tenga una GlobalKey para el scroll
    for (final cat in categorias) {
      _categoriaKeys.putIfAbsent(cat.id, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Cabecera del restaurante (Portada)
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Nuestro Menú',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra de navegación de categorías (Sticky Tabs)
          if (categorias.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCategoryDelegate(
                child: Container(
                  color: Colors.white,
                  height: 54,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                          label: Text(
                            cat.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          onPressed: () => _scrollToCategoria(cat.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Listado de Categorías y Productos
          if (categorias.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Menú no disponible por el momento')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = categorias[index];
                  final items = productosPorCategoria[cat.id] ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();

                  return Column(
                    key: _categoriaKeys[cat.id],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de la categoría
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Text(
                          cat.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      // Grilla de platos
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final prod = items[i];
                          final agotado = !prod.disponible;

                          return Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen con manejo de Agotado y Shimmer
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (prod.fotoUrl.isNotEmpty)
                                        ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            agotado
                                                ? Colors.grey
                                                : Colors.transparent,
                                            agotado
                                                ? BlendMode.saturation
                                                : BlendMode.multiply,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: prod.fotoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (c, u) =>
                                                Shimmer.fromColors(
                                                  baseColor:
                                                      Colors.grey.shade300,
                                                  highlightColor:
                                                      Colors.grey.shade100,
                                                  child: Container(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                            errorWidget: (c, u, e) => Container(
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          color: Colors.grey.shade100,
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Colors.grey,
                                          ),
                                        ),

                                      // Overlay Agotado
                                      if (agotado)
                                        Container(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'AGOTADO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Detalles
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prod.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: agotado
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formatPrecio(prod.precioEnCentavos),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: agotado
                                              ? Colors.grey.shade500
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                }, childCount: categorias.length),
              ),
            ),
        ],
      ),
      // Footer obligatorio según AGENTS.md
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Menú digital impulsado por',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/registro'),
              child: const Text(
                'MenuQR - Creá el tuyo gratis acá',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Delegado para fijar la barra de categorías en el top al scrollear
class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCategoryDelegate({required this.child});

  @override
  double get minExtent => 54.0;

  @override
  double get maxExtent => 54.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(elevation: overlapsContent ? 2.0 : 0.0, child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
