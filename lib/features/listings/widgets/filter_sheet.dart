import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/listing.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/listings_provider.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sortProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'SORT BY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),

            ...ListingSort.values.map(
              (sort) => _SortTile(
                sort: sort,
                isSelected: currentSort == sort,
                onTap: () {
                  ref.read(sortProvider.notifier).setSort(sort);
                  ref.read(listingsProvider.notifier).changeSort(sort);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final ListingSort sort;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortTile({
    required this.sort,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon => switch (sort) {
    ListingSort.endingSoon => Icons.timer_outlined,
    ListingSort.endingLast => Icons.schedule_outlined,
    ListingSort.priceAsc => Icons.arrow_upward_rounded,
    ListingSort.priceDesc => Icons.arrow_downward_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.4)
                : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 18,
              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sort.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 18, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}
