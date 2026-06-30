import 'package:hive/hive.dart';

part 'listing.g.dart';

@HiveType(typeId: 0)
class EbayListing extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final List<String> imageUrls;

  @HiveField(5)
  final DateTime? auctionEndTime;

  @HiveField(6)
  final String listingUrl;

  @HiveField(7)
  final String listingType; // 'Auction' | 'FixedPrice' | 'BestOffer'

  @HiveField(8)
  final int? bidCount;

  @HiveField(9)
  final DateTime fetchedAt;

  @HiveField(10)
  final String? condition;

  @HiveField(11)
  final String? shippingCost;

  EbayListing({
    required this.itemId,
    required this.title,
    required this.price,
    required this.currency,
    required this.imageUrls,
    this.auctionEndTime,
    required this.listingUrl,
    required this.listingType,
    this.bidCount,
    required this.fetchedAt,
    this.condition,
    this.shippingCost,
  });

  // ── Computed helpers ─────────────────────────────────────────────────────

  bool get isAuction => listingType == 'Auction';

  bool get isEnded =>
      auctionEndTime != null && auctionEndTime!.isBefore(DateTime.now());

  Duration get timeRemaining {
    if (auctionEndTime == null) return Duration.zero;
    final diff = auctionEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get endingSoon => timeRemaining.inHours < 2 && !isEnded;

  String get shortUrl {
    // eBay short URL format
    return 'https://ebay.com/itm/$itemId';
  }

  // ── Factories ────────────────────────────────────────────────────────────

  factory EbayListing.fromFindingApiJson(Map<String, dynamic> json) {
    String _s(dynamic v) => (v is List ? v.first : v)?.toString() ?? '';
    double _d(dynamic v) =>
        double.tryParse((v is List ? v.first : v)?.toString() ?? '0') ?? 0;

    final sellingStatus =
        (json['sellingStatus'] is List
            ? json['sellingStatus'].first
            : json['sellingStatus']) ??
            {};
    final listingInfo =
        (json['listingInfo'] is List
            ? json['listingInfo'].first
            : json['listingInfo']) ??
            {};
    final pictureDetails =
        (json['pictureDetails'] is List
            ? json['pictureDetails'].first
            : json['pictureDetails']) ??
            {};
    final shippingInfo =
        (json['shippingInfo'] is List
            ? json['shippingInfo'].first
            : json['shippingInfo']) ??
            {};

    final currentPrice =
        (sellingStatus['currentPrice'] is List
            ? sellingStatus['currentPrice'].first
            : sellingStatus['currentPrice']) ??
            {};
    final endTimeStr = _s(listingInfo['endTime']);

    // Collect all image URLs
    List<String> images = [];
    final pUrls = pictureDetails['pictureURL'];
    if (pUrls is List) {
      images = pUrls.map((e) => e.toString()).toList();
    } else if (pUrls is String) {
      images = [pUrls];
    }
    // Fallback gallery
    final galleryUrl = _s(json['galleryURL']);
    if (galleryUrl.isNotEmpty && !images.contains(galleryUrl)) {
      images.insert(0, galleryUrl);
    }

    // Shipping cost
    String? shipping;
    final shipCost =
        (shippingInfo['shippingServiceCost'] is List
            ? shippingInfo['shippingServiceCost'].first
            : shippingInfo['shippingServiceCost']);
    if (shipCost != null) {
      final cost = double.tryParse(shipCost['__value__']?.toString() ?? '');
      shipping = cost == 0 ? 'Free' : '\$${cost?.toStringAsFixed(2)}';
    }

    return EbayListing(
      itemId: _s(json['itemId']),
      title: _s(json['title']),
      price: _d(currentPrice['__value__']),
      currency: currentPrice['@currencyId']?.toString() ?? 'USD',
      imageUrls: images,
      auctionEndTime:
          endTimeStr.isNotEmpty ? DateTime.tryParse(endTimeStr) : null,
      listingUrl:
          _s(json['viewItemURL']).isNotEmpty
              ? _s(json['viewItemURL'])
              : 'https://ebay.com/itm/${_s(json['itemId'])}',
      listingType: _s(listingInfo['listingType']),
      bidCount: int.tryParse(_s(sellingStatus['bidCount'])),
      fetchedAt: DateTime.now(),
      condition: _s(
        (json['condition'] is List
                ? json['condition'].first
                : json['condition'])
            ?['conditionDisplayName'],
      ).isNotEmpty
          ? _s(
              (json['condition'] is List
                      ? json['condition'].first
                      : json['condition'])
                  ?['conditionDisplayName'],
            )
          : null,
      shippingCost: shipping,
    );
  }

  EbayListing copyWith({DateTime? fetchedAt}) {
    return EbayListing(
      itemId: itemId,
      title: title,
      price: price,
      currency: currency,
      imageUrls: imageUrls,
      auctionEndTime: auctionEndTime,
      listingUrl: listingUrl,
      listingType: listingType,
      bidCount: bidCount,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      condition: condition,
      shippingCost: shippingCost,
    );
  }
}

// ── Sort enum ────────────────────────────────────────────────────────────────

enum ListingSort {
  endingSoon('Ending Soon', 'EndTimeSoonest'),
  endingLast('Ending Last', 'EndTimeFarthest'),
  priceAsc('Price: Low to High', 'PricePlusShippingLowest'),
  priceDesc('Price: High to Low', 'PricePlusShippingHighest');

  final String label;
  final String apiValue;
  const ListingSort(this.label, this.apiValue);
}
