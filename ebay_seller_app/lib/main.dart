import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/cache/cache_service.dart';
import 'features/listings/screens/listings_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode for optimal table layout on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar style (transparent + light icons on dark bg)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize local cache
  await CacheService.init();

  runApp(
    // ProviderScope is the root of Riverpod state
    const ProviderScope(child: EbaySellerApp()),
  );
}

class EbaySellerApp extends StatelessWidget {
  const EbaySellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eBay Listings',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ListingsScreen(),
    );
  }
}
