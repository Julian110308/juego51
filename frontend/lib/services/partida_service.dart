import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class PartidaService {
  final String token;
  PartidaService(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> crearPartida({
    String modoJuego = 'cpu',
    String dificultadIa = 'medio',
    int numIas = 1,
  }) async {
    final res = await http.post(
      Uri.parse(Api.crearPartida),
      headers: _headers,
      body: jsonEncode({
        'modo_juego': modoJuego,
        'dificultad_ia': dificultadIa,
        'num_ias': numIas,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al crear partida');
  }

  Future<Map<String, dynamic>> robar(int idPartida, {String fuente = 'mazo'}) async {
    final uri = Uri.parse(Api.robar(idPartida)).replace(
      queryParameters: {'fuente': fuente},
    );
    final res = await http.post(uri, headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al robar');
  }

  Future<Map<String, dynamic>> descartar(int idPartida, int iidCarta) async {
    final res = await http.post(
      Uri.parse(Api.descartar(idPartida)),
      headers: _headers,
      body: jsonEncode({'iid_carta': iidCarta}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al descartar');
  }

  Future<Map<String, dynamic>> agregar(
      int idPartida, int idxMesa, List<int> iids) async {
    final res = await http.post(
      Uri.parse(Api.agregar(idPartida)),
      headers: _headers,
      body: jsonEncode({'idx_mesa': idxMesa, 'iids': iids}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al agregar');
  }

  Future<Map<String, dynamic>> bajar(
      int idPartida, List<Map<String, dynamic>> combinaciones) async {
    final res = await http.post(
      Uri.parse(Api.bajar(idPartida)),
      headers: _headers,
      body: jsonEncode({'combinaciones': combinaciones}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al bajar');
  }

  Future<Map<String, dynamic>> rendirse(int idPartida) async {
    final res = await http.post(
      Uri.parse(Api.rendirse(idPartida)),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Error al rendirse');
  }
}
