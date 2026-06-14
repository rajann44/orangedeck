import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/domain/models/article.dart';
import 'swipe_card.dart';

class CardStack extends StatefulWidget {
  final List<Article> articles;
  final Function(Article article, bool isSave) onSwiped;
  final Function(Article article) onTap;
  final Function(Article article) onTapComments;

  const CardStack({
    super.key,
    required this.articles,
    required this.onSwiped,
    required this.onTap,
    required this.onTapComments,
  });

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with SingleTickerProviderStateMixin {
  late AnimationController _snapController;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  
  // Anchor point mapping (determines direction of rotation based on vertical swipe position)
  double _rotationDirectionMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    
    _snapController.addListener(() {
      if (!_isDragging) {
        setState(() {
          // Animate back to center using custom snapback curve
          _dragOffset = Offset.lerp(
            _dragOffset,
            Offset.zero,
            CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack).value,
          )!;
        });
      }
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details, Size size) {
    // If the touch is on the lower half of the card, we invert the rotation direction
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localTouch = renderBox.globalToLocal(details.globalPosition);
    final halfHeight = size.height / 2;
    
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = true;
      _rotationDirectionMultiplier = localTouch.dy < halfHeight ? 1.0 : -1.0;
      _snapController.stop();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details, double screenWidth) {
    setState(() {
      _isDragging = false;
    });

    final velocity = details.velocity.pixelsPerSecond;
    final threshold = screenWidth * 0.35;

    // Check swipe thresholds
    if (_dragOffset.dx > threshold || velocity.dx > 800) {
      _fling(true, screenWidth);
    } else if (_dragOffset.dx < -threshold || velocity.dx < -800) {
      _fling(false, screenWidth);
    } else {
      // Return to center
      HapticFeedback.lightImpact();
      _snapController.forward(from: 0.0);
    }
  }

  /// Performs a smooth, velocity-matching exit fling animation
  void _fling(bool toRight, double screenWidth) {
    HapticFeedback.mediumImpact();
    final finalX = toRight ? screenWidth * 1.5 : -screenWidth * 1.5;
    final currentOffset = _dragOffset;
    final topCard = widget.articles.first;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    controller.addListener(() {
      setState(() {
        _dragOffset = Offset(
          Offset.lerp(currentOffset, Offset(finalX, currentOffset.dy), controller.value)!.dx,
          currentOffset.dy,
        );
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSwiped(topCard, toRight);
        setState(() {
          _dragOffset = Offset.zero;
        });
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return Container();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final count = widget.articles.length;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: List.generate(count, (index) {
            // Render backwards so index 0 is on top
            final revIndex = count - 1 - index;
            final article = widget.articles[revIndex];

            if (revIndex == 0) {
              return Positioned.fill(
                child: GestureDetector(
                  onTapUp: (details) {
                    final cardHeight = constraints.maxHeight;
                    // If tap is in the bottom footer of the card (shifted up to clear overlay buttons, bottom 90-145 pixels)
                    // and on the left half (where points and comments are)
                    if (details.localPosition.dy > cardHeight - 145 && 
                        details.localPosition.dy < cardHeight - 90 && 
                        details.localPosition.dx < constraints.maxWidth * 0.65) {
                      widget.onTapComments(article);
                    } else {
                      widget.onTap(article);
                    }
                  },
                  onPanStart: (details) => _onDragStart(details, constraints.biggest),
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: (details) => _onDragEnd(details, screenWidth),
                  child: _buildTopCard(article, screenWidth),
                ),
              );
            }

            if (revIndex == 1) {
              return Positioned.fill(
                child: _buildBackgroundCard(article, 1, screenWidth),
              );
            }

            if (revIndex == 2) {
              return Positioned.fill(
                child: _buildBackgroundCard(article, 2, screenWidth),
              );
            }

            return const Positioned.fill(child: SizedBox.shrink());
          }),
        );
      },
    );
  }

  Widget _buildTopCard(Article article, double screenWidth) {
    // Tinder style rotation: rotates up to ~15 degrees max at complete drag
    final double maxRotation = 15.0 * math.pi / 180.0;
    final double progress = (_dragOffset.dx / screenWidth).clamp(-1.0, 1.0);
    final double angle = progress * maxRotation * _rotationDirectionMultiplier;

    final transform = Matrix4.identity()
      ..translate(_dragOffset.dx, _dragOffset.dy)
      ..rotateZ(angle);

    final normalizedProgress = _dragOffset.dx / (screenWidth * 0.35);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: SwipeCard(
        article: article,
        swipeProgress: normalizedProgress,
        onCommentsTap: () => widget.onTapComments(article),
      ),
    );
  }

  Widget _buildBackgroundCard(Article article, int depth, double screenWidth) {
    // Interpolation progress from 0.0 to 1.0 based on how far the top card is swiped
    final progress = (_dragOffset.dx.abs() / (screenWidth * 0.35)).clamp(0.0, 1.0);

    // Scaling: Card 1 goes from 0.95 -> 1.0. Card 2 goes from 0.90 -> 0.95
    final double baseScale = depth == 1 ? 0.95 : 0.90;
    final double targetScale = depth == 1 ? 1.0 : 0.95;
    final double currentScale = baseScale + (targetScale - baseScale) * progress;

    // Translation: Card 1 goes from 16 -> 0 px down. Card 2 goes from 32 -> 16 px down
    final double baseOffsetY = depth == 1 ? 16.0 : 32.0;
    final double targetOffsetY = depth == 1 ? 0.0 : 16.0;
    final double currentOffsetY = baseOffsetY - (baseOffsetY - targetOffsetY) * progress;

    // Opacity: Card 1 goes from 0.85 -> 1.0. Card 2 goes from 0.50 -> 0.85
    final double baseOpacity = depth == 1 ? 0.85 : 0.50;
    final double targetOpacity = depth == 1 ? 1.0 : 0.85;
    final double currentOpacity = baseOpacity + (targetOpacity - baseOpacity) * progress;

    return Transform.translate(
      offset: Offset(0, currentOffsetY),
      child: Transform.scale(
        scale: currentScale,
        child: Opacity(
          opacity: currentOpacity,
          child: SwipeCard(
            article: article,
            swipeProgress: 0.0,
          ),
        ),
      ),
    );
  }
}
