import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/image_proxy.dart';
import '../../../core/utils/image_saver.dart';
import '../../../shared/theme/app_theme.dart';

/// true on Android/iOS (touchscreen), false on web or desktop (mouse).
/// We use this to skip the "tap outside to close" gesture on touch, since
/// it would conflict with pinch-to-zoom and swiping between photos.
bool get _isTouchDevice =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

// ── Thumbnail (used in table cell) ───────────────────────────────────────────

class ListingImageThumb extends StatelessWidget {
  final List<String> imageUrls;

  const ListingImageThumb({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const _Placeholder();
    }

    return GestureDetector(
      onTap: () => _openViewer(context, 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: ImageProxy.proxied(imageUrls.first),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: 400, // enough resolution for large cards
              placeholder: (_, __) => const _Placeholder(),
              errorWidget: (_, __, ___) => const _Placeholder(),
            ),
          ),
          // Badge when multiple images
          if (imageUrls.length > 1)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: _FullScreenViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }
}

// ── Full-screen viewer ────────────────────────────────────────────────────────

class _FullScreenViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late final PageController _controller;
  late final FocusNode _focusNode;
  late final TransformationController _zoomController;
  late int _current;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();
    _zoomController = TransformationController();
    _zoomController.addListener(_onZoomChanged);
  }

  void _onZoomChanged() {
    // getMaxScaleOnAxis() returns the current zoom level (1.0 = normal size).
    final zoomed = _zoomController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  bool _busy = false;

  Future<Uint8List> _downloadBytes(String url) async {
    final response = await Dio().get<List<int>>(
      ImageProxy.proxied(url),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveCurrentImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _downloadBytes(widget.imageUrls[_current]);
      final filename = 'ebay_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await saveImageBytes(bytes, filename);
      _showMessage('Image saved');
    } catch (_) {
      // Windows/Linux has no "gallery" concept; suggest sharing instead.
      _showMessage('Could not save here. Try the share button instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareCurrentImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _downloadBytes(widget.imageUrls[_current]);
      final filename = 'ebay_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, name: filename, mimeType: 'image/jpeg'),
          ],
        ),
      );
    } catch (_) {
      _showMessage('Could not share the image.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Image carousel ───────────────────────────────────────────────
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              // While zoomed in, swiping between photos is disabled: this
              // way dragging moves the zoomed image around instead of
              // switching to the next/previous photo.
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (i) {
                _zoomController.value = Matrix4.identity();
                setState(() => _current = i);
              },
              itemBuilder: (ctx, i) {
                final image = CachedNetworkImage(
                  imageUrl: ImageProxy.proxied(widget.imageUrls[i]),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accent,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textMuted,
                    size: 48,
                  ),
                );

                if (_isTouchDevice) {
                  // Mobile: no "tap outside" detector — this way pinch-to-
                  // zoom and swiping between photos stay intact, same as
                  // the original version. To close: the ✕ button.
                  return InteractiveViewer(
                    transformationController: _zoomController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(child: image),
                  );
                }

                // Web/escritorio (mouse): toca fuera de la imagen = cerrar.
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: InteractiveViewer(
                    transformationController: _zoomController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // absorbe el toque sobre la imagen
                        child: image,
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Top bar ──────────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.imageUrls.length > 1)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_current + 1} / ${widget.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          _TopBarIconButton(
                            icon: Icons.download_rounded,
                            busy: _busy,
                            onTap: _saveCurrentImage,
                          ),
                          const SizedBox(width: 8),
                          _TopBarIconButton(
                            icon: Icons.share_rounded,
                            busy: _busy,
                            onTap: _shareCurrentImage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Desktop arrow navigation ────────────────────────────────────
            if (widget.imageUrls.length > 1) ...[
              if (_current > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              if (_current < widget.imageUrls.length - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
            ],
            // ── Dot indicators ───────────────────────────────────────────────
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (i) => GestureDetector(
                      onTap: () => _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _current ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppTheme.accent
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Swipe hint (only first time) ──────────────────────────────────
            if (widget.imageUrls.length > 1 && _current == 0)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Swipe to see more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppTheme.textMuted,
        size: 20,
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
