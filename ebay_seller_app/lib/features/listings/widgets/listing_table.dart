import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../shared/theme/app_theme.dart';
import 'countdown_widget.dart';
import 'image_carousel.dart';

// ── Row height (fixed for performance — no layout recalculations) ─────────────
const double _rowHeight = 68;
const double _headerH = 32;

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
              return _ListingRow(listing: listing, isEven: i.isEven);
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
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('TIME LEFT', center: true)),
          _vDivider(),
          Expanded(flex: 2, child: _HeaderCell('PRICE', center: true)),
          _vDivider(),
          Expanded(flex: 2, child: _HeaderCell('PHOTOS', center: true)),
          _vDivider(),
          Expanded(flex: 1, child: _HeaderCell('LINK', center: true)),
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
  final bool center;

  const _HeaderCell(this.label, {this.center = false});

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
    return Center(child: child);
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
          Expanded(
            flex: 2,
            child: Center(
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
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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

          // ── Col 3: Images (más grande, ocupa espacio extra) ────────────────
          Expanded(
            flex: 2,
            child: Center(
              child: ListingImageThumb(imageUrls: listing.imageUrls),
            ),
          ),
          _vDivider(),

          // ── Col 4: Link (pequeña, solo el ícono) ───────────────────────────
          Expanded(
            flex: 1,
            child: Center(child: _LinkButton(listing: listing)),
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
      onTap: () => _launch(listing.listingUrl),
      onLongPress: () => _copy(context, listing.listingUrl),
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
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
