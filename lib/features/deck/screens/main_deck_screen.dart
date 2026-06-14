import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'contact_screen.dart';
import '../presentation/providers/deck_notifier.dart';
import '../presentation/widgets/card_stack.dart';
import '../presentation/widgets/deck_filter_bar.dart';
import '../presentation/widgets/explore_category_card.dart';
import '../../saved/presentation/providers/saved_notifier.dart';
import '../../saved/screens/saved_articles_screen.dart';
import '../../article_detail/screens/article_webview_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../domain/models/story_filter.dart';

class MainDeckScreen extends ConsumerStatefulWidget {
  const MainDeckScreen({super.key});

  @override
  ConsumerState<MainDeckScreen> createState() => _MainDeckScreenState();
}

class _MainDeckScreenState extends ConsumerState<MainDeckScreen> {
  bool _showExploreGrid = false;

  Widget _buildExploreGrid(BuildContext context) {
    final categories = [
      (
        filter: StoryFilter.top,
        title: 'Top Stories',
        description: 'Trending tech discussions & links.',
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFFFF5A00), Color(0xFFFF7A00)], // Flame
      ),
      (
        filter: StoryFilter.newest,
        title: 'Newest',
        description: 'Real-time raw submission stream.',
        icon: Icons.access_time_filled_rounded,
        gradient: const [Color(0xFF00C6FF), Color(0xFF0072FF)], // Cyan/Blue
      ),
      (
        filter: StoryFilter.best,
        title: 'Best Stories',
        description: 'Highly rated curated discussions.',
        icon: Icons.workspace_premium_rounded,
        gradient: const [Color(0xFFEC008C), Color(0xFFFC6767)], // Pink/Red
      ),
      (
        filter: StoryFilter.ask,
        title: 'Ask HN',
        description: 'Community questions, advice & answers.',
        icon: Icons.forum_rounded,
        gradient: const [Color(0xFF8A2387), Color(0xFFE94057)], // Purple/Indigo
      ),
      (
        filter: StoryFilter.show,
        title: 'Show HN',
        description: 'Startups, projects & demos showcase.',
        icon: Icons.rocket_launch_rounded,
        gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)], // Green
      ),
      (
        filter: StoryFilter.jobs,
        title: 'Hiring Jobs',
        description: 'Startups and companies hiring talent.',
        icon: Icons.business_center_rounded,
        gradient: const [Color(0xFFF2994A), Color(0xFFF2C94C)], // Gold/Amber
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Discoveries',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(4),
              Text(
                'Discover different categories of tech stories matching your vibe.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8C94),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ExploreCategoryCard(
                title: cat.title,
                description: cat.description,
                icon: cat.icon,
                gradientColors: cat.gradient,
                onTap: () {
                  ref.read(selectedFilterProvider.notifier).state = cat.filter;
                  setState(() {
                    _showExploreGrid = false;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(deckNotifierProvider);
    final notifier = ref.read(deckNotifierProvider.notifier);
    final savedArticles = ref.watch(savedArticlesProvider);
    final isTopCardSaved = deckState.cards.isNotEmpty &&
        savedArticles.any((a) => a.id == deckState.cards.first.id);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _showExploreGrid = !_showExploreGrid;
                      });
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Gap(10),
                        Text(
                          'OrangeDeck',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Settings Button
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          size: 24,
                        ),
                        onPressed: () => _showSettingsBottomSheet(context, ref),
                      ),
                      // Go to Saved Deck Button
                      IconButton(
                        icon: const Icon(
                          Icons.bookmarks_outlined,
                          size: 24,
                        ),
                        onPressed: () {
                          final persistenceService = ref.read(persistenceServiceProvider);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => SavedArticlesScreen(
                                  persistenceService: persistenceService),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Animated Swapper between Swiper Feed and Explore Grid
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _showExploreGrid
                    ? _buildExploreGrid(context)
                    : Column(
                        key: const ValueKey('swiper_feed'),
                        children: [
                          // Horizontal Feed Filter Chips
                          const DeckFilterBar(),
                          const Gap(16),

                          if (deckState.isOffline) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.wifi_off_rounded, size: 16, color: theme.colorScheme.primary),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        'Offline Mode. Viewing cached stories.',
                                        style: GoogleFonts.inter(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Main Swiper Deck Area
                          Expanded(
                            child: Stack(
                              children: [
                                // 1. CardStack/List Area (takes up full expanded height)
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Builder(
                                      builder: (context) {
                                        if (deckState.isLoading && deckState.cards.isEmpty) {
                                          return _buildShimmerDeck(context);
                                        }

                                        if (deckState.errorMessage != null && deckState.cards.isEmpty) {
                                          return _buildErrorState(context, deckState.errorMessage!, notifier);
                                        }

                                        if (deckState.cards.isEmpty) {
                                          return _buildEmptyState(context, notifier);
                                        }

                                        return CardStack(
                                          articles: deckState.cards,
                                          onSwiped: (article, isSave) async {
                                            if (isSave) {
                                              await ref.read(savedArticlesProvider.notifier).saveArticle(article);
                                            }
                                            notifier.popCard(article.id);
                                          },
                                          onTap: (article) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (context) => ArticleWebviewScreen(article: article),
                                              ),
                                            );
                                          },
                                          onTapComments: (article) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (context) => ArticleWebviewScreen(
                                                  article: article,
                                                  startWithComments: true,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // 2. Floating action buttons overlaid on top of the bottom edge of the cards
                                if (deckState.cards.isNotEmpty || deckState.swipeHistory.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.only(bottom: 24.0, top: 20.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            scaffoldBg.withValues(alpha: 0.4),
                                            scaffoldBg.withValues(alpha: 0.95),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.0, 0.35, 1.0],
                                        ),
                                      ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Back (Undo/Previous) shortcut button
                                            _buildActionButton(
                                              context: context,
                                              icon: Icons.arrow_back_rounded,
                                              color: deckState.swipeHistory.isNotEmpty
                                                  ? theme.colorScheme.primary
                                                  : (isDark ? const Color(0xFF8C8C94).withValues(alpha: 0.3) : Colors.black12),
                                              size: 50,
                                              iconSize: 22,
                                              onTap: deckState.swipeHistory.isNotEmpty
                                                  ? () {
                                                      HapticFeedback.mediumImpact();
                                                      notifier.undoSwipe();
                                                    }
                                                  : () {},
                                            ),
                                            const Gap(24),
                                            // Save (Bookmark) shortcut button
                                            _buildActionButton(
                                              context: context,
                                              icon: isTopCardSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                                              color: deckState.cards.isNotEmpty
                                                  ? (isTopCardSaved ? theme.colorScheme.primary : const Color(0xFF10B981))
                                                  : (isDark ? const Color(0xFF8C8C94).withValues(alpha: 0.3) : Colors.black12),
                                              size: 60,
                                              iconSize: 28,
                                              onTap: deckState.cards.isNotEmpty
                                                  ? () async {
                                                      await HapticFeedback.mediumImpact();
                                                      final topCard = deckState.cards.first;
                                                      if (isTopCardSaved) {
                                                        await ref.read(savedArticlesProvider.notifier).deleteArticle(topCard.id);
                                                      } else {
                                                        await ref.read(savedArticlesProvider.notifier).saveArticle(topCard);
                                                      }
                                                    }
                                                  : () {},
                                            ),
                                            const Gap(24),
                                            // Next (Skip/Pass) shortcut button
                                            _buildActionButton(
                                              context: context,
                                              icon: Icons.arrow_forward_rounded,
                                              color: deckState.cards.isNotEmpty
                                                  ? const Color(0xFFEF4444)
                                                  : (isDark ? const Color(0xFF8C8C94).withValues(alpha: 0.3) : Colors.black12),
                                              size: 60,
                                              iconSize: 28,
                                              onTap: deckState.cards.isNotEmpty
                                                  ? () {
                                                      HapticFeedback.mediumImpact();
                                                      final topCard = deckState.cards.first;
                                                      notifier.popCard(topCard.id);
                                                    }
                                                  : () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentThemeState = ref.watch(themeNotifierProvider);
            final currentTheme = Theme.of(context);
            final currentIsDark = currentTheme.brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: currentTheme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(
                  color: currentIsDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: currentIsDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(20),

                  // Header
                  Text(
                    'Customize Deck',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(24),

                  // Theme Mode Selector
                  Text(
                    'THEME MODE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8C8C94),
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      _buildThemeModeButton(
                        context: context,
                        label: 'System',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: currentThemeState.themeMode == ThemeMode.system,
                        onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.system),
                      ),
                      const Gap(12),
                      _buildThemeModeButton(
                        context: context,
                        label: 'Light',
                        icon: Icons.light_mode_rounded,
                        isSelected: currentThemeState.themeMode == ThemeMode.light,
                        onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.light),
                      ),
                      const Gap(12),
                      _buildThemeModeButton(
                        context: context,
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentThemeState.themeMode == ThemeMode.dark,
                        onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                  const Gap(24),

                  // Accent Color Selector
                  Text(
                    'ACCENT COLOR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8C8C94),
                    ),
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: themeAccentPalette.map((color) {
                      final isSelected = currentThemeState.accentColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(themeNotifierProvider.notifier).setAccentColor(color);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (currentIsDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 3.0,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(24),
                  Divider(
                    color: currentIsDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  const Gap(12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentTheme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contact_support_outlined,
                        color: currentTheme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Contact Developer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: currentIsDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Support, feedback, or publisher inquiries',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8C8C94),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8C8C94),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pop(context); // close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ContactScreen(),
                        ),
                      );
                    },
                  ),
                  const Gap(12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeModeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF0F0F10) : const Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF8C8C94) : const Color(0xFF5C5C64)),
              ),
              const Gap(8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
    double iconSize = 28,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildShimmerDeck(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1E20) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 100, height: 12, color: Colors.white),
                  Container(width: 60, height: 16, color: Colors.white),
                ],
              ),
              const Gap(32),
              Container(width: double.infinity, height: 28, color: Colors.white),
              const Gap(12),
              Container(width: double.infinity, height: 28, color: Colors.white),
              const Gap(12),
              Container(width: 180, height: 28, color: Colors.white),
              const Spacer(),
              Container(width: double.infinity, height: 1, color: Colors.white),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 50, height: 16, color: Colors.white),
                      const Gap(16),
                      Container(width: 50, height: 16, color: Colors.white),
                    ],
                  ),
                  Container(width: 120, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DeckNotifier notifier) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_none_rounded,
            size: 64,
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
          ),
          const Gap(20),
          Text(
            'No More Cards Left',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            'You have swiped through all loaded articles.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8C8C94),
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () => notifier.loadFeed(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh Feed'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, DeckNotifier notifier) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const Gap(20),
            Text(
              'Failed to Load Feed',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF8C8C94),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () => notifier.loadFeed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
