/// Convierte una URL de imagen de eBay (ej. https://i.ebayimg.com/...)
/// en una URL que apunta a nuestro propio backend, el cual descarga la
/// imagen del lado del servidor y la reenvía.
///
/// Esto evita inconsistencias al pedir la imagen directo a eBay desde el
/// navegador (bloqueos de terceros, modo incógnito, extensiones, etc.),
/// porque ahora la imagen "viene" del mismo dominio que el resto de la app.
///
/// Usa la misma URL base configurable que [EbayApiClient]:
///   flutter run --dart-define=API_URL=https://tu-backend.onrender.com/
class ImageProxy {
  static const _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ebay-back.kaerdos.dev/',
  );

  /// Si [originalUrl] es nula/vacía la devuelve tal cual (para no romper
  /// los placeholders/errorWidget de CachedNetworkImage).
  static String proxied(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    final encoded = Uri.encodeQueryComponent(originalUrl);
    return '${_apiUrl}image-proxy?url=$encoded';
  }
}
