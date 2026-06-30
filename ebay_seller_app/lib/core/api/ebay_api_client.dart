import 'package:dio/dio.dart';
import '../models/listing.dart';

/// eBay Finding API client.
/// Docs: https://developer.ebay.com/devzone/finding/callref/findItemsIneBayStores.html
class EbayApiClient {
  static const _baseUrl =
      'https://svcs.ebay.com/services/search/FindingService/v1';
  static const _version = '1.0.0';

  final Dio _dio;
  final String appId; // Your eBay App ID (Client ID)

  EbayApiClient({required this.appId})
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'X-EBAY-SOA-SECURITY-APPNAME': appId,
            'X-EBAY-SOA-REQUEST-DATA-FORMAT': 'JSON',
            'X-EBAY-SOA-RESPONSE-DATA-FORMAT': 'JSON',
            'X-EBAY-SOA-SERVICE-VERSION': _version,
          },
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[eBay API] $o'),
      ),
    );
  }

  /// Fetch all active listings for a seller username.
  /// [sort] uses eBay's sortOrder values.
  /// [page] is 1-indexed, max 100 items per page.
  Future<EbaySearchResult> getSellerListings({
    required String sellerUsername,
    ListingSort sort = ListingSort.endingSoon,
    int page = 1,
    int itemsPerPage = 50,
  }) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'OPERATION-NAME': 'findItemsIneBayStores',
          'storeName': sellerUsername,
          'sortOrder': sort.apiValue,
          'paginationInput.pageNumber': page,
          'paginationInput.entriesPerPage': itemsPerPage,
          // Request all image URLs
          'outputSelector': [
            'PictureURLLarge',
            'PictureURLSuperSize',
            'SellerInfo',
            'ShippingInfo',
          ],
        },
      );

      final data = response.data;
      final searchResp = data['findItemsIneBayStoresResponse']?[0];

      if (searchResp == null) {
        throw EbayApiException('Empty response from eBay API');
      }

      final ack = searchResp['ack']?[0] ?? 'Failure';
      if (ack != 'Success' && ack != 'Warning') {
        final errMsg =
            searchResp['errorMessage']?[0]?['error']?[0]?['message']?[0] ??
            'Unknown API error';
        throw EbayApiException(errMsg);
      }

      final paginationOutput = searchResp['paginationOutput']?[0] ?? {};
      final totalItems =
          int.tryParse(
            paginationOutput['totalEntries']?[0]?.toString() ?? '0',
          ) ??
          0;
      final totalPages =
          int.tryParse(paginationOutput['totalPages']?[0]?.toString() ?? '1') ??
          1;

      final rawItems = (searchResp['searchResult']?[0]?['item'] as List?) ?? [];

      final listings = rawItems
          .map((item) => EbayListing.fromFindingApiJson(item))
          .where((l) => !l.isEnded) // filter out expired
          .toList();

      return EbaySearchResult(
        listings: listings,
        totalItems: totalItems,
        totalPages: totalPages,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw EbayApiException('Connection timed out. Check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw EbayApiException('No internet connection.');
      }
      if (e.response?.statusCode == 503) {
        throw const EbayApiException(
          'eBay is temporarily unavailable. Please try again in a moment.',
        );
      }
      throw EbayApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is EbayApiException) rethrow;
      throw EbayApiException('Unexpected error: $e');
    }
  }

  /// Fetch ALL pages for a seller (used on first load / full refresh).
  Future<List<EbayListing>> getAllSellerListings({
    required String sellerUsername,
    ListingSort sort = ListingSort.endingSoon,
  }) async {
    final firstPage = await getSellerListings(
      sellerUsername: sellerUsername,
      sort: sort,
      page: 1,
    );

    if (firstPage.totalPages <= 1) return firstPage.listings;

    // Fetch remaining pages concurrently (max 3 concurrent to be polite)
    final allListings = <EbayListing>[...firstPage.listings];
    const batchSize = 3;

    for (
      int batch = 0;
      batch < ((firstPage.totalPages - 1) / batchSize).ceil();
      batch++
    ) {
      final startPage = 2 + batch * batchSize;
      final endPage = (startPage + batchSize - 1).clamp(
        2,
        firstPage.totalPages,
      );

      final futures = List.generate(
        endPage - startPage + 1,
        (i) => getSellerListings(
          sellerUsername: sellerUsername,
          sort: sort,
          page: startPage + i,
        ),
      );

      final results = await Future.wait(futures);
      for (final result in results) {
        allListings.addAll(result.listings);
      }
    }

    return allListings;
  }
}

// ── Supporting types ──────────────────────────────────────────────────────────

class EbaySearchResult {
  final List<EbayListing> listings;
  final int totalItems;
  final int totalPages;
  final int currentPage;

  const EbaySearchResult({
    required this.listings,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
  });
}

class EbayApiException implements Exception {
  final String message;
  const EbayApiException(this.message);

  @override
  String toString() => 'EbayApiException: $message';
}

void debugPrint(String msg) {
  // ignore: avoid_print
  print(msg);
}
