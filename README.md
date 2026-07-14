# eBay Seller Listings App

App Flutter (Android / iOS / Web) para visualizar en vivo las publicaciones
activas de un vendedor de eBay, en tarjetas con filtros y cuenta regresiva
para subastas.

---

## Arquitectura

```
┌─────────────┐      HTTPS       ┌──────────────────────┐      HTTPS      ┌──────────┐
│  Flutter App │ ───────────────▶│  Backend (Go, propio) │───────────────▶│  eBay API │
│ (móvil / web)│  GET /listings   │  ebay-back.kaerdos.dev│  OAuth + Browse │           │
└─────────────┘                  └──────────────────────┘                 └──────────┘
```

La app **nunca** habla directo con eBay. Le pide los listings a nuestro
propio backend (repo `ebay_seller_backend`), que guarda el Client ID/Secret
de eBay y hace el OAuth por su cuenta. Así el secret nunca viaja al
dispositivo del usuario ni queda expuesto en un build web.

---

## Características

- **Tarjetas por publicación**: imagen, precio, tiempo restante, link
- **Visor de imágenes**: tap abre pantalla completa con carrusel deslizable
- **Cuenta regresiva en vivo** para subastas (se actualiza cada segundo)
- **Filtros de orden**: termina antes/después, precio mayor/menor
- **Modo offline**: muestra caché de la última sesión si no hay internet
- **Cache de 30 min**: abre instantáneo sin esperar la API

---

## Setup paso a paso

### 1. Levantar el backend

El backend vive en un repo aparte (`ebay_seller_backend`, Go + Gin). Necesita
sus propias variables (`EBAY_CLIENT_ID`, `EBAY_CLIENT_SECRET`,
`DEFAULT_SELLER_USERNAME`, `PORT`) corriendo en el server o en Docker.
Sacá el Client ID/Secret desde [developer.ebay.com](https://developer.ebay.com)
→ **My Account → Application Keys** → app en modo **Production**.

> La app Flutter **no necesita** el Client ID/Secret de eBay en ningún
> momento — eso vive únicamente en el backend.

### 2. Configurar la app Flutter

Creá un archivo `.env` en la raíz del proyecto (no se commitea, está en
`.gitignore`):

```
EBAY_SELLER_USERNAME=nombre-del-vendedor
```

Es el username de eBay del vendedor, el mismo que aparece en sus
publicaciones. Si necesitás apuntar a otra URL de backend (por ejemplo local
en desarrollo), cambiá `_apiUrl` en `lib/core/api/ebay_api_client.dart`.

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
# Android/iOS
flutter run --release

# Web
flutter run -d chrome --release
```

Usa `--release` para probar el rendimiento real (modo debug es ~3x más lento).

---

## Estructura del proyecto

```
lib/
├── main.dart                              # Entry point
├── core/
│   ├── api/
│   │   └── ebay_api_client.dart           # Cliente HTTP hacia nuestro backend
│   ├── cache/
│   │   └── cache_service.dart             # Persistencia local con Hive
│   ├── models/
│   │   ├── listing.dart                   # Modelo EbayListing + enums
│   │   └── listing.g.dart                 # Generado por build_runner
│   └── utils/
│       └── app_config.dart                # Config general (seller username)
├── features/
│   └── listings/
│       ├── providers/
│       │   └── listings_provider.dart     # Estado con Riverpod
│       ├── screens/
│       │   └── listings_screen.dart       # Pantalla principal
│       └── widgets/
│           ├── listing_cards.dart         # Tarjetas de publicaciones
│           ├── empty_listings_state.dart  # Estado vacío / sin resultados
│           ├── image_carousel.dart        # Visor de imágenes
│           ├── countdown_widget.dart      # Temporizador en vivo
│           ├── filter_sheet.dart          # Bottom sheet filtros
│           └── offline_banner.dart        # Banner sin internet
└── shared/
    └── theme/
        └── app_theme.dart                 # Paleta y tipografía
```

---

## Límites de la eBay Browse API

| Límite | Valor |
|--------|-------|
| Ítems por página | 200 (máximo permitido) |
| Rate limit típico (app Production) | 5,000 llamadas/día |

Con el caché de 30 min configurado, una sesión típica consume muy pocas
llamadas. La app pagina automáticamente hasta traer todos los listings
activos del vendedor (típicamente ~300, en varias páginas en paralelo).

---

## Seguridad: qué va en `.env` y qué no

- **Nunca** agregues `EBAY_CLIENT_ID` ni `EBAY_CLIENT_SECRET` al `.env` de
  esta app. Como `.env` se empaqueta como *asset* de Flutter, terminaría
  legible dentro del build (y en la web, servido como archivo público).
- Esas credenciales viven **solo** en el backend, que corre en un servidor
  que controlamos y nunca expone su código ni sus variables al cliente.
- Lo único que necesita este `.env` es `EBAY_SELLER_USERNAME`, que no es un
  dato sensible.

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
El sistema está preparado para múltiples vendedores. El caché guarda por
`sellerUsername`, así que solo necesitas instanciar otro `ListingsNotifier`
con un username diferente.

---

## Build para producción

```bash
# Android (3 APKs optimizados por arquitectura)
flutter build apk --release --split-per-abi

# Web
flutter build web --release
```

El APK arm64 pesa aproximadamente **13-16 MB**.
