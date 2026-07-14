import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Se muestra cuando no hay publicaciones activas (o los filtros no
/// devuelven resultados).
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
