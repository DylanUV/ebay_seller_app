/// Converts an eBay image URL (e.g. https://i.ebayimg.com/...) into a URL
/// that points to our own backend, which fetches the image server-side and
/// forwards it.
///
/// This avoids inconsistencies when requesting the image directly from eBay
/// in the browser (third-party blocking, incognito mode, extensions, etc.),
/// because now the image "comes from" the same domain as the rest of the app.
///
/// Uses the same configurable base URL as [EbayApiClient]:
///   flutter run --dart-define=API_URL=https://your-backend.onrender.com/
class ImageProxy {
  static const _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ebay-back.kaerdos.dev/',
  );

  /// If [originalUrl] is null/empty, returns it as-is (so we don't break
  /// CachedNetworkImage's placeholders/errorWidget).
  static String proxied(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    final encoded = Uri.encodeQueryComponent(originalUrl);
    return '${_apiUrl}image-proxy?url=$encoded';
  }
}
