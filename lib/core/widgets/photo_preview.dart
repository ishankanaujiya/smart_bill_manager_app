import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/design_system.dart';

/// Opens a preview of a profile picture.
///
/// The preview is presented as a **floating card** over a dimmed backdrop — it
/// deliberately does not fill the screen. When [imageUrl] is null or empty
/// (the user has no photo), the card shows their [initials] instead.
///
/// When a photo exists, it grows out of its on-screen thumbnail through a
/// [Hero] flight (identified by [heroTag]). Dismiss with the close button, a
/// tap on the backdrop, or a downward swipe.
Future<void> showPhotoPreview(
  BuildContext context, {
  String? imageUrl,
  required String initials,
  Object? heroTag,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      // Non-opaque (with a transparent barrier) so the screen behind shows
      // through the dimmed backdrop. Mirrors the payment-QR viewer's setup.
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => PhotoPreviewScreen(
        imageUrl: imageUrl,
        initials: initials,
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Floating profile-photo preview shown by [showPhotoPreview].
class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.initials,
    this.imageUrl,
    this.heroTag,
  });

  /// The user's initials, shown when there is no photo.
  final String initials;

  /// The remote URL of the photo, or null/empty when the user has none.
  final String? imageUrl;

  /// [Hero] tag shared with the thumbnail this photo flies out of. Only used
  /// when a photo exists.
  final Object? heroTag;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  /// Drag distance (logical px) past which a downward swipe dismisses.
  static const _dismissDistance = 120.0;

  /// Downward fling speed (logical px/s) that dismisses regardless of distance.
  static const _dismissVelocity = 700.0;

  double _dragOffset = 0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset.abs() > _dismissDistance ||
        velocity.abs() > _dismissVelocity) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_dragOffset != 0) setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    // Fade the backdrop as the card is dragged away.
    final dragProgress = (_dragOffset.abs() / 320).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Dimmed backdrop (tap to dismiss) ──────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: ColoredBox(
                color: AppColors.black.withValues(
                  alpha: 0.72 * (1 - dragProgress * 0.7),
                ),
              ),
            ),
          ),

          // ── Floating preview card ─────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.huge,
              ),
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: GestureDetector(
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: LayoutBuilder(
                    builder: (context, constraints) => _PreviewCard(
                      initials: widget.initials,
                      imageUrl: widget.imageUrl,
                      heroTag: widget.heroTag,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Close button ──────────────────────────────────────────────────
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _CloseButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rounded card holding either the photo or the user's initials.
///
/// Its size is capped to the space it is given, so the preview never covers
/// the whole screen.
class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.initials,
    required this.maxWidth,
    required this.maxHeight,
    this.imageUrl,
    this.heroTag,
  });

  final String initials;
  final double maxWidth;
  final double maxHeight;
  final String? imageUrl;
  final Object? heroTag;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  /// Fallback ratio used until the image's real dimensions are known.
  static const _fallbackRatio = 1.0;

  final _aspectRatio = ValueNotifier<double>(_fallbackRatio);
  ImageStream? _stream;
  ImageStreamListener? _listener;

  bool get _hasPhoto =>
      widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasPhoto) return;

    // Resolve the image up-front so the card can take the photo's aspect ratio
    // immediately (the image is normally already in the cache from the
    // thumbnail). This avoids a layout jump once the image paints.
    final stream = NetworkImage(widget.imageUrl!).resolve(
      ImageConfiguration.empty,
    );
    final listener = ImageStreamListener(
      (info, _) {
        if (info.image.height > 0) {
          _aspectRatio.value = info.image.width / info.image.height;
        }
      },
      onError: (_, __) {},
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _aspectRatio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto) return _buildInitialsCard(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: _aspectRatio,
        builder: (context, ratio, child) =>
            AspectRatio(aspectRatio: ratio, child: child),
        child: _card(child: _buildPhoto()),
      ),
    );
  }

  Widget _buildPhoto() {
    Widget image = Image.network(
      widget.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _LoadingIndicator(),
      errorBuilder: (_, __, ___) => const _PreviewError(),
    );

    if (widget.heroTag != null) {
      image = Hero(
        tag: widget.heroTag!,
        flightShuttleBuilder: _photoFlightShuttleBuilder,
        child: image,
      );
    }
    return image;
  }

  Widget _buildInitialsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final side = math.min(
      math.min(widget.maxWidth, widget.maxHeight),
      260.0,
    );

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkPrimaryGradient
            : AppColors.lightPrimaryGradient,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Text(
          widget.initials,
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.4),
        borderRadius: AppRadius.radiusXxl,
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.45),
          blurRadius: 36,
          spreadRadius: 2,
          offset: const Offset(0, 14),
        ),
      ];
}

/// Morphs the thumbnail's circular clip into the card's rounded corners during
/// the [Hero] flight, so the transition reads as one continuous image.
Widget _photoFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final toHero = toHeroContext.widget as Hero;
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );

  return AnimatedBuilder(
    animation: curved,
    builder: (context, child) {
      final radius = BorderRadius.lerp(
        BorderRadius.circular(AppRadius.full),
        BorderRadius.circular(AppRadius.xxl),
        curved.value,
      )!;
      return ClipRRect(borderRadius: radius, child: child);
    },
    child: toHero.child,
  );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load photo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact circular close affordance pinned to the top-right corner.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
