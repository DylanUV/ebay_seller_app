# eBay Seller Listings App

App móvil Flutter para visualizar las publicaciones activas de un vendedor de eBay en formato tabla optimizado.

---

## Características

- **Tabla con 4 columnas**: tiempo restante, precio, imágenes, link
- **Visor de imágenes**: tap abre pantalla completa con carrusel deslizable
- **Cuenta regresiva en vivo** para subastas (se actualiza cada segundo)
- **4 filtros de orden**: termina antes/después, precio mayor/menor
- **Modo offline**: muestra caché de la última sesión si no hay internet
- **Cache de 30 min**: abre instantáneo sin esperar la API

---

## Setup paso a paso

### 1. Obtener credenciales de eBay

1. Ve a [developer.ebay.com](https://developer.ebay.com) y crea una cuenta
2. En el dashboard, ve a **My Account → Application Keys**
3. Crea una nueva app → selecciona **Production**
4. Copia tu **App ID (Client ID)** — es el único que necesitas para la Finding API

> ⚠️ La Finding API es **gratuita** y no requiere OAuth para consultas públicas de listings.

### 2. Configurar la app

Abre `lib/core/utils/app_config.dart` y reemplaza los valores:

```dart
static const String ebayAppId = 'TuNombre-TuApp-PRD-xxxxxxx-xxxxxxxx';
static const String defaultSellerUsername = 'nombre-del-vendedor';
```

El `sellerUsername` es el nombre de usuario de eBay del vendedor, el mismo que aparece en sus publicaciones.

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Generar código Hive (adaptadores de caché)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Correr la app

```bash
# En un dispositivo Android conectado o emulador
flutter run --release
```

Usa `--release` para probar el rendimiento real (modo debug es ~3x más lento).

---

## Estructura del proyecto

```
lib/
├── main.dart                          # Entry point
├── core/
│   ├── api/
│   │   └── ebay_api_client.dart       # Cliente eBay Finding API
│   ├── cache/
│   │   └── cache_service.dart         # Persistencia local con Hive
│   ├── models/
│   │   ├── listing.dart               # Modelo EbayListing + enums
│   │   └── listing.g.dart             # Generado por build_runner
│   └── utils/
│       └── app_config.dart            # ← EDITAR AQUÍ tus credenciales
├── features/
│   └── listings/
│       ├── providers/
│       │   └── listings_provider.dart # Estado con Riverpod
│       ├── screens/
│       │   └── listings_screen.dart   # Pantalla principal
│       └── widgets/
│           ├── listing_table.dart     # Tabla principal
│           ├── image_carousel.dart    # Visor de imágenes
│           ├── countdown_widget.dart  # Temporizador en vivo
│           ├── filter_sheet.dart      # Bottom sheet filtros
│           └── offline_banner.dart    # Banner sin internet
└── shared/
    └── theme/
        └── app_theme.dart             # Paleta y tipografía
```

---

## Límites de la eBay Finding API (plan gratuito)

| Límite | Valor |
|--------|-------|
| Llamadas por día | 5,000 |
| Ítems por página | 100 |
| Páginas máximas | 100 |
| Ítems máximos por búsqueda | 10,000 |

Con el caché de 30 min configurado, una sesión típica consume ~2-5 llamadas. No llegarás al límite con uso normal.

---

## Personalización rápida

### Cambiar duración del caché
En `lib/core/cache/cache_service.dart`:
```dart
static const cacheTTL = Duration(minutes: 30); // ← cambiar aquí
```

### Cambiar colores
En `lib/shared/theme/app_theme.dart` están todos los tokens de color.

### Agregar más vendedores
El sistema está preparado para múltiples vendedores. El caché guarda por `sellerUsername`, así que solo necesitas instanciar otro `ListingsNotifier` con un username diferente.

---

## Build para producción (APK)

```bash
flutter build apk --release --split-per-abi
```

Esto genera 3 APKs optimizados por arquitectura (arm64, arm32, x86_64).
El más liviano (arm64) pesa aproximadamente **13-16 MB**.

Para instalar directamente en un dispositivo:
```bash
flutter install --release
```
