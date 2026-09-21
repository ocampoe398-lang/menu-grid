# AGENTS.md — App de Menú Digital (Flutter + Firebase)

Este archivo es la fuente de verdad del proyecto para cualquier agente (Antigravity u otro) que trabaje en este repo.
**Antes de generar código, leé este archivo completo.**
Si algo que vas a hacer contradice lo definido acá, preguntá antes de improvisar.

---

## 1. Qué es el proyecto

App de menú digital para locales gastronómicos, con dos frentes:

1. **CRM (Android + Web)**: el dueño del local gestiona su menú — login, categorías, productos, fotos, código QR.
2. **Menú público (Web)**: el cliente final escanea un QR y ve el menú del local sin necesidad de login ni de instalar nada.

Un solo codebase Flutter para los tres targets (Android app, CRM web, menú público web).

### Objetivo de negocio
Cada QR que se genera es un canal de distribución orgánico. El menú público **debe** incluir un footer con el link de registro al producto — cada cliente que escanea es un potencial usuario nuevo. No eliminar ni ocultar este footer bajo ningún concepto sin aprobación explícita.

---

## 2. Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter + Dart |
| Backend | Firebase (Auth, Firestore, Storage, Hosting) |
| State management | Riverpod (StreamProvider para datos en tiempo real) |
| IDE / debug nativo | Android Studio |
| Asistencia de código | Antigravity |

### Paquetes clave

```yaml
dependencies:
  firebase_core: ...
  firebase_auth: ...
  cloud_firestore: ...
  firebase_storage: ...
  qr_flutter: ...
  share_plus: ...
  cached_network_image: ...
  flutter_image_compress: ...   # compresión antes de upload a Storage
  image_picker: ...             # selección de foto desde galería/cámara

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ...
  build_runner: ...
```

> **Regla**: no agregar dependencias nuevas sin mencionarlo primero. Cada paquete nuevo que se agregue debe justificarse en este archivo.

---

## 3. Modelo de datos en Firestore

> **Regla**: NO reinventar esta estructura. Si hace falta agregar un campo nuevo, se agrega a este archivo primero, no directo al código.

```
usuarios/{uid}
  ├─ nombre: string
  ├─ email: string
  ├─ nombreNegocio: string
  ├─ logoUrl: string
  ├─ createdAt: timestamp
  ├─ activo: bool           // true = cuenta activa; false = suspendida por admin o plan vencido
  ├─ plan: string           // 'free' | 'pro' — base para monetización futura, NO implementar lógica en el MVP
  └─ planVencimiento: timestamp | null   // null = sin vencimiento (plan free ilimitado en MVP)

usuarios/{uid}/categorias/{categoriaId}
  ├─ nombre: string
  ├─ orden: number          // entero, para reordenamiento drag-and-drop
  ├─ activa: bool           // false = oculta en el menú público, visible en CRM
  └─ createdAt: timestamp

usuarios/{uid}/productos/{productoId}
  ├─ nombre: string
  ├─ descripcion: string
  ├─ precioEnCentavos: number   // ENTERO en centavos. Ej: 1250 = $12.50. Nunca float.
  ├─ categoriaId: string        // referencia a categorias/{categoriaId}
  ├─ fotoUrl: string
  ├─ disponible: bool           // false = agotado, visible en CRM, oculto/marcado en menú público
  ├─ orden: number              // entero, para reordenamiento dentro de la categoría
  └─ createdAt: timestamp
```

### Convenciones de nombres
- Todo en **español**, camelCase para campos, sin abreviaturas raras.
- Excepción explícita: `precioEnCentavos` lleva sufijo para que sea imposible confundirlo con un float.
- Clases Dart y nombres de archivos siguen convenciones de Flutter (PascalCase para clases, snake_case para archivos).

### Notas importantes sobre el precio
- El precio **siempre** se almacena como entero en centavos.
- Para mostrar: `(precioEnCentavos / 100).toStringAsFixed(2)` o usar un helper `formatPrecio(int centavos)` en `lib/utils/formato.dart`.
- Para guardar desde un TextField: parsear el string del usuario, multiplicar por 100, guardar como int.
- **Nunca** hacer aritmética de precios con doubles directamente.

---

## 4. Storage — paths y reglas de imágenes

```
/usuarios/{uid}/productos/{productoId}.jpg
/usuarios/{uid}/logo.jpg
```

### Reglas de upload obligatorias
Antes de cualquier upload a Firebase Storage:

1. **Comprimir** la imagen con `flutter_image_compress` a máximo **800px** en el lado más largo y calidad **75**.
2. **Formato**: siempre `.jpg`, nunca PNG para fotos (Storage y ancho de banda innecesario).
3. **Tamaño máximo aceptado para upload**: 5 MB después de compresión. Si supera ese límite, mostrar error al usuario.
4. El `productoId` del path debe existir en Firestore antes de subir la imagen (crear el documento primero, subir foto después).

```dart
// Flujo correcto en storage_service.dart:
// 1. Comprimir imagen con flutter_image_compress
// 2. Subir a Storage
// 3. Obtener downloadUrl
// 4. Actualizar fotoUrl en el documento Firestore del producto
```

---

## 5. Reglas de seguridad de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usuarios/{uid} {
      allow read: if true; // el menú público necesita leer sin auth
      allow write: if request.auth != null && request.auth.uid == uid;

      match /categorias/{catId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == uid;
      }
      match /productos/{prodId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

> **IMPORTANTE**: cualquier cambio a estas reglas debe ser explícito y revisado antes de deployarse. No modificar reglas de seguridad sin mostrar el diff primero.

---

## 6. Índices compuestos de Firestore

Estas queries requieren índices compuestos. Crearlos en la consola o via `firestore.indexes.json` antes de que la app los necesite — de lo contrario fallan silenciosamente en algunos SDK.

| Colección | Campo 1 | Campo 2 |
|---|---|---|
| `productos` | `categoriaId` ASC | `orden` ASC |
| `categorias` | `activa` ASC | `orden` ASC |
| `productos` | `disponible` ASC | `orden` ASC |

> Si se agrega una query nueva con múltiples campos, documentar el índice requerido en esta tabla antes de implementarla.

---

## 7. Estrategia de layout multiplataforma

El codebase es único pero los layouts **no son idénticos** entre Android y Web. Usar `kIsWeb` y breakpoints para adaptar sin duplicar lógica de negocio.

### Breakpoints de referencia

```dart
// lib/utils/responsive.dart
const double kBreakpointMovil  = 600;
const double kBreakpointTablet = 900;
```

### Reglas por pantalla

| Pantalla | Android | Web CRM | Menú público web |
|---|---|---|---|
| Login / Registro | Pantalla completa | Card centrada max-width 400px | N/A |
| Menu Grid | BottomNavigationBar | Sidebar/Rail lateral | N/A |
| Lista productos | ListView vertical | Grid 2–3 columnas | Grid responsivo |
| Edición producto | Pantalla completa | Dialog / modal | N/A |
| QR | Pantalla centrada | Card centrada | N/A |
| Menú público | N/A | N/A | Max-width 480px centrado |

> No asumir que un widget funciona igual en web y Android sin verificarlo. Si hay duda, preguntar antes.

---

## 8. Arquitectura de carpetas

```
lib/
 ├─ main.dart
 ├─ app.dart                         // configuración de rutas y tema
 ├─ models/
 │   ├─ usuario.dart                 // fromDoc / toJson
 │   ├─ categoria.dart
 │   └─ producto.dart
 ├─ providers/
 │   ├─ auth_provider.dart           // estado de autenticación
 │   ├─ categorias_provider.dart     // StreamProvider desde Firestore
 │   ├─ productos_provider.dart
 │   └─ menu_agrupado_provider.dart  // productos agrupados por categoría
 ├─ screens/
 │   ├─ auth/
 │   │   ├─ login_screen.dart
 │   │   ├─ registro_screen.dart
 │   │   └─ recuperar_password_screen.dart
 │   ├─ crm/
 │   │   ├─ menu_grid_screen.dart
 │   │   ├─ categorias_screen.dart
 │   │   ├─ editar_categoria_screen.dart
 │   │   ├─ productos_screen.dart
 │   │   └─ editar_producto_screen.dart
 │   ├─ qr/
 │   │   └─ qr_screen.dart
 │   └─ menu_publico/
 │       └─ menu_publico_screen.dart
 ├─ widgets/
 │   ├─ producto_tile.dart
 │   ├─ categoria_section.dart
 │   ├─ estado_vacio.dart            // widget genérico para listas vacías
 │   ├─ loading_overlay.dart
 │   └─ error_banner.dart
 ├─ services/
 │   ├─ auth_service.dart
 │   ├─ firestore_service.dart
 │   └─ storage_service.dart
 └─ utils/
     ├─ formato.dart                 // formatPrecio(), formatFecha(), etc.
     └─ responsive.dart              // kIsWeb, breakpoints, helpers de layout
```

---

## 9. Convenciones de código

### General
- Widgets pequeños y reutilizables. Ninguna pantalla debe superar ~300 líneas. Si supera, extraer en widgets.
- Separar lógica de Firestore en `services/`, **nunca** hacer queries directo dentro de un widget o provider.
- Nombres de variables y comentarios en **español**. Nombres de clases/métodos en inglés solo si es convención técnica de Flutter/Dart.

### Soft-delete obligatorio
- Los campos `activa`, `disponible`, `activo` se usan para ocultar/mostrar. **Nunca borrar un documento como primera opción.**
- Borrado físico solo cuando el usuario lo confirma explícitamente con un `AlertDialog`.
- Texto del diálogo estándar: *"¿Estás seguro? Esta acción no se puede deshacer."* con botones "Cancelar" y "Eliminar".

### Manejo de estados en escrituras a Firestore

Cada pantalla o widget que escribe a Firestore debe manejar **3 estados**:

```dart
// ✅ Correcto
setState(() => _cargando = true);
try {
  await firestoreService.guardarProducto(producto);
  if (mounted) mostrarSnackbarExito(context, 'Producto guardado');
} catch (e) {
  if (mounted) mostrarSnackbarError(context, 'Error al guardar: $e');
} finally {
  if (mounted) setState(() => _cargando = false);
}

// ❌ Incorrecto — sin loading, sin error
await firestoreService.guardarProducto(producto);
```

- No dejar `catch` vacíos ni con solo un `print()`.
- Verificar `mounted` antes de llamar a `setState` o `context` dentro de callbacks async.

### Precio — recordatorio de implementación

```dart
// ❌ Nunca
double precio = 12.50;
firestore.set({'precio': precio});

// ✅ Siempre
int precioEnCentavos = 1250; // $12.50
firestore.set({'precioEnCentavos': precioEnCentavos});

// Para mostrar en UI
Text(formatPrecio(producto.precioEnCentavos)); // → "$12.50"
```

---

## 10. Comportamiento offline

Firebase Firestore tiene caché local habilitada por defecto en mobile. En web **no está habilitada** por defecto.

### Decisión para este proyecto

| Target | Caché offline | Razón |
|---|---|---|
| Android | ✅ Habilitada (default) | El cliente puede perder señal en el local |
| Web CRM | ❌ Sin caché | El dueño opera siempre con conexión |
| Menú público web | ❌ Sin caché en MVP | Mejora futura si hay feedback de locales con WiFi malo |

> Si se cambia esta decisión, actualizar este archivo primero.

---

## 11. Pantallas del MVP (orden de implementación)

> No saltar pasos. Cada feature depende del anterior.

```
[1] Auth
    └── login, registro, recuperar contraseña

[2] Menu Grid (dashboard)
    └── bienvenida + accesos a Categoría / Producto / QR

[3] CRUD Categorías
    └── crear, editar, listar, activar/desactivar

[4] Lista de productos agrupada por categoría
    └── toggle disponible, reordenamiento
    ↑ el paso [5] depende de que esto esté andando

[5] Crear/editar producto
    └── formulario + subida de foto a Storage (con compresión)

[6] Pantalla QR
    └── generar QR, descargar imagen, copiar link, compartir

[7] Menú público
    └── vista solo lectura para el cliente final, sin auth
    └── footer con link de registro al producto (no eliminar)
```

---

## 12. Testing

No se exige cobertura total en el MVP, pero sí una base mínima que evite regresiones críticas.

### Unit tests obligatorios
- `lib/utils/formato.dart` → `formatPrecio()`: casos borde (0, negativos, valores grandes).
- `lib/models/producto.dart` → `fromDoc()` y `toJson()`: parsing correcto desde/hacia Firestore.
- `lib/models/categoria.dart` → ídem.

### Widget tests recomendados (no bloqueantes para el MVP)
- `login_screen.dart`: que el formulario muestre error cuando los campos están vacíos.
- `editar_producto_screen.dart`: que el campo de precio rechace letras.

### Comandos
```bash
flutter test                 # todos los tests
flutter test test/utils/     # solo utils
flutter test --coverage      # con reporte de cobertura
```

> El agente no debe romper tests existentes al generar código nuevo. Si una feature nueva requiere cambiar un test existente, avisar antes.

---

## 13. Cómo trabajar con el agente

- **Review-driven**: mostrar el plan antes de ejecutar cambios grandes. Pedir aprobación para cada comando de terminal con efecto secundario.
- **Feature por feature**: una pantalla o feature a la vez. No generar toda la app de una.
- **Antes de crear**: si vas a agregar una colección, campo, regla, índice o dependencia que no está en este archivo, avisar antes.
- **Simplicidad sobre abstracción**: código simple y legible. Es un proyecto en etapa MVP.
- **Resumen al terminar**: al cerrar cada feature, dejar un resumen corto de qué se creó/modificó y qué archivos se tocaron.
- **No asumir layout**: si un widget tiene comportamiento distinto en web vs Android, preguntar antes de asumir.

---

## 14. Fuera de alcance (por ahora)

| Feature | Motivo |
|---|---|
| Sistema de pedidos desde la mesa | Futura versión — mantener `categoriaId`/`productoId` como IDs simples sin acoplar |
| Lógica de planes free/pro | Los campos existen en el modelo pero sin lógica en el MVP |
| Multi-idioma (i18n) | Fuera de scope |
| Pagos online | Fuera de scope |
| Analytics de escaneos QR | Fuera de scope — pero no borrar el footer del menú público |
| Notificaciones push | Fuera de scope |
| Dominio personalizado por local | Fuera de scope |

---

## 15. Checklist antes de hacer un PR o commit importante

- [ ] ¿El modelo de datos modificado está actualizado en este archivo?
- [ ] ¿Las reglas de Firestore modificadas tienen aprobación explícita?
- [ ] ¿Los índices compuestos nuevos están documentados en la sección 6?
- [ ] ¿Cada escritura a Firestore maneja loading + error + éxito?
- [ ] ¿Las imágenes se comprimen antes del upload?
- [ ] ¿El precio se guarda como entero en centavos (`precioEnCentavos`)?
- [ ] ¿Los tests unitarios de utils y models siguen pasando?
- [ ] ¿Se verificó `mounted` antes de usar `context` en callbacks async?
