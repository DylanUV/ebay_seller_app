import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime? lastUpdated;

  const OfflineBanner({super.key, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceAlt,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: AppTheme.accentWarm,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastUpdated != null
                  ? 'Offline · Last updated ${_timeAgo(lastUpdated!)}'
                  : 'No internet · Showing cached data',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.accentWarm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
