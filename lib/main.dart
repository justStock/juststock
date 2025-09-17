import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

Route<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Brand palette: Yellow focused
    // - Primary (bright): #FFD200
    // - Dark Yellow (header/accent): #F7971E
    const brandYellow = Color(0xFFFFD200);
    const brandYellowDark = Color(0xFFF7971E);
    const adDark = brandYellowDark;
    return MaterialApp(
      title: 'NewJustStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Yellow primary with darker yellow accents; white surfaces
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandYellow,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandYellow,
          secondary: brandYellowDark,
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: brandYellowDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Subtle light background so symbol images pop
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: brandYellow, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: brandYellowDark),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(brandYellow),
            foregroundColor: const MaterialStatePropertyAll(Colors.white),
          ),
        ),
      ),
      home: const SplashPage(),
      );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_fadeRoute(const LoginRegisterPage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final scale = 0.95 + 0.05 * sin(2 * pi * t);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: 2 * pi * t,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.25),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.show_chart,
                            size: 46,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'JustStock',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: cs.primary.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  bool _sendingOtp = false;

  Future<void> _onContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();

    setState(() => _sendingOtp = true);
    final res = await AuthService.requestOtp(mobile, name: name);
    setState(() => _sendingOtp = false);

    if (!mounted) return;
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      Navigator.of(context).push(
        _fadeRoute(
          OtpVerifyPage(
            name: name,
            mobile: mobile,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    final accent = colorScheme.secondary;
    return Scaffold(
      // Slight off-white around the login box
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              color: Colors.white, // make login box pure white
              surfaceTintColor: Colors.transparent, // avoid M3 elevation tint
              shadowColor: accent.withOpacity(0.20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0x16000000)),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Let's Get Started",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please sign in to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          // Name
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.black87),
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your name';
                              if (v.trim().length < 2) return 'Name seems too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Mobile
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              counterText: '',
                              prefixIcon: Icon(Icons.phone_iphone, color: Colors.black87),
                              filled: true,
                              fillColor: Color(0xFFF6F7FB),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Please enter your mobile number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter a valid 10-digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          // CTA
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: FilledButton(
                                style: ButtonStyle(
                                  shape: const MaterialStatePropertyAll(StadiumBorder()),
                                  elevation: const MaterialStatePropertyAll(6),
                                  shadowColor: MaterialStatePropertyAll(accent.withOpacity(0.35)),
                                  backgroundColor: MaterialStatePropertyAll(color),
                                  foregroundColor: const MaterialStatePropertyAll(Colors.white),
                                ),
                                onPressed: _sendingOtp ? null : _onContinue,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_sendingOtp) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Text(
                                      'Login',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We will send an OTP to verify your number.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.black.withOpacity(0.75)),
                              ),
                              GestureDetector(
                                onTap: _onContinue,
                                child: Text(
                                  'Sign up',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: accent, fontWeight: FontWeight.w800),
                                  ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpVerifyPage extends StatefulWidget {
  final String name;
  final String mobile;

  const OtpVerifyPage({
    super.key,
    required this.name,
    required this.mobile,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _verified = false;
  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _verifying = true);
    final res = await AuthService.verifyOtp(mobile: widget.mobile, otp: _otpController.text.trim());
    setState(() => _verifying = false);

    if (!mounted) return;
    if (res.ok) {
      setState(() => _verified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(HomePage(name: widget.name, mobile: widget.mobile)),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    }
  }

  Future<void> _resend() async {
    final res = await AuthService.requestOtp(widget.mobile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.primary;
    String masked = widget.mobile;
    if (masked.length >= 4) {
      masked = '******' + masked.substring(masked.length - 4);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0x16000000)),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sms, color: color),
                        const SizedBox(width: 8),
                        Text(
                          'OTP Verification',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code sent to $masked',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                          hintText: '······',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Please enter the OTP';
                          if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter a valid 6-digit OTP';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _verified || _verifying ? null : _verify,
                        child: _verifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_verified ? 'Verified' : 'Verify'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resend,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                      child: const Text('Resend OTP'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Didn\'t receive the code? Tap resend.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String name;
  final String mobile;
  const HomePage({super.key, required this.name, required this.mobile});

  String get _initial => (name.trim().isNotEmpty ? name.trim()[0] : 'U').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart, color: Colors.white),
            const SizedBox(width: 8),
            const Text('JustStock'),
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
                  _fadeRoute(ProfilePage(name: name, mobile: mobile)),
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
          // Compute a pleasant circle diameter based on width
          final double circleDiameter = width >= 1100
              ? 132
              : width >= 820
                  ? 120
                  : width >= 600
                      ? 110
                      : 100;

          final cs = Theme.of(context).colorScheme;
          final List<_HomeItem> items = [
            _HomeItem('NIFTY', Icons.trending_up, cs.primary, 'assets/symbols/nifty50.png'),
            _HomeItem('BANKNIFTY', Icons.account_balance, cs.secondary, 'assets/symbols/banknifty.png'),
            _HomeItem('STOCKS', Icons.stacked_bar_chart, cs.primary, 'assets/symbols/stocks.png'),
            _HomeItem('SENSEX', Icons.timeline, cs.secondary, 'assets/symbols/sensex.png'),
            _HomeItem('COMMODITY', Icons.oil_barrel, cs.primary, 'assets/symbols/commodity.png'),
          ];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${name.trim().isEmpty ? 'User' : name.trim()}!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                // Centered, wrapping circular shortcuts
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
                          onTap: () {
                            debugPrint('Tapped on ${item.title}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.title} tapped')),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _AdsSlider(
                  primary: color,
                  assetPaths: const [
                    'assets/ads/ad_low_js.mp4',
                    'assets/ads/free_acc.mp4',
                    'assets/ads/add3.mp4',
                  ],
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}


class ProfilePage extends StatelessWidget {
  final String name;
  final String mobile;

  const ProfilePage({super.key, required this.name, required this.mobile});

  String get _displayName => name.trim().isEmpty ? 'User' : name.trim();
  String get _initial => _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';

  String get _referenceCode {
    final digitsOnly = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 'JS000000';
    }
    final padded = digitsOnly.padLeft(6, '0');
    final suffix = padded.substring(padded.length - 6);
    return 'JS' + suffix;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.secondary, scheme.primary],
    );
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4DF),
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.24),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.secondary,
                    child: Text(
                      _initial,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: scheme.secondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'User Dashboard',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: scheme.primary.withOpacity(0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Full name',
                      value: _displayName,
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoRow(
                      icon: Icons.phone_iphone,
                      label: 'Registered mobile',
                      value: mobile,
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Reference code',
                      value: _referenceCode,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  _fadeRoute(const LoginRegisterPage()),
                  (route) => false,
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: scheme.secondary,
                foregroundColor: Colors.white,
                textStyle: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: const Color(0xFF7A7A7A),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    );
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: const Color(0xFF1F1F1F),
      fontWeight: FontWeight.w600,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.secondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 4),
              Text(value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
class _HomeCircleTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double diameter;
  final String? imageAsset;

  const _HomeCircleTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.diameter,
    this.imageAsset,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1.0,
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
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            color,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: diameter * 0.44,
                          color: Colors.white,
                        ),
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

class _HomeItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? imageAsset;
  const _HomeItem(this.title, this.icon, this.color, [this.imageAsset]);
}

class _AdCard extends StatefulWidget {
  final Color primary;
  final String? assetPath; // optional explicit asset to play
  const _AdCard({super.key, required this.primary, this.assetPath});

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  VideoPlayerController? _video;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _initVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the requested asset changes, reload the video for this card
    if (widget.assetPath != oldWidget.assetPath) {
      _video?.dispose();
      _video = null;
      _initialized = false;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    // If assetPath is provided, only try that path for this card.
    // This prevents both pages from falling back to the same file.
    final pathsToTry = widget.assetPath != null
        ? <String>[widget.assetPath!]
        : <String>[
            'assets/ads/ad_low_js.mp4',
            'assets/ads/free_acc.mp4',
            'assets/ads/ad low js.mp4',
            'assets/ads/Buy call at 100.mp4',
          ];

    for (final assetPath in pathsToTry) {
      VideoPlayerController? c;
      try {
        await rootBundle.load(assetPath);
        c = VideoPlayerController.asset(assetPath);
        await c.initialize();
        c
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        _video?.dispose();
        _video = c;
        if (mounted) setState(() => _initialized = true);
        debugPrint('Ad video loaded: $assetPath');
        return;
      } catch (e) {
        debugPrint('Ad video failed for $assetPath: $e');
        await c?.dispose();
      }
    }
    if (mounted) setState(() => _initialized = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1 loop
        return Card(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AspectRatio(
                aspectRatio: (_video != null && _video!.value.isInitialized && _video!.value.aspectRatio > 0)
                    ? _video!.value.aspectRatio
                    : 16 / 9,
                child: Stack(
                  children: [
                    Container(color: Colors.black),
                    // Show the asset video full-bleed
                    Positioned.fill(
                      child: _initialized && _video != null && _video!.value.isInitialized
                          ? VideoPlayer(_video!)
                          : Container(
                              color: Colors.black,
                              child: const Center(
                                child: Text(
                                  'Loading ad video...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Tap layer: toggle play/pause
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_video == null) return;
                            if (_video!.value.isPlaying) {
                              _video!.pause();
                            } else {
                              _video!.play();
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shadowText(String text, double size) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(offset: Offset(2, 2), blurRadius: 2, color: Color(0x80FFD200)),
        ],
      ),
    );
  }
}

class _AdsSlider extends StatefulWidget {
  final List<String> assetPaths;
  final Color primary;
  const _AdsSlider({super.key, required this.assetPaths, required this.primary});

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
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AdsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPaths.join('|') != widget.assetPaths.join('|')) {
      _timer?.cancel();
      _prepareAssets();
    }
  }

  Future<void> _prepareAssets() async {
    final results = <String>[];
    for (final p in widget.assetPaths) {
      try {
        await rootBundle.load(p);
        results.add(p);
      } catch (_) {
        debugPrint('Ad asset missing, skipping: $p');
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
      _timer = Timer.periodic(const Duration(seconds: 4), (t) {
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
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
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
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _AdCard(
                key: ValueKey(paths[i]),
                primary: widget.primary,
                assetPath: paths[i],
              ),
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
                    : Theme.of(context).colorScheme.primary.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CandleBgPainter extends CustomPainter {
  final double progress; // 0..1
  _CandleBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    // Use brand yellow (#FFD200) tints
    final base = Paint()..color = const Color(0xFFFFD200).withOpacity(0.22);
    final wick = Paint()
      ..color = const Color(0xFFFFD200).withOpacity(0.32)
      ..strokeWidth = 2;

    final width = size.width;
    final height = size.height;
    final count = 20;
    final offsetX = (progress * 40) % 40; // slow pan
    for (int i = -2; i < count; i++) {
      final x = i * 40.0 + offsetX;
      final h = 30 + rnd.nextInt(80);
      final top = height / 2 - h / 2 + rnd.nextInt(30) - 15;
      final body = Rect.fromLTWH(x.toDouble(), top.toDouble(), 18, h.toDouble());
      canvas.drawRect(body, base);
      // wick
      canvas.drawLine(Offset(x + 9, top - 12), Offset(x + 9, top + h + 12), wick);
    }
  }

  @override
  bool shouldRepaint(covariant _CandleBgPainter oldDelegate) => oldDelegate.progress != progress;
}

class _LeftBarsPainter extends CustomPainter {
  final double glow; // 0..1
  _LeftBarsPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    // Four ascending bars with arrow cap
    final baseY = h * 0.75;
    final widths = [w * 0.12, w * 0.2, w * 0.28, w * 0.36];
    for (int i = 0; i < 4; i++) {
      final x = w * 0.1 + i * (w * 0.15);
      final barTop = baseY - widths[i] * 1.2;
      path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, barTop, w * 0.08, baseY - barTop), const Radius.circular(6)));
    }
    // Upward arrow line
    final arrow = Path()
      ..moveTo(w * 0.05, baseY - 10)
      ..lineTo(w * 0.42, baseY - widths[3] * 1.25)
      ..lineTo(w * 0.42 - 10, baseY - widths[3] * 1.25 + 10)
      ..moveTo(w * 0.42, baseY - widths[3] * 1.25)
      ..lineTo(w * 0.42 - 12, baseY - widths[3] * 1.25 - 2);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final lineShadow = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // draw shadow then white
    canvas.save();
    canvas.translate(3, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(arrow, lineShadow);
    canvas.restore();

    // subtle glow on top of white
    canvas.drawPath(path, stroke);
    canvas.drawPath(arrow, line);
  }

  @override
  bool shouldRepaint(covariant _LeftBarsPainter oldDelegate) => oldDelegate.glow != glow;
}

