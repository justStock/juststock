import 'dart:math';

import 'package:flutter/material.dart';

import 'package:newjuststock/core/navigation/fade_route.dart';
import 'package:newjuststock/features/auth/presentation/pages/otp_verify_page.dart';
import 'package:newjuststock/services/auth_service.dart';

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
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.of(
        context,
      ).push(fadeRoute(OtpVerifyPage(name: name, mobile: mobile)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.message)));
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
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Let's Get Started",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please sign in to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          // Name
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Colors.black87,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Please enter your name';
                              if (v.trim().length < 2)
                                return 'Name seems too short';
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
                              prefixIcon: Icon(
                                Icons.phone_iphone,
                                color: Colors.black87,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF6F7FB),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty)
                                return 'Please enter your mobile number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value))
                                return 'Enter a valid 10-digit number';
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
                                  shape: const MaterialStatePropertyAll(
                                    StadiumBorder(),
                                  ),
                                  elevation: const MaterialStatePropertyAll(6),
                                  shadowColor: MaterialStatePropertyAll(
                                    accent.withOpacity(0.35),
                                  ),
                                  backgroundColor: MaterialStatePropertyAll(
                                    color,
                                  ),
                                  foregroundColor:
                                      const MaterialStatePropertyAll(
                                        Colors.white,
                                      ),
                                ),
                                onPressed: _sendingOtp ? null : _onContinue,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_sendingOtp) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.black.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.black.withOpacity(0.75),
                                    ),
                              ),
                              GestureDetector(
                                onTap: _onContinue,
                                child: Text(
                                  'Sign up',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                      ),
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
      final body = Rect.fromLTWH(
        x.toDouble(),
        top.toDouble(),
        18,
        h.toDouble(),
      );
      canvas.drawRect(body, base);
      // wick
      canvas.drawLine(
        Offset(x + 9, top - 12),
        Offset(x + 9, top + h + 12),
        wick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandleBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barTop, w * 0.08, baseY - barTop),
          const Radius.circular(6),
        ),
      );
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
  bool shouldRepaint(covariant _LeftBarsPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
