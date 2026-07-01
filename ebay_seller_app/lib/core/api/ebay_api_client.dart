import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/listing.dart';

/// eBay Browse API client with OAuth Client Credentials.
/// Docs: https://developer.ebay.com/api-docs/buy/browse/overview.html
class EbayApiClient {
  static const _authUrl = 'https://api.ebay.com/identity/v1/oauth2/token';
  static const _browseUrl = 'https://api.ebay.com/buy/browse/v1';

  final String clientId;
  final String clientSecret;

  late final Dio _dio;
  late final Dio _authDio;

  String? _accessToken;
  DateTime? _tokenExpiry;

  EbayApiClient({required this.clientId, required this.clientSecret}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _browseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US',
        },
      ),
    );

    _authDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  // ── OAuth: Client Credentials flow ────────────────────────────────────────

  /// Returns a valid access token, refreshing if expired.
  Future<String> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    try {
      final response = await _authDio.post(
        _authUrl,
        data:
            'grant_type=client_credentials&scope=https%3A%2F%2Fapi.ebay.com%2Foauth%2Fapi_scope',
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      _accessToken = response.data['access_token'];
      final expiresIn = response.data['expires_in'] as int? ?? 7200;
      // Subtract 60s buffer so we refresh before actual expiry
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

      return _accessToken!;
    } on DioException catch (e) {
      throw EbayApiException(
        'Auth failed: ${e.response?.data?['error_description'] ?? e.message}',
      );
    }
  }

  // ── Browse API: search by seller ─────────────────────────────────────────

  /// Fetch all active listings for a seller username.
  Future<List<EbayListing>> getAllSellerListings({
    required String sellerUsername,
    ListingSort sort = ListingSort.endingSoon,
  }) async {
    final token = await _getToken();
    final allListings = <EbayListing>[];
    int offset = 0;
    const limit = 200; // Browse API max per page
    int? total;

    do {
      final result = await _fetchPage(
        token: token,
        sellerUsername: sellerUsername,
        sort: sort,
        limit: limit,
        offset: offset,
      );

      allListings.addAll(result.listings);
      total ??= result.total;
      offset += limit;
    } while (total != null && offset < total && allListings.length < total);

    return allListings;
  }

  Future<_BrowsePageResult> _fetchPage({
    required String token,
    required String sellerUsername,
    required ListingSort sort,
    required int limit,
    required int offset,
  }) async {
    try {
      final response = await _dio.get(
        '/item_summary/search',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: {
          // eBay's Browse API does NOT allow a '*' wildcard in `q`.
          // Workaround to fetch ALL of a seller's items regardless of
          // category: use category_ids=0 instead of a keyword search.
          'category_ids': '0',
          // Include AUCTION items too — by default Browse API only returns
          // FIXED_PRICE (Buy It Now) listings, which would hide auctions.
          'filter':
              'sellers:{$sellerUsername},buyingOptions:{AUCTION|FIXED_PRICE}',
          'sort': sort.browseApiValue,
          'limit': limit,
          'offset': offset,
          'fieldgroups': 'EXTENDED',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final total = data['total'] as int? ?? 0;
      final items = (data['itemSummaries'] as List?) ?? [];

      // ── TEMP DEBUG: imprime el JSON completo del primer item, partido en
      // líneas cortas para que logcat de Android no las trunque.
      if (items.isNotEmpty) {
        _printJsonSafely(items.first as Map<String, dynamic>);
      }
      // ── FIN TEMP DEBUG ────────────────────────────────────────────────

      final listings = items
          .map((item) => EbayListing.fromBrowseApiJson(item))
          .where((l) => !l.isEnded)
          .toList();

      return _BrowsePageResult(listings: listings, total: total);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired mid-session — clear and let caller retry
        _accessToken = null;
        throw EbayApiException('Token expired, please try again.');
      }
      if (e.response?.statusCode == 503) {
        throw const EbayApiException(
          'eBay is temporarily unavailable. Please try again in a moment.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw EbayApiException('Connection timed out. Check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw EbayApiException('No internet connection.');
      }
      // Surface eBay's specific error message (e.g. from a 400) instead of
      // Dio's generic "status code X" text, to make debugging easier.
      final ebayMessage = _extractEbayErrorMessage(e.response?.data);
      if (ebayMessage != null) {
        throw EbayApiException(
          'eBay error (${e.response?.statusCode}): $ebayMessage',
        );
      }
      throw EbayApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is EbayApiException) rethrow;
      throw EbayApiException('Unexpected error: $e');
    }
  }

  /// Parses eBay's standard error body shape:
  /// `{ "errors": [ { "message": "...", "longMessage": "..." } ] }`
  String? _extractEbayErrorMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final errors = data['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final first = errors.first as Map<String, dynamic>;
          return (first['longMessage'] ?? first['message'])?.toString();
        }
      }
    } catch (_) {
      // Fall through to null if the shape is unexpected.
    }
    return null;
  }
}

/// TEMP DEBUG: imprime un JSON completo pero troceado en líneas de máximo
/// ~800 caracteres, porque logcat de Android corta las líneas largas
/// (como pasó con el bloque que llegaba hasta "shippingOpti" y se cortaba).
void _printJsonSafely(Map<String, dynamic> json) {
  const chunkSize = 800;
  final text = const JsonEncoder.withIndent('  ').convert(json);
  print('🔍 RAW ITEM DE EBAY (${text.length} caracteres):');
  for (var i = 0; i < text.length; i += chunkSize) {
    final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
    print(text.substring(i, end));
  }
  print('🔍 FIN DEL ITEM');
}

// ── Supporting types ──────────────────────────────────────────────────────────

class _BrowsePageResult {
  final List<EbayListing> listings;
  final int total;
  const _BrowsePageResult({required this.listings, required this.total});
}

class EbayApiException implements Exception {
  final String message;
  const EbayApiException(this.message);

  @override
  String toString() => 'EbayApiException: $message';
}
