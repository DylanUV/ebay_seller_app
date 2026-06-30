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
          'q': '*',
          'filter': 'sellers:{$sellerUsername}',
          'sort': sort.browseApiValue,
          'limit': limit,
          'offset': offset,
          'fieldgroups': 'EXTENDED',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final total = data['total'] as int? ?? 0;
      final items = (data['itemSummaries'] as List?) ?? [];

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
      throw EbayApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is EbayApiException) rethrow;
      throw EbayApiException('Unexpected error: $e');
    }
  }
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
