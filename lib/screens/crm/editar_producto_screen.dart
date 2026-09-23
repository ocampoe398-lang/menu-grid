import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';

class EditarProductoScreen extends ConsumerStatefulWidget {
  final Producto? producto;
  final String? categoriaIdInicial;

  const EditarProductoScreen({
    super.key,
    this.producto,
    this.categoriaIdInicial,
  });

  @override
  ConsumerState<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends ConsumerState<EditarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;

  String? _categoriaSeleccionadaId;
  Uint8List? _nuevaFotoBytes;
  String _fotoUrlActual = '';
  bool _guardando = false;

  bool get esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final prod = widget.producto;
    _nombreController = TextEditingController(text: prod?.nombre ?? '');
    _descripcionController = TextEditingController(text: prod?.descripcion ?? '');
    _precioController = TextEditingController(
      text: prod != null ? (prod.precioEnCentavos / 100).toStringAsFixed(2) : '',
    );
    _categoriaSeleccionadaId = prod?.categoriaId ?? widget.categoriaIdInicial;
    _fotoUrlActual = prod?.fotoUrl ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    try {
      final picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (imagen != null) {
        final bytes = await imagen.readAsBytes();
        setState(() {
          _nuevaFotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionadaId == null || _categoriaSeleccionadaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccioná una categoría')),
      );
      return;
    }

    final uid = ref.read(authServiceProvider).usuarioActual?.uid;
    if (uid == null) return;

    final precioDouble = double.tryParse(_precioController.text.trim().replaceAll(',', '.')) ?? 0;
    final int precioEnCentavos = (precioDouble * 100).round();

    setState(() => _guardando = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      String productoId = widget.producto?.id ?? '';
      String fotoFinalUrl = _fotoUrlActual;

      if (esEdicion) {
        if (_nuevaFotoBytes != null) {
          fotoFinalUrl = await storageService.subirFotoProducto(
            uid: uid,
            productoId: productoId,
            bytes: _nuevaFotoBytes!,
          );
        }

        await firestoreService.actualizarProducto(
          uid: uid,
          productoId: productoId,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          precioEnCentavos: precioEnCentavos,
          categoriaId: _categoriaSeleccionadaId!,
          fotoUrl: fotoFinalUrl,
        );
      } else {
        productoId = await firestoreService.crearProducto(
          uid: uid,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          precioEnCentavos: precioEnCentavos,
          categoriaId: _categoriaSeleccionadaId!,
          fotoUrl: '',
        );

        if (_nuevaFotoBytes != null) {
          fotoFinalUrl = await storageService.subirFotoProducto(
            uid: uid,
            productoId: productoId,
            bytes: _nuevaFotoBytes!,
          );
          await firestoreService.actualizarProducto(
            uid: uid,
            productoId: productoId,
            fotoUrl: fotoFinalUrl,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion ? 'Producto actualizado' : 'Producto creado con éxito'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Edición de producto' : 'Nuevo producto'),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'NOMBRE',
                          hintText: 'Ej: Cerveza IPA, Hamburguesa Doble',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresá el nombre del producto' : null,
                      ),
                      const SizedBox(height: 20),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'DESCRIPCIÓN',
                          hintText: 'Detalles, ingredientes, tamaño...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Subir Foto + con preview
                      Card(
                        elevation: 0,
                        color: Colors.purple.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.purple.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_nuevaFotoBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _nuevaFotoBytes!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (_fotoUrlActual.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _fotoUrlActual,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.purple.shade700,
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.purple.shade800,
                                  side: BorderSide(color: Colors.purple.shade300),
                                ),
                                onPressed: _guardando ? null : _seleccionarFoto,
                                icon: const Icon(Icons.upload),
                                label: Text(
                                  (_nuevaFotoBytes != null || _fotoUrlActual.isNotEmpty)
                                      ? 'CAMBIAR FOTO'
                                      : 'SUBIR FOTO +',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fila de Precio y Categoría
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Precio
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _precioController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'PRECIO',
                                prefixText: '\$ ',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresá el precio';
                                final parsed = double.tryParse(v.replaceAll(',', '.'));
                                if (parsed == null || parsed < 0) return 'Precio no válido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Categoría
                          Expanded(
                            flex: 1,
                            child: categoriasAsync.when(
                              loading: () => const Center(child: LinearProgressIndicator()),
                              error: (_, __) => const Text('Error al cargar categorías'),
                              data: (categorias) {
                                if (_categoriaSeleccionadaId == null && categorias.isNotEmpty) {
                                  _categoriaSeleccionadaId = categorias.first.id;
                                }

                                return DropdownButtonFormField<String>(
                                  initialValue: categorias.any((c) => c.id == _categoriaSeleccionadaId)
                                      ? _categoriaSeleccionadaId
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'CATEGORÍA',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: categorias.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat.id,
                                      child: Text(
                                        cat.nombre,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _categoriaSeleccionadaId = val;
                                    });
                                  },
                                  validator: (v) => v == null ? 'Elegí categoría' : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Botón GUARDAR / GUARDAR CAMBIOS
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          onPressed: _guardando ? null : _guardar,
                          child: Text(
                            esEdicion ? 'GUARDAR CAMBIOS' : 'GUARDAR',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_guardando)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Guardando producto y sincronizando...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
