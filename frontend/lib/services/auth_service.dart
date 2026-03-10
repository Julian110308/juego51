import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthService {
  static const _tokenKey = 'token';

  Future<String?> login(String correo, String contrasena) async {
    final res = await http.post(
      Uri.parse(Api.login),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': correo, 'password': contrasena},
    );
    if (res.statusCode == 200) {
      final token = jsonDecode(res.body)['access_token'] as String;
      await _guardarToken(token);
      return token;
    }
    final detail = jsonDecode(res.body)['detail'] ?? 'Error al iniciar sesión';
    throw Exception(detail);
  }

  Future<void> registro(String nombreUsuario, String correo, String contrasena) async {
    final res = await http.post(
      Uri.parse(Api.registro),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_usuario': nombreUsuario,
        'correo': correo,
        'contrasena': contrasena,
      }),
    );
    if (res.statusCode != 201) {
      final detail = jsonDecode(res.body)['detail'] ?? 'Error al registrarse';
      throw Exception(detail);
    }
  }

  Future<void> _guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
