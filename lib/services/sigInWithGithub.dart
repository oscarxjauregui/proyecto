import 'dart:convert';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

class GitHubAuth {
  static Future<String?> authenticate() async {
    final clientId = 'Ov23lilBv6Z7j2zAmBbV';
    final clientSecret = 'https://SocialLynx.com';
    final redirectUrl = 'myapp://callback';
    final authorizationUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUrl&scope=read:user,user:email';

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authorizationUrl,
        callbackUrlScheme: "myapp",
      );

      final code = Uri.parse(result).queryParameters['code'];

      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code!,
          'redirect_uri': redirectUrl,
        },
      );

      final responseBody = json.decode(response.body);
      final accessToken = responseBody['access_token'];

      return accessToken;
    } catch (e) {
      print('Error durante la autenticación: $e');
      return null;
    }
  }
}
