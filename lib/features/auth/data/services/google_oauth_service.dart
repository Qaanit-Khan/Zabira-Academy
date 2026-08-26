import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

/// Zabira Academy — Google OAuth Service
///
/// Implements web-based OAuth 2.0 with Google using flutter_web_auth_2.
/// Does NOT require SHA-1 fingerprint or Firebase native configuration.
/// Works on any Android/iOS device using the system browser.
///
/// Setup required on Google Cloud Console:
/// - OAuth 2.0 Web application type client
/// - Authorized redirect URI: zabiraauth://callback
class GoogleOAuthService {
  GoogleOAuthService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _googleAuthUrl =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _googleTokenUrl =
      'https://oauth2.googleapis.com/token';
  static const String _callbackScheme = 'zabiraauth';
  static const String _callbackUrl = 'zabiraauth://callback';

  /// Launches a browser-based Google sign-in.
  /// [clientId] must be a Web-type OAuth 2.0 client ID from Google Cloud Console.
  Future<GoogleOAuthResult> signIn({required String clientId}) async {
    final authUri = Uri.parse(_googleAuthUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': _callbackUrl,
        'response_type': 'code',
        'scope': 'openid email profile',
        'access_type': 'offline',
        'prompt': 'select_account',
      },
    );

    debugPrint('[GOOGLE OAUTH] Starting web auth: $authUri');

    final String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
          useWebview: false,
        ),
      );
    } catch (e) {
      debugPrint('[GOOGLE OAUTH] Error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') ||
          msg.contains('user_cancelled') ||
          msg.contains('dismiss')) {
        throw const GoogleOAuthException('Google sign-in was cancelled.');
      }
      throw GoogleOAuthException('Google sign-in failed: $e');
    }

    debugPrint('[GOOGLE OAUTH] Callback: $resultUrl');

    final uri = Uri.parse(resultUrl);
    final error = uri.queryParameters['error'];
    if (error != null) {
      throw GoogleOAuthException('Google auth error: $error');
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const GoogleOAuthException(
          'No authorization code received from Google.');
    }

    return _exchangeCodeForTokens(code: code, clientId: clientId);
  }

  Future<GoogleOAuthResult> _exchangeCodeForTokens({
    required String code,
    required String clientId,
  }) async {
    debugPrint('[GOOGLE OAUTH] Exchanging auth code for tokens...');
    try {
      final response = await _client
          .post(
            Uri.parse(_googleTokenUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'code': code,
              'client_id': clientId,
              'redirect_uri': _callbackUrl,
              'grant_type': 'authorization_code',
            },
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[GOOGLE OAUTH] Token response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final err = decoded['error_description'] ??
            decoded['error'] ??
            'Token exchange failed (${response.statusCode})';
        throw GoogleOAuthException(err.toString());
      }

      final idToken = decoded['id_token']?.toString();
      final accessToken = decoded['access_token']?.toString();

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw const GoogleOAuthException(
            'Google did not return a usable token.');
      }

      // Decode id_token JWT payload to extract user claims
      String? email, name, sub, picture;
      if (idToken != null && idToken.isNotEmpty) {
        try {
          final parts = idToken.split('.');
          if (parts.length >= 2) {
            var payload = parts[1];
            while (payload.length % 4 != 0) {
              payload += '=';
            }
            final claims = jsonDecode(
              utf8.decode(base64Url.decode(payload)),
            ) as Map<String, dynamic>;
            email = claims['email']?.toString();
            name = claims['name']?.toString();
            sub = claims['sub']?.toString();
            picture = claims['picture']?.toString();
          }
        } catch (e) {
          debugPrint('[GOOGLE OAUTH] Could not decode id_token: $e');
        }
      }

      // Fallback: fetch userinfo endpoint with access token
      if ((email == null || email.isEmpty) && accessToken != null) {
        try {
          final info = await _client
              .get(
                Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
                headers: {'Authorization': 'Bearer $accessToken'},
              )
              .timeout(const Duration(seconds: 10));
          if (info.statusCode == 200) {
            final j = jsonDecode(info.body) as Map<String, dynamic>;
            email ??= j['email']?.toString();
            name ??= j['name']?.toString();
            sub ??= j['sub']?.toString();
            picture ??= j['picture']?.toString();
          }
        } catch (_) {
          debugPrint('[GOOGLE OAUTH] Could not fetch userinfo');
        }
      }

      return GoogleOAuthResult(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        name: name,
        googleId: sub,
        photoUrl: picture,
      );
    } on GoogleOAuthException {
      rethrow;
    } catch (e) {
      throw GoogleOAuthException('Token exchange error: $e');
    }
  }
}

/// Result of a successful Google OAuth web sign-in
class GoogleOAuthResult {
  const GoogleOAuthResult({
    this.idToken,
    this.accessToken,
    this.email,
    this.name,
    this.googleId,
    this.photoUrl,
  });

  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? name;
  final String? googleId;
  final String? photoUrl;

  /// Best credential to forward to the Zabira backend
  String? get credential => idToken ?? accessToken;
}

class GoogleOAuthException implements Exception {
  const GoogleOAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
