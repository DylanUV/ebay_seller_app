import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/models/listing.dart';
import '../../../core/utils/app_config.dart';
import '../providers/listings_provider.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/listing_cards.dart';
import '../widgets/empty_listings_state.dart';
import '../widgets/offline_banner.dart';

class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(listingsProvider);
    final sort = ref.watch(sortProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'eBay Listings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '@${AppConfig.defaultSellerUsername}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          // Item count badge
          if (state.listings.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.listings.length} items',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Filter button
          IconButton(
            onPressed: () => FilterSheet.show(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                // Dot when non-default sort is active
                if (sort != ListingSort.endingSoon)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Sort & Filter',
          ),

          // Refresh button
          IconButton(
            onPressed: state.isRefreshing
                ? null
                : () => ref.read(listingsProvider.notifier).refresh(sort: sort),
            icon: state.isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
            tooltip: 'Refresh',
          ),

          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Offline banner ─────────────────────────────────────────────────
          if (state.isOffline) OfflineBanner(lastUpdated: state.lastUpdated),

          // ── Error banner ───────────────────────────────────────────────────
          if (state.error != null)
            _ErrorBanner(
              message: state.error!,
              onRetry: () =>
                  ref.read(listingsProvider.notifier).refresh(sort: sort),
            ),

          // ── Last updated bar ───────────────────────────────────────────────
          if (state.lastUpdated != null && !state.isOffline)
            _LastUpdatedBar(updatedAt: state.lastUpdated!),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(child: _buildContent(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ListingsState state,
  ) {
    // Initial loading (no cache available)
    if (state.isLoading && state.listings.isEmpty) {
      return const _LoadingState();
    }

    // Empty
    if (state.listings.isEmpty && !state.isLoading) {
      return EmptyListingsState(
        message: state.error != null
            ? 'Could not load listings.\nCheck your App ID and seller username.'
            : 'No active listings for @${AppConfig.defaultSellerUsername}',
      );
    }

    // Table
    return RefreshIndicator(
      onRefresh: () => ref
          .read(listingsProvider.notifier)
          .refresh(sort: ref.read(sortProvider)),
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceAlt,
      child: ListingsCards(listings: _applyHeatFilter(state.listings, ref)),
    );
  }

  List<EbayListing> _applyHeatFilter(
    List<EbayListing> listings,
    WidgetRef ref,
  ) {
    final filter = ref.watch(heatFilterProvider);
    if (filter == HeatFilter.all) return listings;

    return listings.where((l) {
      if (!l.isAuction) return false;
      final bids = l.bidCount ?? 0;
      return switch (filter) {
        HeatFilter.hot => bids >= 5,
        HeatFilter.warm => bids >= 2 && bids <= 4,
        HeatFilter.cold => bids <= 1,
        HeatFilter.all => true,
      };
    }).toList();
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Loading listings…',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.danger.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 14,
            color: AppTheme.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedBar extends StatelessWidget {
  final DateTime updatedAt;

  const _LastUpdatedBar({required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(updatedAt);
    final label = diff.inMinutes < 1
        ? 'Updated just now'
        : diff.inMinutes < 60
        ? 'Updated ${diff.inMinutes}m ago'
        : 'Updated ${diff.inHours}h ago';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: AppTheme.surfaceAlt,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
      ),
    );
  }
}
