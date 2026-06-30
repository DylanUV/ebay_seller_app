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

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isAuction => listingType == 'Auction';

  bool get isEnded =>
      auctionEndTime != null && auctionEndTime!.isBefore(DateTime.now());

  Duration get timeRemaining {
    if (auctionEndTime == null) return Duration.zero;
    final diff = auctionEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get endingSoon => timeRemaining.inHours < 2 && !isEnded;

  String get shortUrl => 'https://ebay.com/itm/$itemId';

  // ── Factory: Browse API JSON ──────────────────────────────────────────────

  factory EbayListing.fromBrowseApiJson(Map<String, dynamic> json) {
    // Price
    final priceMap = json['price'] as Map<String, dynamic>? ?? {};
    final price = double.tryParse(priceMap['value']?.toString() ?? '0') ?? 0.0;
    final currency = priceMap['currency']?.toString() ?? 'USD';

    // Images — Browse API returns thumbnailImages and additionalImages
    final images = <String>[];
    final thumbnail = json['thumbnailImages'] as List?;
    final additional = json['additionalImages'] as List?;

    if (thumbnail != null) {
      for (final img in thumbnail) {
        final url = img['imageUrl']?.toString();
        if (url != null && url.isNotEmpty) images.add(url);
      }
    }
    if (additional != null) {
      for (final img in additional) {
        final url = img['imageUrl']?.toString();
        if (url != null && url.isNotEmpty && !images.contains(url)) {
          images.add(url);
        }
      }
    }
    // Fallback to image field
    if (images.isEmpty) {
      final fallback = (json['image'] as Map<String, dynamic>?)?['imageUrl'];
      if (fallback != null) images.add(fallback.toString());
    }

    // Auction end time
    DateTime? endTime;
    final endTimeStr = json['itemEndDate']?.toString();
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      endTime = DateTime.tryParse(endTimeStr);
    }

    // Listing type
    final buyingOptions = (json['buyingOptions'] as List?) ?? [];
    String listingType = 'FixedPrice';
    if (buyingOptions.contains('AUCTION')) {
      listingType = 'Auction';
    } else if (buyingOptions.contains('BEST_OFFER')) {
      listingType = 'BestOffer';
    }

    // Bids
    final bidCount = json['bidCount'] as int?;

    // Shipping
    String? shippingCost;
    final shippingOptions = json['shippingOptions'] as List?;
    if (shippingOptions != null && shippingOptions.isNotEmpty) {
      final firstShip = shippingOptions.first as Map<String, dynamic>;
      final shipCostMap = firstShip['shippingCost'] as Map<String, dynamic>?;
      if (shipCostMap != null) {
        final cost = double.tryParse(shipCostMap['value']?.toString() ?? '');
        shippingCost = cost == 0 ? 'Free' : '\$${cost?.toStringAsFixed(2)}';
      }
    }

    // Condition
    final condition = json['condition']?.toString();

    // URL
    final itemUrl =
        json['itemWebUrl']?.toString() ??
        'https://ebay.com/itm/${json['itemId']}';

    return EbayListing(
      itemId: json['itemId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: price,
      currency: currency,
      imageUrls: images,
      auctionEndTime: endTime,
      listingUrl: itemUrl,
      listingType: listingType,
      bidCount: bidCount,
      fetchedAt: DateTime.now(),
      condition: condition,
      shippingCost: shippingCost,
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

// ── Sort enum ─────────────────────────────────────────────────────────────────

enum ListingSort {
  endingSoon('Ending Soon', 'endTimeSoonest'),
  endingLast('Ending Last', 'endTimeFarthest'),
  priceAsc('Price: Low to High', 'price'),
  priceDesc('Price: High to Low', '-price');

  final String label;
  final String browseApiValue;
  const ListingSort(this.label, this.browseApiValue);
}
