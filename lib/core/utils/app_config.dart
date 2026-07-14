import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central app configuration — reads from .env file.
/// Never hardcode credentials here.
class AppConfig {
  // ── Seller to track ───────────────────────────────────────────────────────
  static String get defaultSellerUsername =>
      dotenv.env['EBAY_SELLER_USERNAME'] ?? '';

  // ── Behaviour ─────────────────────────────────────────────────────────────
  /// Items per page for Browse API (max 200)
  static const int itemsPerPage = 200;

  /// Cache TTL
  static const Duration foregroundRefreshInterval = Duration(minutes: 15);
}
