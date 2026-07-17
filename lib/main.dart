import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/cache/cache_service.dart';
import 'features/listings/screens/listings_screen.dart';
import 'shared/theme/app_theme.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Force portrait + landscape support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize local cache
  await CacheService.init();

  runApp(const ProviderScope(child: EbaySellerApp()));
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
