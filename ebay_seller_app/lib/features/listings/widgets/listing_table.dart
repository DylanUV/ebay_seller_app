import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../shared/theme/app_theme.dart';
import 'countdown_widget.dart';
import 'image_carousel.dart';

// ── Column widths (fixed for performance — no layout recalculations) ──────────
const double _colTime   = 76;
const double _colPrice  = 72;
const double _colImg    = 64;
const double _colLink   = 48;
const double _rowHeight = 68;
const double _headerH   = 32;

class ListingsTable extends StatelessWidget {
  final List<EbayListing> listings;

  const ListingsTable({super.key, required this.listings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TableHeader(),
        Expanded(
          child: ListView.builder(
            // Disable scroll physics bounce on Android for performance
            physics: const ClampingScrollPhysics(),
            itemCount: listings.length,
            itemExtent: _rowHeight, // fixed height = massive perf boost
            itemBuilder: (ctx, i) {
              final listing = listings[i];
              return _ListingRow(
                listing: listing,
                isEven: i.isEven,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerH,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell('TIME LEFT',  _colTime),
          _vDivider(),
          _HeaderCell('PRICE',      _colPrice),
          _vDivider(),
          _HeaderCell('PHOTOS',     _colImg, center: true),
          _vDivider(),
          _HeaderCell('LINK',       _colLink, center: true),
          // Title column fills remaining space
          _vDivider(),
          const Expanded(child: _HeaderCell('TITLE', double.infinity)),
        ],
      ),
    );
  }

  Widget _vDivider() => const SizedBox(
    width: 1,
    height: double.infinity,
    child: ColoredBox(color: AppTheme.divider),
  );
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final bool center;

  const _HeaderCell(this.label, this.width, {this.center = false});

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppTheme.textMuted,
      ),
    );
    if (width == double.infinity) {
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: child,
      );
    }
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }
}

// ── Row ───────────────────────────────────────────────────────────────────────

class _ListingRow extends StatelessWidget {
  final EbayListing listing;
  final bool isEven;

  const _ListingRow({required this.listing, required this.isEven});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: isEven ? AppTheme.background : AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Col 1: Time remaining ────────────────────────────────────────
          SizedBox(
            width: _colTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: listing.isAuction
                  ? CountdownWidget(
                      initialDuration: listing.timeRemaining,
                      endingSoon: listing.endingSoon,
                    )
                  : StaticListingTypeBadge(listingType: listing.listingType),
            ),
          ),
          _vDivider(),

          // ── Col 2: Price ─────────────────────────────────────────────────
          SizedBox(
            width: _colPrice,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPrice(listing.price, listing.currency),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentWarm,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (listing.shippingCost != null)
                    Text(
                      '+ ${listing.shippingCost} ship',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (listing.bidCount != null && listing.bidCount! > 0)
                    Text(
                      '${listing.bidCount} bid${listing.bidCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _vDivider(),

          // ── Col 3: Images ────────────────────────────────────────────────
          SizedBox(
            width: _colImg,
            child: Center(
              child: ListingImageThumb(imageUrls: listing.imageUrls),
            ),
          ),
          _vDivider(),

          // ── Col 4: Link ──────────────────────────────────────────────────
          SizedBox(
            width: _colLink,
            child: Center(
              child: _LinkButton(listing: listing),
            ),
          ),
          _vDivider(),

          // ── Col 5: Title (fills remaining) ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (listing.condition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        listing.condition!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => const SizedBox(
    width: 1,
    height: double.infinity,
    child: ColoredBox(color: AppTheme.divider),
  );

  String _formatPrice(double price, String currency) {
    final symbol = currency == 'USD'
        ? '\$'
        : currency == 'EUR'
            ? '€'
            : currency == 'GBP'
                ? '£'
                : '$currency ';
    return '$symbol${price.toStringAsFixed(2)}';
  }
}

// ── Link button ───────────────────────────────────────────────────────────────

class _LinkButton extends StatelessWidget {
  final EbayListing listing;

  const _LinkButton({required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launch(listing.shortUrl),
      onLongPress: () => _copy(context, listing.shortUrl),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.open_in_new_rounded,
          color: AppTheme.accent,
          size: 16,
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copy(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class EmptyListingsState extends StatelessWidget {
  final String? message;

  const EmptyListingsState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No active listings found',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
