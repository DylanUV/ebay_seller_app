import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/listing.dart';
import '../../../shared/theme/app_theme.dart';
import 'countdown_widget.dart';
import 'image_carousel.dart';

/// Lista de tarjetas — reemplaza el layout de tabla.
/// Cada tarjeta muestra: imagen grande, título, precio destacado,
/// tiempo restante y acciones (abrir / compartir).
class ListingsCards extends StatelessWidget {
  final List<EbayListing> listings;

  const ListingsCards({super.key, required this.listings});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      physics: const ClampingScrollPhysics(),
      itemCount: listings.length,
      itemBuilder: (ctx, i) => _ListingCard(listing: listings[i]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final EbayListing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    // Tarjeta "caliente": subasta terminando pronto o con varias pujas.
    final isHot =
        listing.isAuction &&
        (listing.endingSoon || (listing.bidCount ?? 0) >= 5);

    // Tarjeta "fría": subasta con 0 o 1 bids (poco interés hasta ahora).
    final isCold = listing.isAuction && !isHot && (listing.bidCount ?? 0) <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Imagen: llena todo el alto de la tarjeta ────────────────
                SizedBox(
                  width: 100,
                  child: ListingImageThumb(imageUrls: listing.imageUrls),
                ),

                // ── Contenido ────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Precio + envío + tiempo restante en una fila
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _formatPrice(listing.price, listing.currency),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentWarm,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (listing.shippingCost != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '+ ${listing.shippingCost} ship',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                            const Spacer(),
                            listing.isAuction
                                ? CountdownWidget(
                                    initialDuration: listing.timeRemaining,
                                    endingSoon: listing.endingSoon,
                                  )
                                : StaticListingTypeBadge(
                                    listingType: listing.listingType,
                                  ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Bids (si aplica)
                        if (listing.bidCount != null && listing.bidCount! > 0)
                          Text(
                            '${listing.bidCount} bid${listing.bidCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Acciones
                        Row(
                          children: [
                            _ActionChip(
                              icon: Icons.open_in_new_rounded,
                              label: 'View',
                              color: AppTheme.accent,
                              onTap: () => _launch(listing.listingUrl),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              color: AppTheme.textMuted,
                              onTap: () => _share(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Badge de fuego (subasta caliente) ─────────────────────────
          if (isHot)
            Positioned(bottom: 6, right: 6, child: _StatusBadge(emoji: '🔥')),

          // ── Badge de frío (subasta con 0-1 bids) ───────────────────────
          if (isCold)
            Positioned(bottom: 6, right: 6, child: _StatusBadge(emoji: '❄️')),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(text: '${listing.title}\n${listing.listingUrl}'),
    );
  }

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

// ── Badge de estado (fuego / frío) ──────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String emoji;

  const _StatusBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ── Chip de acción reutilizable ─────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
