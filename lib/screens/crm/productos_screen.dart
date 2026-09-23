import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';
import '../../utils/formato.dart';
import 'editar_producto_screen.dart';

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  String? _filtroCategoriaId;
  bool _procesando = false;

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar producto'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final uid = ref.read(authServiceProvider).usuarioActual?.uid;
    if (uid == null) return;

    setState(() => _procesando = true);
    try {
      await ref.read(firestoreServiceProvider).eliminarProducto(
            uid: uid,
            productoId: producto.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto "${producto.nombre}" borrado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _toggleDisponible(Producto producto, bool valor) async {
    final uid = ref.read(authServiceProvider).usuarioActual?.uid;
    if (uid == null) return;

    try {
      await ref.read(firestoreServiceProvider).toggleDisponibleProducto(
            uid: uid,
            productoId: producto.id,
            disponible: valor,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              valor
                  ? '"${producto.nombre}" marcado como Disponible'
                  : '"${producto.nombre}" marcado como Agotado',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar disponibilidad: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final categoriasAsync = ref.watch(categoriasProvider);

    final categoriasMap = {
      for (final c in (categoriasAsync.value ?? [])) c.id: c.nombre,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        title: const Text('Productos y Precios'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior destacada: botón Nuevo Producto +
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text(
                      'Nuevo Producto +',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditarProductoScreen(
                            categoriaIdInicial: _filtroCategoriaId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Chips de filtro por categoría
              categoriasAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categorias) {
                  if (categorias.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: const Text('Todas'),
                            selected: _filtroCategoriaId == null,
                            onSelected: (_) {
                              setState(() => _filtroCategoriaId = null);
                            },
                          ),
                        ),
                        ...categorias.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat.nombre),
                              selected: _filtroCategoriaId == cat.id,
                              onSelected: (_) {
                                setState(() {
                                  _filtroCategoriaId =
                                      _filtroCategoriaId == cat.id ? null : cat.id;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Listado de Productos
              Expanded(
                child: productosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error al cargar productos: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (productos) {
                    final productosFiltrados = _filtroCategoriaId == null
                        ? productos
                        : productos.where((p) => p.categoriaId == _filtroCategoriaId).toList();

                    if (productosFiltrados.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fastfood_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay productos cargados',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filtroCategoriaId == null
                                    ? 'Cargá platos, bebidas y precios para mostrarlos en tu menú digital.'
                                    : 'No hay productos en esta categoría.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: productosFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final prod = productosFiltrados[index];
                        final nombreCat = categoriasMap[prod.categoriaId] ?? 'Sin categoría';

                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto del producto (Izquierda)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade100,
                                    child: prod.fotoUrl.isNotEmpty
                                        ? Image.network(
                                            prod.fotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 32,
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : Icon(
                                            Icons.restaurant,
                                            size: 36,
                                            color: Colors.grey.shade400,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Datos del producto (Centro)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              prod.nombre,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: prod.disponible
                                                    ? Colors.black87
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            formatPrecio(prod.precioEnCentavos),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Categoría badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          nombreCat,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // Descripción
                                      if (prod.descripcion.isNotEmpty)
                                        Text(
                                          prod.descripcion,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),

                                      const SizedBox(height: 10),

                                      // Fila de acciones (EDITAR / BORRAR / DISPONIBLE)
                                      Row(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Switch(
                                                value: prod.disponible,
                                                activeThumbColor: const Color(0xFF2E7D32),
                                                onChanged: _procesando
                                                    ? null
                                                    : (val) => _toggleDisponible(prod, val),
                                              ),
                                              Text(
                                                prod.disponible ? 'Disponible' : 'Agotado',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: prod.disponible
                                                      ? Colors.green.shade700
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                            ),
                                            onPressed: _procesando
                                                ? null
                                                : () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) => EditarProductoScreen(
                                                          producto: prod,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            child: const Text(
                                              'EDITAR',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red.shade700,
                                              side: BorderSide(color: Colors.red.shade200),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                            ),
                                            onPressed: _procesando
                                                ? null
                                                : () => _eliminarProducto(prod),
                                            child: const Text(
                                              'BORRAR',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
