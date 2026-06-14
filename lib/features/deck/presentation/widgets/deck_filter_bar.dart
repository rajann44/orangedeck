import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/story_filter.dart';
import '../providers/deck_notifier.dart';

class DeckFilterBar extends ConsumerWidget {
  const DeckFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(selectedFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: StoryFilter.values.length,
        itemBuilder: (context, index) {
          final filter = StoryFilter.values[index];
          final isSelected = filter == activeFilter;

          final primaryColor = Theme.of(context).colorScheme.primary;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  ref.read(selectedFilterProvider.notifier).state = filter;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  filter.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF8C8C94),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
