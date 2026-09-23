import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/categoria.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';

class CategoriasScreen extends ConsumerStatefulWidget {
  const CategoriasScreen({super.key});

  @override
  ConsumerState<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends ConsumerState<CategoriasScreen> {
  bool _procesando = false;

  void _mostrarDialogoCrearOEditar([Categoria? categoria]) {
    final esEdicion = categoria != null;
    final textController = TextEditingController(text: categoria?.nombre ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(esEdicion ? 'Editar categoría' : 'Nueva categoría'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Bebidas, Hamburguesas, Postres',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Por favor ingresá un nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final nuevoNombre = textController.text.trim();
              Navigator.of(dialogCtx).pop();

              final uid = ref.read(authServiceProvider).usuarioActual?.uid;
              if (uid == null) return;

              final firestoreService = ref.read(firestoreServiceProvider);

              setState(() => _procesando = true);
              try {
                if (esEdicion) {
                  await firestoreService.actualizarCategoria(
                    uid: uid,
                    categoriaId: categoria.id,
                    nombre: nuevoNombre,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría actualizada con éxito')),
                    );
                  }
                } else {
                  await firestoreService.crearCategoria(
                    uid: uid,
                    nombre: nuevoNombre,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría creada con éxito')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar categoría: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _procesando = false);
              }
            },
            child: Text(esEdicion ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEstado(Categoria categoria, bool nuevoEstado) async {
    final uid = ref.read(authServiceProvider).usuarioActual?.uid;
    if (uid == null) return;

    try {
      await ref.read(firestoreServiceProvider).toggleActivaCategoria(
            uid: uid,
            categoriaId: categoria.id,
            activa: nuevoEstado,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado
                  ? 'Categoría "${categoria.nombre}" activada'
                  : 'Categoría "${categoria.nombre}" oculta',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final uid = ref.read(authServiceProvider).usuarioActual?.uid;
    if (uid == null) return;

    setState(() => _procesando = true);
    try {
      await ref.read(firestoreServiceProvider).eliminarCategoria(
            uid: uid,
            categoriaId: categoria.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "${categoria.nombre}" eliminada'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar categoría: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías del Menú'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : () => _mostrarDialogoCrearOEditar(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
      body: Stack(
        children: [
          categoriasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error al cargar categorías: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            data: (categorias) {
              if (categorias.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tenés categorías creadas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Creá secciones como "Bebidas", "Hamburguesas" o "Postres" para organizar tus productos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _mostrarDialogoCrearOEditar(),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear mi primera categoría'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      return Card(
                        elevation: cat.activa ? 2 : 0,
                        color: cat.activa ? Colors.white : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: cat.activa
                                ? Colors.grey.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cat.activa
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade300,
                            child: Icon(
                              Icons.folder_outlined,
                              color: cat.activa
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            cat.nombre,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: cat.activa ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            cat.activa ? 'Visible en el menú' : 'Oculta en el menú',
                            style: TextStyle(
                              color: cat.activa ? Colors.green.shade700 : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: cat.activa,
                                onChanged: _procesando
                                    ? null
                                    : (val) => _toggleEstado(cat, val),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar nombre',
                                onPressed: _procesando
                                    ? null
                                    : () => _mostrarDialogoCrearOEditar(cat),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                ),
                                tooltip: 'Eliminar',
                                onPressed: _procesando
                                    ? null
                                    : () => _confirmarEliminar(cat),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (_procesando)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
