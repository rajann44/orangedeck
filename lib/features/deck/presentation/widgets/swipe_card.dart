import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../shared/domain/models/article.dart';
import '../../../../shared/domain/models/comment.dart';
import '../providers/comments_notifier.dart';

class SwipeCard extends ConsumerWidget {
  final Article article;
  final double swipeProgress; // Positive for right/save, negative for left/pass
  final VoidCallback? onCommentsTap; // Click callback for discussion flow

  const SwipeCard({
    super.key,
    required this.article,
    required this.swipeProgress,
    this.onCommentsTap,
  });

  /// Formats UNIX epoch timestamp to a relative time string (e.g. "3h ago")
  String _formatRelativeTime(int timestamp) {
    final difference = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
    if (difference.inDays >= 1) return '${difference.inDays}d ago';
    if (difference.inHours >= 1) return '${difference.inHours}h ago';
    if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  /// Locally generates a high-quality abstract mesh gradient deterministically based on story ID.
  Widget _buildProceduralBanner(int id, double height) {
    final List<Color> palette = [
      const Color(0xFFEF4444), // Vibrant Red
      const Color(0xFFF97316), // Flame Orange
      const Color(0xFFF59E0B), // Golden Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFD946EF), // Fuchsia
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF00FFA3), // Mint
    ];

    // Pick three high-harmony colors deterministically
    final c1 = palette[id % palette.length];
    final c2 = palette[(id + 3) % palette.length];
    final c3 = palette[(id + 7) % palette.length];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Overlay Radial gradient for the "mesh" spotlight effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [c3.withOpacity(0.55), Colors.transparent],
                  center: const Alignment(0.4, -0.3),
                  radius: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            // 1. Deterministic cover art banner as full background
            Positioned.fill(
              child: _buildProceduralBanner(article.id, double.infinity),
            ),

            // 2. Premium dark gradient overlay for text readability (kept dark for overlay visuals)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.50),
                      Colors.black.withOpacity(0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.40, 0.85],
                  ),
                ),
              ),
            ),

            // 3. Foreground details & content aligned to the bottom
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Metadata Row: Source & Category Tag
                    Row(
                      children: [
                        if (article.url != null && article.url!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              'https://www.google.com/s2/favicons?sz=64&domain=${article.domain}',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.language_rounded,
                                size: 16,
                                color: Color(0xFFD4D4D8),
                              ),
                            ),
                          ),
                          const Gap(8),
                        ],
                        Expanded(
                          child: Text(
                            article.domain.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFFE4E4E7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        _buildCategoryBadge(context),
                      ],
                    ),
                    const Gap(12),

                    // Title Text
                    Text(
                      article.title,
                      style: GoogleFonts.outfit(
                        fontSize: article.title.length > 80 ? 17 : 21,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (article.text != null && article.text!.isNotEmpty) ...[
                      const Gap(8),
                      Text(
                        _sanitizeHtml(article.text!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.35,
                          color: const Color(0xFFD4D4D8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Spacer to push metrics/comments to bottom
                    const Spacer(),

                    // Inline Comments Preview
                    if (article.commentIds.isNotEmpty) ...[
                      _buildCommentsPreviewSection(context, ref, article.commentIds),
                      const Gap(10),
                    ],

                    Divider(color: Colors.white.withOpacity(0.12)),
                    const Gap(8),

                    // Footer Row (metrics & author)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildFooterMetric(
                              icon: Icons.keyboard_double_arrow_up_rounded,
                              value: '${article.score}',
                              color: primaryColor,
                            ),
                            const Gap(16),
                            _buildFooterMetric(
                              icon: Icons.chat_bubble_outline_rounded,
                              value: '${article.commentCount}',
                              color: primaryColor,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'by ',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFD4D4D8),
                              ),
                            ),
                            Text(
                              article.by,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' • ${_formatRelativeTime(article.time)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFD4D4D8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Swipe Stamp Overlays
            if (swipeProgress > 0.05)
              Positioned(
                top: 40,
                left: 30,
                child: Transform.rotate(
                  angle: -12 * math.pi / 180,
                  child: _buildStamp(
                    text: 'SAVE',
                    borderColor: const Color(0xFF10B981),
                    opacity: swipeProgress.clamp(0.0, 1.0),
                  ),
                ),
              ),
            if (swipeProgress < -0.05)
              Positioned(
                top: 40,
                right: 30,
                child: Transform.rotate(
                  angle: 12 * math.pi / 180,
                  child: _buildStamp(
                    text: 'SKIP',
                    borderColor: const Color(0xFFEF4444),
                    opacity: (-swipeProgress).clamp(0.0, 1.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsPreviewSection(BuildContext context, WidgetRef ref, List<int> commentIds) {
    final commentsAsync = ref.watch(commentsPreviewProvider(commentIds));
    final primaryColor = Theme.of(context).colorScheme.primary;

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) return const SizedBox.shrink();

        final comment = comments.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.forum_rounded,
                  size: 10,
                  color: primaryColor,
                ),
                const Gap(4),
                Text(
                  'TOP COMMENT PREVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const Gap(4),
            GestureDetector(
              onTap: () => _showCommentBottomSheet(context, comment),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F10).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${comment.by}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: primaryColor.withOpacity(0.95),
                      ),
                    ),
                    const Gap(1),
                    Text(
                      _sanitizeHtml(comment.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        height: 1.3,
                        color: const Color(0xFFE2E2E2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => _buildCommentsShimmer(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showCommentBottomSheet(BuildContext context, Comment comment) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F10).withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Handle
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.forum_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const Gap(8),
                        Text(
                          'TOP COMMENT DETAIL',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Author Details Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // Procedural avatar with gradient
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            comment.by.isNotEmpty ? comment.by[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${comment.by}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _formatRelativeTime(comment.time),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Comment Text Area
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          _sanitizeHtml(comment.text),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.45,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(20),

                  // Bottom Action Buttons
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      bottom: MediaQuery.of(context).padding.bottom + 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onCommentsTap?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'View Full Discussion',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
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
        );
      },
    );
  }

  Widget _buildCommentsShimmer(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.forum_rounded, size: 10, color: primaryColor.withOpacity(0.5)),
            const Gap(4),
            Container(
              width: 100,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const Gap(4),
        Container(
          height: 36,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F10).withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    String label = 'STORY';
    Color color = Colors.white.withOpacity(0.12);
    Color textColor = Colors.white;

    if (article.url == null || article.url!.isEmpty) {
      if (article.title.toLowerCase().startsWith('ask hn')) {
        label = 'ASK HN';
        color = primaryColor.withOpacity(0.15);
        textColor = primaryColor;
      } else if (article.title.toLowerCase().startsWith('show hn')) {
        label = 'SHOW HN';
        color = const Color(0xFF3B82F6).withOpacity(0.15);
        textColor = const Color(0xFF3B82F6);
      } else {
        label = 'TEXT POST';
      }
    } else if (article.title.toLowerCase().contains('job: ') || article.url!.contains('/jobs/')) {
      label = 'JOB';
      color = const Color(0xFF10B981).withOpacity(0.15);
      textColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFooterMetric({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const Gap(4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStamp({
    required String text,
    required Color borderColor,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 4),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: borderColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  /// Enhanced HTML sanitizer to strip formatting and clean up anchor tags
  String _sanitizeHtml(String html) {
    // Convert paragraph tags to newlines
    String text = html.replaceAll('<p>', '\n\n').replaceAll('</p>', '');
    
    // Replace pre/code blocks
    text = text.replaceAll('<pre><code>', '\n').replaceAll('</code></pre>', '');
    
    // Replace basic formatting tags
    text = text.replaceAll('<i>', '').replaceAll('</i>', '')
               .replaceAll('<code>', '').replaceAll('</code>', '');
    
    // Replace valid links: <a href="url">text</a> -> text or text (url)
    final RegExp linkRegExp = RegExp(r'<a\s+href="([^"]*)">([^<]*)</a>');
    text = text.replaceAllMapped(linkRegExp, (match) {
      final url = match.group(1);
      final linkText = match.group(2);
      if (url == linkText) {
        return url ?? '';
      } else {
        return '$linkText ($url)';
      }
    });

    // Remove any remaining complete or incomplete HTML tags (e.g. truncated links at the end)
    text = text.replaceAll(RegExp(r'<[^>]*>?'), '');
    
    // Unescape HTML entities
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
