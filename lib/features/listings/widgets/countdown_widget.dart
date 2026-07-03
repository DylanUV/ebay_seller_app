import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class CountdownWidget extends StatefulWidget {
  final Duration initialDuration;
  final bool endingSoon;

  const CountdownWidget({
    super.key,
    required this.initialDuration,
    required this.endingSoon,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialDuration;
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = _remaining > const Duration(seconds: 1)
              ? _remaining - const Duration(seconds: 1)
              : Duration.zero;
        });
        if (_remaining == Duration.zero) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const Text(
        'Ended',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final color = widget.endingSoon ? AppTheme.danger : AppTheme.textPrimary;
    final formatted = _format(_remaining);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.endingSoon)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(Icons.timer_outlined, size: 10, color: color),
          ),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    if (d.inDays >= 1) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      return '${days}d ${hours}h';
    } else if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return '${h}h ${m}m';
    } else if (d.inMinutes >= 1) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    } else {
      final s = d.inSeconds;
      return '${s}s';
    }
  }
}

/// For Fixed Price listings (no countdown)
class StaticListingTypeBadge extends StatelessWidget {
  final String listingType;

  const StaticListingTypeBadge({super.key, required this.listingType});

  @override
  Widget build(BuildContext context) {
    final label = switch (listingType) {
      'FixedPrice' => 'Buy It Now',
      'BestOffer' => 'Best Offer',
      'StoreInventory' => 'Store',
      _ => listingType,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
