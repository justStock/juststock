import 'package:flutter/material.dart';

import 'package:newjuststock/core/navigation/fade_route.dart';
import 'package:newjuststock/features/home/presentation/pages/home_page.dart';
import 'package:newjuststock/services/auth_service.dart';
import 'package:newjuststock/services/session_service.dart';

class OtpVerifyPage extends StatefulWidget {
  final String name;
  final String mobile;

  const OtpVerifyPage({super.key, required this.name, required this.mobile});

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
    final res = await AuthService.verifyOtp(
      mobile: widget.mobile,
      otp: _otpController.text.trim(),
    );
    setState(() => _verifying = false);

    if (!mounted) return;
    if (res.ok) {
      final data = res.data;
      final token = _extractToken(data);
      final resolvedName = _extractName(data);

      await _persistSession(token, resolvedName);
      if (!mounted) return;

      setState(() => _verified = true);
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('OTP verified successfully.')),
        );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(
            HomePage(
              name: resolvedName,
              mobile: widget.mobile,
              token: token.isNotEmpty ? token : null,
            ),
          ),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  Future<void> _persistSession(String token, String resolvedName) async {
    if (token.isNotEmpty) {
      await SessionService.saveSession(
        AuthSession(token: token, name: resolvedName, mobile: widget.mobile),
      );
    } else {
      await SessionService.clearSession();
    }
  }

  Future<void> _resend() async {
    final res = await AuthService.requestOtp(widget.mobile);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(res.message)));
  }

  String _extractToken(Map<String, dynamic>? data) {
    if (data == null) return '';
    final candidates = [
      data['token'],
      data['accessToken'],
      data['access_token'],
      data['jwt'],
      data['sessionToken'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    for (final nestedKey in ['data', 'result', 'payload']) {
      final nested = data[nestedKey];
      if (nested is Map<String, dynamic>) {
        final token = _extractToken(nested);
        if (token.isNotEmpty) {
          return token;
        }
      }
    }
    return '';
  }

  String _extractName(Map<String, dynamic>? data) {
    if (data == null) return widget.name;
    final candidates = [
      data['name'],
      data['fullName'],
      data['username'],
      if (data['user'] is Map<String, dynamic>)
        (data['user'] as Map<String, dynamic>)['name'],
      if (data['profile'] is Map<String, dynamic>)
        (data['profile'] as Map<String, dynamic>)['name'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return widget.name;
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
      appBar: AppBar(title: const Text('Verify OTP')),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                        style: const TextStyle(
                          letterSpacing: 8,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                          hintText: '------',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Please enter the OTP';
                          if (!RegExp(r'^\d{6}$').hasMatch(value))
                            return 'Enter a valid 6-digit OTP';
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_verified ? 'Verified' : 'Verify'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _resend,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                      ),
                      child: const Text('Resend OTP'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Didn\'t receive the code? Tap resend.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
