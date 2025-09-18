import 'dart:math';

import 'package:flutter/material.dart';

import 'package:newjuststock/core/navigation/fade_route.dart';
import 'package:newjuststock/features/auth/presentation/pages/login_register_page.dart';
import 'package:newjuststock/features/home/presentation/pages/home_page.dart';
import 'package:newjuststock/services/session_service.dart';

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _bootstrap();
  }

  void _bootstrap() {
    Future.microtask(() async {
      final session = await SessionService.loadSession();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      if (session != null && session.isValid) {
        Navigator.of(context).pushReplacement(
          fadeRoute(
            HomePage(
              name: session.name.isEmpty ? 'User' : session.name,
              mobile: session.mobile,
              token: session.token,
            ),
          ),
        );
      } else {
        Navigator.of(
          context,
        ).pushReplacement(fadeRoute(const LoginRegisterPage()));
      }
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
