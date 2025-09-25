import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:newjuststock/services/api_config.dart';

class ApiResponse {
  final bool ok;
  final int status;
  final Map<String, dynamic>? data;
  final String message;

  ApiResponse({
    required this.ok,
    required this.status,
    this.data,
    required this.message,
  });
}

class AuthService {
  static String get _base => '${ApiConfig.apiBaseUrl}/api/auth';

  static String _extractMessage(
    Map<String, dynamic>? json,
    int status,
    String raw,
  ) {
    if (json == null) return raw.isNotEmpty ? raw : 'HTTP $status';
    final keys = ['message', 'msg', 'error', 'detail'];
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    if (json['errors'] is List && (json['errors'] as List).isNotEmpty) {
      return (json['errors'] as List).first.toString();
    }
    return raw.isNotEmpty ? raw : 'HTTP $status';
  }

  static Future<ApiResponse> requestOtp(String mobile, {String? name}) async {
    final uri = Uri.parse('$_base/request-otp');

    final attempts =
        <({Map<String, String> headers, Object body, String note})>[
          (
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'mobile': mobile,
              if (name != null && name.isNotEmpty) 'name': name,
            }),
            note: 'json mobile',
          ),
          (
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'phone': mobile,
              if (name != null && name.isNotEmpty) 'name': name,
            }),
            note: 'json phone',
          ),
          (
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=utf-8',
              'Accept': 'application/json',
            },
            body: {
              'mobile': mobile,
              if (name != null && name.isNotEmpty) 'name': name,
            },
            note: 'form mobile',
          ),
          (
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=utf-8',
              'Accept': 'application/json',
            },
            body: {
              'phone': mobile,
              if (name != null && name.isNotEmpty) 'name': name,
            },
            note: 'form phone',
          ),
        ];

    ApiResponse? last;
    for (final a in attempts) {
      try {
        final res = await http.post(uri, headers: a.headers, body: a.body);
        final status = res.statusCode;
        Map<String, dynamic>? json;
        try {
          json = res.body.isNotEmpty
              ? jsonDecode(res.body) as Map<String, dynamic>?
              : null;
        } catch (_) {
          json = null;
        }
        final msg = _extractMessage(json, status, res.body);

        // Debug aid while integrating
        // ignore: avoid_print
        print('[request-otp ${a.note}] -> HTTP $status, body: ${res.body}');

        if (status >= 200 && status < 300) {
          return ApiResponse(
            ok: true,
            status: status,
            data: json,
            message: msg,
          );
        }

        last = ApiResponse(ok: false, status: status, data: json, message: msg);
      } catch (e) {
        last = ApiResponse(
          ok: false,
          status: -1,
          data: null,
          message: 'Network error: $e',
        );
      }
    }
    return last ??
        ApiResponse(
          ok: false,
          status: -1,
          data: null,
          message: 'Failed to request OTP',
        );
  }

  static Future<ApiResponse> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final uri = Uri.parse('$_base/verify-otp');

    final attempts =
        <({Map<String, String> headers, Object body, String note})>[
          (
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'mobile': mobile, 'otp': otp}),
            note: 'json mobile',
          ),
          (
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': mobile, 'otp': otp}),
            note: 'json phone',
          ),
          (
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=utf-8',
              'Accept': 'application/json',
            },
            body: {'mobile': mobile, 'otp': otp},
            note: 'form mobile',
          ),
          (
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=utf-8',
              'Accept': 'application/json',
            },
            body: {'phone': mobile, 'otp': otp},
            note: 'form phone',
          ),
        ];

    ApiResponse? last;
    for (final a in attempts) {
      try {
        final res = await http.post(uri, headers: a.headers, body: a.body);
        final status = res.statusCode;
        Map<String, dynamic>? json;
        try {
          json = res.body.isNotEmpty
              ? jsonDecode(res.body) as Map<String, dynamic>?
              : null;
        } catch (_) {
          json = null;
        }
        final msg = _extractMessage(json, status, res.body);

        // Debug aid while integrating
        // ignore: avoid_print
        print('[verify-otp ${a.note}] -> HTTP $status, body: ${res.body}');

        if (status >= 200 && status < 300) {
          return ApiResponse(
            ok: true,
            status: status,
            data: json,
            message: msg,
          );
        }
        last = ApiResponse(ok: false, status: status, data: json, message: msg);
      } catch (e) {
        last = ApiResponse(
          ok: false,
          status: -1,
          data: null,
          message: 'Network error: $e',
        );
      }
    }
    return last ??
        ApiResponse(
          ok: false,
          status: -1,
          data: null,
          message: 'OTP verification failed',
        );
  }
}
