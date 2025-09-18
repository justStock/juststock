import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:newjuststock/core/navigation/fade_route.dart';
import 'package:newjuststock/features/auth/presentation/pages/login_register_page.dart';
import 'package:newjuststock/features/profile/presentation/pages/profile_page.dart';
import 'package:newjuststock/services/session_service.dart';
import 'package:newjuststock/services/segment_service.dart';

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

  static const List<_SegmentDescriptor> _segmentDescriptors = [
    _SegmentDescriptor(
      key: 'nifty',
      title: 'NIFTY',
      icon: Icons.trending_up,
      tone: _SegmentTone.primary,
      asset: 'assets/symbols/nifty50.png',
    ),
    _SegmentDescriptor(
      key: 'banknifty',
      title: 'BANKNIFTY',
      icon: Icons.account_balance,
      tone: _SegmentTone.secondary,
      asset: 'assets/symbols/banknifty.png',
    ),
    _SegmentDescriptor(
      key: 'stocks',
      title: 'STOCKS',
      icon: Icons.stacked_bar_chart,
      tone: _SegmentTone.primary,
      asset: 'assets/symbols/stocks.png',
    ),
    _SegmentDescriptor(
      key: 'sensex',
      title: 'SENSEX',
      icon: Icons.timeline,
      tone: _SegmentTone.secondary,
      asset: 'assets/symbols/sensex.png',
    ),
    _SegmentDescriptor(
      key: 'commodity',
      title: 'COMMODITY',
      icon: Icons.oil_barrel,
      tone: _SegmentTone.primary,
      asset: 'assets/symbols/commodity.png',
    ),
  ];

  final Map<String, SegmentMessage> _segmentMessages = {};
  final Map<String, String> _acknowledgedMessages = {};
  bool _loadingSegments = false;
  String? _segmentsError;

  @override
  void initState() {
    super.initState();
    _loadSegments();
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
      if (!silently) {
        _showSnack('Session expired. Please log in again.');
      }
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

    if (!mounted) return;
    setState(() {
      _acknowledgedMessages[item.segmentKey] = message;
    });
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
    final color = scheme.primary;
    final items = _segmentDescriptors
        .map(
          (descriptor) => _HomeItem(
            title: descriptor.title,
            icon: descriptor.icon,
            color: descriptor.tone == _SegmentTone.secondary
                ? scheme.secondary
                : scheme.primary,
            segmentKey: descriptor.key,
            imageAsset: descriptor.asset,
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
                foregroundColor: color,
                child: Text(_initial),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final circleDiameter = width >= 1100
              ? 132.0
              : width >= 820
              ? 120.0
              : width >= 600
              ? 110.0
              : 100.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RefreshIndicator(
              onRefresh: () => _loadSegments(silently: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_displayName!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
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
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final item in items)
                            _HomeCircleTile(
                              title: item.title,
                              icon: item.icon,
                              color: item.color,
                              imageAsset: item.imageAsset,
                              diameter: circleDiameter,
                              hasNotification: _isSegmentUnread(
                                item.segmentKey,
                              ),
                              onTap: () => _handleSegmentTap(item),
                            ),
                        ],
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
    return '$day $month $year ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ $hour:$minute $period';
  }
}

class _SegmentDescriptor {
  final String key;
  final String title;
  final IconData icon;
  final _SegmentTone tone;
  final String asset;

  const _SegmentDescriptor({
    required this.key,
    required this.title,
    required this.icon,
    required this.tone,
    required this.asset,
  });
}

enum _SegmentTone { primary, secondary }

class _HomeItem {
  final String title;
  final IconData icon;
  final Color color;
  final String segmentKey;
  final String? imageAsset;

  const _HomeItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.segmentKey,
    this.imageAsset,
  });
}

class _HomeCircleTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double diameter;
  final String? imageAsset;
  final bool hasNotification;

  const _HomeCircleTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.diameter,
    this.imageAsset,
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
    final color = widget.color;
    final onTap = widget.onTap;
    final diameter = widget.diameter;
    final imageAsset = widget.imageAsset;
    final hasNotification = widget.hasNotification;

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
          width: diameter + 16,
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
                          colors: [color, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(
                              hasNotification ? 0.55 : 0.25,
                            ),
                            blurRadius: hasNotification ? 22 : 14,
                            spreadRadius: hasNotification ? 1.5 : 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (imageAsset != null && imageAsset.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset(
                                imageAsset,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Icon(
                              icon,
                              size: diameter * 0.44,
                              color: Colors.white,
                            ),
                          if (hasNotification)
                            Positioned(
                              top: 16,
                              right: 18,
                              child: _NotificationBadge(
                                glowColor: color,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatefulWidget {
  final Color glowColor;
  final Color color;

  const _NotificationBadge({required this.glowColor, required this.color});

  @override
  State<_NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<_NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.6, end: 1).animate(curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.15).animate(curve),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.7),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            : const Center(child: CircularProgressIndicator()),
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
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final paths = _validPaths;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
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
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}
