import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/listing.dart';

/// eBay Browse API client with OAuth Client Credentials.
/// Docs: https://developer.ebay.com/api-docs/buy/browse/overview.html
class EbayApiClient {
  /// URL del backend. Por defecto usa el backend "oficial", pero se puede
  /// sobrescribir al compilar/correr con:
  ///   flutter run --dart-define=API_URL=https://tu-backend.onrender.com/
  static const _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ebay-back.kaerdos.dev/',
  );
  late final Dio _dio;

  EbayApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  // ── Browse API: search by seller ─────────────────────────────────────────

  /// Fetch all active listings for a seller username.
  Future<List<EbayListing>> getAllSellerListings({
    required String sellerUsername,
    ListingSort sort = ListingSort.endingSoon,
  }) async {
    const limit = 200; // Browse API max per page

    final first = await _fetchPage(
      sellerUsername: sellerUsername,
      sort: sort,
      limit: limit,
      offset: 0,
    );

    if (first.total <= limit) return first.listings;

    // 2. El resto de páginas, todas en paralelo
    final remainingOffsets = [
      for (int o = limit; o < first.total; o += limit) o,
    ];

    final results = await Future.wait(
      remainingOffsets.map(
        (offset) => _fetchPage(
          sellerUsername: sellerUsername,
          sort: sort,
          limit: limit,
          offset: offset,
        ),
      ),
    );

    return [...first.listings, for (final r in results) ...r.listings];
  }

  Future<_BrowsePageResult> _fetchPage({
    required String sellerUsername,
    required ListingSort sort,
    required int limit,
    required int offset,
  }) async {
    try {
      final response = await _dio.get(
        '/listings',
        queryParameters: {
          'seller': sellerUsername,
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
      if (kDebugMode && items.isNotEmpty) {
        _printJsonSafely(items.first as Map<String, dynamic>);
      }
      // ── FIN TEMP DEBUG ────────────────────────────────────────────────

      final listings = items
          .map((item) => EbayListing.fromBrowseApiJson(item))
          .where((l) => !l.isEnded)
          .toList();

      return _BrowsePageResult(listings: listings, total: total);
    } on DioException catch (e) {
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
