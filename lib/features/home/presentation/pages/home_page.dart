import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:newjuststock/core/navigation/fade_route.dart';
import 'package:newjuststock/features/auth/presentation/pages/login_register_page.dart';
import 'package:newjuststock/features/profile/presentation/pages/profile_page.dart';
import 'package:newjuststock/services/session_service.dart';
import 'package:newjuststock/services/segment_service.dart';
import 'package:newjuststock/services/gallery_service.dart';
import 'package:newjuststock/wallet/ui/wallet_screen.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String mobile;
  final String? token;

  const HomePage({
    super.key,
    required this.name,
    required this.mobile,
    this.token,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> _segmentKeys = [
    'nifty',
    'banknifty',
    'stocks',
    'sensex',
    'commodity',
  ];

  static const Color _segmentGradientStart = Color(0xFFFFA000);
  static const Color _segmentGradientEnd = Color(0xFFFFC107);

  static const List<_SegmentDescriptor> _segmentDescriptors = [
    _SegmentDescriptor(
      key: 'nifty',
      title: 'NIFTY',
      icon: Icons.trending_up,
      tone: _SegmentTone.primary,
    ),
    _SegmentDescriptor(
      key: 'banknifty',
      title: 'BANKNIFTY',
      icon: Icons.account_balance,
      tone: _SegmentTone.secondary,
    ),
    _SegmentDescriptor(
      key: 'stocks',
      title: 'STOCKS',
      icon: Icons.auto_graph,
      tone: _SegmentTone.primary,
    ),
    _SegmentDescriptor(
      key: 'sensex',
      title: 'SENSEX',
      icon: Icons.show_chart,
      tone: _SegmentTone.secondary,
    ),
    _SegmentDescriptor(
      key: 'commodity',
      title: 'COMMODITY',
      icon: Icons.analytics_outlined,
      tone: _SegmentTone.primary,
    ),
  ];

  final Map<String, SegmentMessage> _segmentMessages = {};
  final Map<String, String> _acknowledgedMessages = {};
  bool _loadingSegments = false;
  String? _segmentsError;

  List<GalleryImage> _galleryImages = const [];
  bool _loadingGallery = false;
  String? _galleryError;

  @override
  void initState() {
    super.initState();
    _loadSegments();
    _loadGallery();
  }

  String get _displayName {
    final trimmed = widget.name.trim();
    return trimmed.isEmpty ? 'User' : trimmed;
  }

  String get _initial => _displayName[0].toUpperCase();

  Future<void> _loadSegments({bool silently = false}) async {
    if (!silently) {
      setState(() {
        _loadingSegments = true;
        _segmentsError = null;
      });
    }

    final result = await SegmentService.fetchSegments(
      _segmentKeys,
      token: widget.token,
    );

    if (!mounted) return;

    if (result.unauthorized) {
      if (!silently) _showSnack('Session expired. Please log in again.');
      await SessionService.clearSession();
      if (!mounted) return;
      setState(() {
        _loadingSegments = false;
        _segmentsError = 'Session expired. Please log in again.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const LoginRegisterPage()),
          (route) => false,
        );
      });
      return;
    }

    final segments = result.segments;

    setState(() {
      _loadingSegments = false;

      if (segments.isNotEmpty) {
        for (final entry in segments.entries) {
          _segmentMessages[entry.key] = entry.value;
          if (!entry.value.hasMessage) {
            _acknowledgedMessages.remove(entry.key);
          }
        }
      }

      final missingKeys = _segmentKeys
          .where((key) => !segments.containsKey(key))
          .toList();
      if (segments.isEmpty) {
        _segmentsError =
            'Unable to fetch market updates right now. Pull to refresh to try again.';
      } else if (missingKeys.isNotEmpty) {
        _segmentsError =
            'Some market updates are unavailable. Pull to refresh to retry.';
      } else {
        _segmentsError = null;
      }
    });

    if (!silently) {
      if (segments.isEmpty) {
        _showSnack(
          'Unable to fetch the latest market updates. Please try again.',
        );
      } else {
        final missingKeys = _segmentKeys
            .where((key) => !segments.containsKey(key))
            .toList();
        if (missingKeys.isNotEmpty) {
          _showSnack('Some market updates could not be refreshed.');
        }
      }
    }
  }

  Future<void> _loadGallery({bool silently = false}) async {
    if (!silently) {
      setState(() {
        _galleryError = null;
      });
    }
    setState(() {
      _loadingGallery = true;
    });

    List<GalleryImage>? images;
    String? error;

    try {
      final fetched = await GalleryService.fetchImages(limit: 3);
      final sorted = List<GalleryImage>.from(fetched)
        ..sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      images = sorted.take(3).toList(growable: false);
    } catch (e) {
      if (e is GalleryFetchException) {
        error = e.message;
      } else {
        error = 'Unable to load images. Please try again.';
      }
    }

    if (!mounted) return;

    setState(() {
      _loadingGallery = false;
      if (images != null) {
        _galleryImages = images;
        _galleryError = null;
      } else {
        _galleryError = error;
      }
    });
  }

  bool _isSegmentUnread(String key) {
    final segment = _segmentMessages[key];
    if (segment == null) return false;
    final message = segment.message.trim();
    if (message.isEmpty) return false;
    final seenMessage = _acknowledgedMessages[key];
    return seenMessage != message;
  }

  Future<void> _handleSegmentTap(_HomeItem item) async {
    final segment = _segmentMessages[item.segmentKey];
    if (segment == null) {
      _showSnack('No update for ${item.title} yet.');
      return;
    }
    final message = segment.message.trim();
    if (message.isEmpty) {
      _showSnack('No update for ${item.title} yet.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (context) {
        final theme = Theme.of(context);
        final label = segment.label.trim().isEmpty
            ? item.title
            : segment.label.trim();
        final timestamp = _formatTimestamp(segment.updatedAt);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    timestamp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SelectableText(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _segmentDescriptors
        .map(
          (descriptor) => _HomeItem(
            title: descriptor.title,
            icon: descriptor.icon,
            segmentKey: descriptor.key,
            gradientStart: _segmentGradientStart,
            gradientEnd: _segmentGradientEnd,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.show_chart, color: Colors.white),
            SizedBox(width: 8),
            Text('JustStock'),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.secondary],
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Wallet',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {
              Navigator.of(context).push(
                fadeRoute(
                  WalletScreen(
                    name: widget.name,
                    mobile: widget.mobile,
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  fadeRoute(
                    ProfilePage(name: widget.name, mobile: widget.mobile),
                  ),
                );
              },
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: scheme.primary,
                child: Text(_initial),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemCount = items.length;
          const double baseGap = 6.0;
          final gap = itemCount > 1 ? baseGap : 0.0;
          final availableRowWidth = (width - 32).clamp(0.0, 520.0);
          final rawDiameter = itemCount > 0
              ? (availableRowWidth - gap * (itemCount - 1)) / itemCount
              : 0.0;
          double circleDiameter;
          if (rawDiameter.isFinite && rawDiameter > 0) {
            circleDiameter = rawDiameter.clamp(42.0, 88.0);
            if (rawDiameter < 42.0) {
              circleDiameter = rawDiameter;
            }
          } else if (availableRowWidth > 0 && itemCount > 0) {
            circleDiameter = availableRowWidth / itemCount;
          } else {
            circleDiameter = 52.0;
          }
          if (!circleDiameter.isFinite || circleDiameter <= 0) {
            circleDiameter = 52.0;
          }
          final rowWidth = itemCount > 0
              ? circleDiameter * itemCount + gap * (itemCount - 1)
              : circleDiameter;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait<void>([
                  _loadSegments(silently: true),
                  _loadGallery(silently: true),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_displayName!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    _DailyTipChip(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(fadeRoute(const DailyTipPage()));
                      },
                    ),

                    const SizedBox(height: 20),

                    if (_segmentsError != null) ...[
                      Card(
                        color: scheme.errorContainer.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: scheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _segmentsError!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_loadingSegments) ...[
                      const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 12),
                    ],
                    Center(
                      child: SizedBox(
                        width: rowWidth,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) SizedBox(width: gap),
                              SizedBox(
                                width: circleDiameter,
                                child: _HomeCircleTile(
                                  title: items[i].title,
                                  icon: items[i].icon,
                                  gradientStart: items[i].gradientStart,
                                  gradientEnd: items[i].gradientEnd,
                                  diameter: circleDiameter,
                                  hasNotification: _isSegmentUnread(
                                    items[i].segmentKey,
                                  ),
                                  onTap: () => _handleSegmentTap(items[i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdsSlider(
                      assetPaths: const [
                        'assets/ads/ad_low_js.mp4',
                        'assets/ads/free_acc.mp4',
                        'assets/ads/add3.mp4',
                      ],
                    ),
                    const SizedBox(height: 24),
                    _GallerySection(
                      images: _galleryImages,
                      loading: _loadingGallery,
                      error: _galleryError,
                      onRetry: () {
                        _loadGallery();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return null;
    final local = timestamp.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour24 = local.hour;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$day $month $year - $hour:$minute $period';
  }
}

class _SegmentDescriptor {
  final String key;
  final String title;
  final IconData icon;
  final _SegmentTone tone;

  const _SegmentDescriptor({
    required this.key,
    required this.title,
    required this.icon,
    required this.tone,
  });
}

enum _SegmentTone { primary, secondary }

class _HomeItem {
  final String title;
  final IconData icon;
  final String segmentKey;
  final Color gradientStart;
  final Color gradientEnd;

  const _HomeItem({
    required this.title,
    required this.icon,
    required this.segmentKey,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

/// Circle tile with bigger inner icon and smaller label.
class _HomeCircleTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;
  final double diameter;
  final bool hasNotification;

  const _HomeCircleTile({
    required this.title,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
    required this.diameter,
    this.hasNotification = false,
  });

  @override
  State<_HomeCircleTile> createState() => _HomeCircleTileState();
}

class _HomeCircleTileState extends State<_HomeCircleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.title;
    final icon = widget.icon;
    final gradientStart = widget.gradientStart;
    final gradientEnd = widget.gradientEnd;
    final onTap = widget.onTap;
    final diameter = widget.diameter;
    final hasNotification = widget.hasNotification;

    final baseLabelStyle =
        theme.textTheme.labelMedium ?? theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final baseFontSize = baseLabelStyle.fontSize ?? 12.0;
    final scaledFontSize = (baseFontSize * (diameter / 60.0)).clamp(10.0, baseFontSize + 1.0);
    final labelStyle = baseLabelStyle.copyWith(
      fontSize: scaledFontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final iconSize = (diameter * 0.32).clamp(18.0, 30.0);

    final baseScale = hasNotification ? 1.02 : 1.0;
    final hoverScale = hasNotification ? 0.03 : 0.04;
    final scale = _hovered ? baseScale + hoverScale : baseScale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: SizedBox(
          width: diameter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: diameter,
                height: diameter,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            gradientStart,
                            gradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradientStart.withOpacity(
                              hasNotification ? 0.55 : 0.25,
                            ),
                            blurRadius: hasNotification ? 18 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                          if (hasNotification)
                            Positioned(
                              top: diameter * 0.18,
                              right: diameter * 0.18,
                              child: _NotificationBadge(
                                glowColor: gradientStart,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.glowColor, required this.color});

  final Color glowColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 1.2,
          ),
        ],
      ),
    );
  }
}

class _DailyTipChip extends StatelessWidget {
  const _DailyTipChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'DailyTip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Blank DailyTip page =====
class DailyTipPage extends StatelessWidget {
  const DailyTipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyTip'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.secondary],
            ),
          ),
        ),
      ),
      // Blank for now as requested
      body: const SizedBox.shrink(),
    );
  }
}

// ------------------------------ Ads views ---------------------------------

class _AdVideoTile extends StatefulWidget {
  final String assetPath;

  const _AdVideoTile({super.key, required this.assetPath});

  @override
  State<_AdVideoTile> createState() => _AdVideoTileState();
}

class _AdVideoTileState extends State<_AdVideoTile> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _AdVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _controller?.dispose();
      _controller = null;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await rootBundle.load(widget.assetPath);
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
    } catch (e) {
      debugPrint('Ad asset failed to load ${widget.assetPath}: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final aspectRatio =
        controller != null &&
            controller.value.isInitialized &&
            controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: controller != null && controller.value.isInitialized
            ? VideoPlayer(controller)
            : const _LoadingAdPlaceholder(),
      ),
    );
  }
}

class _LoadingAdPlaceholder extends StatelessWidget {
  const _LoadingAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: Center(
        child: Text(
          'Loading ad video...',
          style: TextStyle(
            color: const Color(0xFFFFA000),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.images,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<GalleryImage> images;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = images.isNotEmpty;
    final errorMessage = error;

    Widget content;
    if (loading && !hasImages) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (!hasImages && errorMessage != null) {
      content = _GalleryInfoCard(
        icon: Icons.wifi_off,
        message: errorMessage,
        actionLabel: 'Retry',
        onAction: loading ? null : onRetry,
      );
    } else if (!hasImages) {
      content = _GalleryInfoCard(
        icon: Icons.image_outlined,
        message: 'No images available yet.',
        actionLabel: 'Refresh',
        onAction: loading ? null : onRetry,
      );
    } else {
      content = _GallerySlider(images: images);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Latest Images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (loading && hasImages)
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            const Spacer(),
            IconButton(
              onPressed: loading ? null : onRetry,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh images',
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
        if (errorMessage != null && hasImages)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _GallerySlider extends StatefulWidget {
  const _GallerySlider({required this.images});

  final List<GalleryImage> images;

  @override
  State<_GallerySlider> createState() => _GallerySliderState();
}

class _GallerySliderState extends State<_GallerySlider> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(covariant _GallerySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _currentPage = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final image = images[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _GalleryTile(image: image),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 14 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.image});

  final GalleryImage image;

  double get _aspectRatio {
    final width = image.width;
    final height = image.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    return 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.colorScheme.surfaceVariant.withOpacity(0.4);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: placeholderColor),
            Image.network(
              image.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryInfoCard extends StatelessWidget {
  const _GalleryInfoCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdsSlider extends StatefulWidget {
  final List<String> assetPaths;

  const _AdsSlider({super.key, required this.assetPaths});

  @override
  State<_AdsSlider> createState() => _AdsSliderState();
}

class _AdsSliderState extends State<_AdsSlider> {
  late final PageController _pageController;
  int _index = 0;
  Timer? _timer;
  List<String> _validPaths = const [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    _prepareAssets();
  }

  @override
  void didUpdateWidget(covariant _AdsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPaths.join('|') != widget.assetPaths.join('|')) {
      _timer?.cancel();
      _prepareAssets();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _prepareAssets() async {
    final results = <String>[];
    for (final path in widget.assetPaths) {
      try {
        await rootBundle.load(path);
        results.add(path);
      } catch (_) {
        debugPrint('Ad asset missing, skipping: $path');
      }
    }
    if (!mounted) return;
    setState(() {
      _validPaths = results.isEmpty ? widget.assetPaths : results;
      _index = 0;
      _ready = true;
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_validPaths.length <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final current = _pageController.page?.round() ?? _index;
        final lastIndex = _validPaths.length - 1;
        if (current >= lastIndex) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final paths = _validPaths;
    final dotActive = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: paths.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _AdVideoTile(key: ValueKey(paths[i]), assetPath: paths[i]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(paths.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? dotActive : dotActive.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}
