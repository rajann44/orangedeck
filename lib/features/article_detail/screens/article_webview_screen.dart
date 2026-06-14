import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/domain/models/article.dart';
import '../data/article_reader_service.dart';

enum DetailTab { article, discussion }

class ArticleWebviewScreen extends StatefulWidget {
  final Article article;
  final bool startWithComments;

  const ArticleWebviewScreen({
    super.key,
    required this.article,
    this.startWithComments = false,
  });

  @override
  State<ArticleWebviewScreen> createState() => _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends State<ArticleWebviewScreen> {
  late DetailTab _activeTab;
  WebViewController? _articleController;
  WebViewController? _discussionController;
  
  int _articleProgress = 0;
  int _discussionProgress = 0;
  
  bool _articleHasError = false;
  bool _discussionHasError = false;

  // Reader Mode states
  bool _isReaderMode = false;
  bool _readerLoading = false;
  String? _readerContent;
  String? _readerError;
  final _readerService = ArticleReaderService();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.startWithComments ? DetailTab.discussion : DetailTab.article;
    
    final hasUrl = widget.article.url != null && widget.article.url!.isNotEmpty;
    if (hasUrl) {
      _isReaderMode = true;
      _loadReaderContent();
    }
    
    _initControllers();
  }

  void _initControllers() {
    final hasUrl = widget.article.url != null && widget.article.url!.isNotEmpty;

    // 1. Initialize Article Controller if url exists
    if (hasUrl) {
      _articleController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0F0F10))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _articleProgress = progress;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _articleHasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _articleProgress = 100;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    _articleHasError = true;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.url!));
    }

    // 2. Initialize Discussion Controller (always loads HN story)
    _discussionController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0F10))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _discussionProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _discussionHasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _discussionProgress = 100;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _discussionHasError = true;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://news.ycombinator.com/item?id=${widget.article.id}'));
  }

  Future<void> _loadReaderContent() async {
    if (_readerContent != null) return; // Already cached
    setState(() {
      _readerLoading = true;
      _readerError = null;
    });
    try {
      final content = await _readerService.fetchReadableContent(widget.article.url!);
      if (mounted) {
        setState(() {
          _readerContent = content;
          _readerLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readerError = e.toString();
          _readerLoading = false;
        });
      }
    }
  }

  void _share() {
    final String shareUrl;
    if (_activeTab == DetailTab.article && widget.article.url != null && widget.article.url!.isNotEmpty) {
      shareUrl = widget.article.url!;
    } else {
      shareUrl = 'https://news.ycombinator.com/item?id=${widget.article.id}';
    }
    Share.share('${widget.article.title} - $shareUrl', subject: 'OrangeDeck Article');
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.article.url != null && widget.article.url!.isNotEmpty;
    final activeProgress = _activeTab == DetailTab.article ? _articleProgress : _discussionProgress;
    final activeHasError = _activeTab == DetailTab.article ? _articleHasError : _discussionHasError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.article.domain,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              widget.article.title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF8C8C94),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Reader Mode Toggle Button (Only active in Article Webview tab)
          if (hasUrl && _activeTab == DetailTab.article)
            IconButton(
              icon: Icon(
                _isReaderMode ? Icons.chrome_reader_mode_rounded : Icons.chrome_reader_mode_outlined,
                color: _isReaderMode ? theme.colorScheme.primary : (isDark ? Colors.white : Colors.black),
              ),
              onPressed: () {
                setState(() {
                  _isReaderMode = !_isReaderMode;
                });
                if (_isReaderMode) {
                  _loadReaderContent();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F10) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Sliding Indicator
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    alignment: _activeTab == DetailTab.article 
                        ? Alignment.centerLeft 
                        : Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tab Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _activeTab = DetailTab.article;
                            });
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _activeTab == DetailTab.article 
                                    ? FontWeight.w700 
                                    : FontWeight.w500,
                                color: _activeTab == DetailTab.article 
                                    ? Colors.white 
                                    : const Color(0xFF8C8C94),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<Color?>(
                                    duration: const Duration(milliseconds: 200),
                                    tween: ColorTween(
                                      begin: const Color(0xFF8C8C94),
                                      end: _activeTab == DetailTab.article 
                                          ? Colors.white 
                                          : const Color(0xFF8C8C94),
                                    ),
                                    builder: (context, color, child) {
                                      return Icon(
                                        !hasUrl ? Icons.menu_book_rounded : Icons.article_rounded,
                                        size: 16,
                                        color: color,
                                      );
                                    },
                                  ),
                                  const Gap(6),
                                  const Text('Article'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _activeTab = DetailTab.discussion;
                            });
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: _activeTab == DetailTab.discussion 
                                    ? FontWeight.w700 
                                    : FontWeight.w500,
                                color: _activeTab == DetailTab.discussion 
                                    ? Colors.white 
                                    : const Color(0xFF8C8C94),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<Color?>(
                                    duration: const Duration(milliseconds: 200),
                                    tween: ColorTween(
                                      begin: const Color(0xFF8C8C94),
                                      end: _activeTab == DetailTab.discussion 
                                          ? Colors.white 
                                          : const Color(0xFF8C8C94),
                                    ),
                                    builder: (context, color, child) {
                                      return Icon(
                                        Icons.forum_rounded,
                                        size: 16,
                                        color: color,
                                      );
                                    },
                                  ),
                                  const Gap(6),
                                  const Text('Discussion'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _activeTab == DetailTab.article ? 0 : 1,
            children: [
              // Tab 1: Article WebView, Reader Mode, or Text Reader View
              _buildArticleTabView(hasUrl),
              
              // Tab 2: Discussion WebView
              _buildWebViewTab(
                controller: _discussionController,
                hasError: _discussionHasError,
                hasUrl: true,
                fallbackView: _buildErrorView(context),
              ),
            ],
          ),

          // Linear loading progress indicator at top of page (only for standard WebView)
          if (activeProgress < 100 && !activeHasError && !(_activeTab == DetailTab.article && _isReaderMode))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: LinearProgressIndicator(
                value: activeProgress / 100.0,
                backgroundColor: Colors.transparent,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArticleTabView(bool hasUrl) {
    if (!hasUrl) {
      return _buildTextReaderView(context);
    }
    
    if (_isReaderMode) {
      return _buildReaderModeView(context);
    }
    
    return _buildWebViewTab(
      controller: _articleController,
      hasError: _articleHasError,
      hasUrl: true,
      fallbackView: _buildErrorView(context),
    );
  }

  Widget _buildWebViewTab({
    required WebViewController? controller,
    required bool hasError,
    required bool hasUrl,
    required Widget fallbackView,
  }) {
    if (!hasUrl) return fallbackView;
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        if (controller != null)
          WebViewWidget(controller: controller),
        if (hasError)
          Container(
            color: theme.scaffoldBackgroundColor,
            child: fallbackView,
          ),
      ],
    );
  }

  Widget _buildReaderModeView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_readerLoading) {
      return _buildReaderShimmer(context);
    }
    
    if (_readerError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const Gap(16),
              Text(
                'Reader Mode Failed',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Text(
                'We could not extract readable content from this article.',
                style: GoogleFonts.inter(color: const Color(0xFF8C8C94), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _loadReaderContent();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Try Again'),
                  ),
                  const Gap(12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isReaderMode = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Switch to Web', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.article.title,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Text(
                'Publisher: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8C8C94),
                ),
              ),
              Text(
                widget.article.domain,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '  •  Author: ${widget.article.by}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF5C5C64),
                ),
              ),
            ],
          ),
          const Gap(24),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
          const Gap(24),
          Text(
            _readerContent ?? 'No readable text content extracted.',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: isDark ? const Color(0xFFE2E2E2) : const Color(0xFF2C2C2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final blockColor = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04);
    final baseColor = isDark ? const Color(0xFF1E1E20) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 28,
              decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
            ),
            const Gap(8),
            Container(
              width: 200,
              height: 28,
              decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
            ),
            const Gap(16),
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
            ),
            const Gap(24),
            Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            const Gap(24),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const Gap(8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const Gap(8),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(color: blockColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextReaderView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.article.title,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Text(
                'Publisher: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8C8C94),
                ),
              ),
              Text(
                widget.article.domain,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '  •  Author: ${widget.article.by}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF5C5C64),
                ),
              ),
            ],
          ),
          const Gap(24),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
          const Gap(24),
          if (widget.article.text != null && widget.article.text!.isNotEmpty)
            Text(
              _sanitizeHtml(widget.article.text!),
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: isDark ? const Color(0xFFE2E2E2) : const Color(0xFF2C2C2E),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48.0),
                child: Text(
                  'No text content is available for this post.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8C8C94),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
            const Gap(16),
            Text(
              'Could Not Load Page',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Text(
              'The website could not be opened. You can try sharing the link to read it in an external browser.',
              style: GoogleFonts.inter(
                color: const Color(0xFF8C8C94),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _share,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Share Link'),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeHtml(String html) {
    return html
        .replaceAll('<p>', '\n\n')
        .replaceAll('</p>', '')
        .replaceAll('<pre><code>', '\n')
        .replaceAll('</code></pre>', '')
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<code>', '')
        .replaceAll('</code>', '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('&amp;', '&');
  }
}
