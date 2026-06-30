/// Central app configuration.
/// Replace the placeholders before running.
class AppConfig {
  // ── eBay API credentials ──────────────────────────────────────────────────
  // Get yours at: https://developer.ebay.com/my/keys
  static const String ebayAppId = 'DylanEle-Listinga-SBX-c0acd91f7-b0582c10';

  // ── Seller to track ───────────────────────────────────────────────────────
  // The eBay username/storename of the seller whose listings you want to see
  static const String defaultSellerUsername = 'ngt001';

  // ── Behaviour ─────────────────────────────────────────────────────────────
  /// How many items to load per page on incremental fetch
  static const int itemsPerPage = 50;

  /// Refresh interval when app is in foreground (optional background refresh)
  static const Duration foregroundRefreshInterval = Duration(minutes: 15);
}
