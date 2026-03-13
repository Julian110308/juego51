import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class UsuarioService {
  final String token;
  UsuarioService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> getPerfil() async {
    final res = await http.get(Uri.parse(Api.perfil), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener perfil');
  }

  Future<Map<String, dynamic>> getEstadisticas() async {
    final res = await http.get(Uri.parse(Api.estadisticas), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener estadísticas');
  }

  Future<List<Map<String, dynamic>>> getHistorial({int limite = 20}) async {
    final uri = Uri.parse(Api.historial)
        .replace(queryParameters: {'limite': '$limite'});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('Error al obtener historial');
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final res = await http.get(Uri.parse(Api.leaderboard), headers: _headers);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    throw Exception('Error al obtener leaderboard');
  }
}
