import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api.dart';
import 'game_provider.dart';

class SalaProvider extends GameProvider {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  int? _idSala;
  String? _codigoSala;
  String _estadoSala = 'esperando'; // esperando | en_juego | finalizada
  List<Map<String, dynamic>> _chat = [];

  int? get idSala => _idSala;
  String? get codigoSala => _codigoSala;
  String get estadoSala => _estadoSala;
  List<Map<String, dynamic>> get chat => List.unmodifiable(_chat);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── HTTP: crear / unirse ────────────────────────────────────────────────────

  Future<bool> crearSala(
    String token, {
    String tipo = 'privada',
    int maxJugadores = 2,
    String dificultad = 'medio',
  }) async {
    updateError(null);
    try {
      final res = await http.post(
        Uri.parse(Api.crearSala),
        headers: _headers(token),
        body: jsonEncode({
          'tipo_sala': tipo,
          'max_jugadores': maxJugadores,
          'dificultad_ia': dificultad,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idSala = data['id_sala'] as int;
        _codigoSala = data['codigo_sala'] as String?;
        updateIdJugadorPartida(data['id_jugador_partida'] as int);
        _conectarWs(token);
        notifyListeners();
        return true;
      }
      updateError(
          (jsonDecode(res.body) as Map)['detail'] as String? ?? 'Error al crear sala');
      return false;
    } catch (e) {
      updateError(e.toString());
      return false;
    }
  }

  Future<bool> unirseASala(String token, String codigo) async {
    updateError(null);
    try {
      final res = await http.post(
        Uri.parse(Api.unirseASala(codigo)),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idSala = data['id_sala'] as int;
        _codigoSala = data['codigo_sala'] as String?;
        updateIdJugadorPartida(data['id_jugador_partida'] as int);
        _conectarWs(token);
        notifyListeners();
        return true;
      }
      updateError(
          (jsonDecode(res.body) as Map)['detail'] as String? ?? 'Error al unirse');
      return false;
    } catch (e) {
      updateError(e.toString());
      return false;
    }
  }

  // ── WebSocket ───────────────────────────────────────────────────────────────

  void _conectarWs(String token) {
    if (_idSala == null) return;
    final uri = Uri.parse(Api.wsSala(_idSala!, token));
    _channel = WebSocketChannel.connect(uri);
    _sub = _channel!.stream.listen(
      (raw) => _onMensaje(raw as String),
      onError: (_) => updateError('Conexión perdida'),
      onDone: () {},
    );
  }

  void _onMensaje(String raw) {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    final tipo = msg['tipo'] as String?;

    switch (tipo) {
      case 'estado':
        updateCargando(false);
        updateEstado(msg['datos'] as Map<String, dynamic>?);

      case 'jugada':
        updateCargando(false);
        updateEstado(msg['datos'] as Map<String, dynamic>?);
        final iaLog = msg['ia_log'] as List?;
        if (iaLog != null) {
          updateIaLog(List<Map<String, dynamic>>.from(iaLog));
        }

      case 'sala_lista':
        _estadoSala = 'en_juego';
        notifyListeners();

      case 'ronda_terminada':
        final pens = (msg['penalizaciones'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), v as int));
        updateResultadoFin({
          'ronda_terminada': true,
          'ganador': msg['ganador'],
          'penalizaciones': pens,
        });
        _estadoSala = 'finalizada';
        notifyListeners();

      case 'chat':
        _chat = [
          ..._chat,
          {
            'autor': msg['autor'] as String? ?? '?',
            'mensaje': msg['mensaje'] as String? ?? '',
            'hora': msg['hora'] as String? ?? '',
          }
        ];
        notifyListeners();

      case 'conectado':
      case 'desconectado':
        _chat = [
          ..._chat,
          {
            'autor': '— Sistema —',
            'mensaje': tipo == 'conectado'
                ? '${msg['jugador']} se conectó'
                : '${msg['jugador']} se desconectó',
            'hora': '',
          }
        ];
        notifyListeners();

      case 'error':
        updateError(msg['detalle'] as String?);
    }
  }

  void _enviar(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  void enviarChat(String mensaje) {
    if (mensaje.trim().isEmpty) return;
    _enviar({'tipo': 'chat', 'mensaje': mensaje.trim()});
  }

  // ── Override acciones (WS en vez de REST) ──────────────────────────────────

  @override
  Future<bool> robar({String fuente = 'mazo'}) async {
    updateCargando(true);
    _enviar({'tipo': 'robar', 'fuente': fuente});
    return true;
  }

  @override
  Future<bool> descartar(int iidCarta) async {
    updateCargando(true);
    _enviar({'tipo': 'descartar', 'iid_carta': iidCarta});
    limpiarSeleccion();
    return true;
  }

  @override
  Future<bool> bajar(List<Map<String, dynamic>> combinaciones) async {
    updateCargando(true);
    _enviar({'tipo': 'bajar', 'combinaciones': combinaciones});
    limpiarPendientes();
    return true;
  }

  @override
  Future<bool> agregarACombinacion(int idxMesa) async {
    if (seleccionadas.isEmpty) return false;
    updateCargando(true);
    _enviar({'tipo': 'agregar', 'idx_mesa': idxMesa, 'iids': seleccionadas.toList()});
    limpiarSeleccion();
    return true;
  }

  @override
  Future<bool> swap(int idxMesa, int iidCartaReal, int iidJoker) async {
    updateCargando(true);
    _enviar({
      'tipo': 'swap',
      'idx_mesa': idxMesa,
      'iid_carta_real': iidCartaReal,
      'iid_joker': iidJoker,
    });
    limpiarSeleccion();
    return true;
  }

  @override
  Future<bool> rendirse() async {
    _enviar({'tipo': 'rendirse'});
    return true;
  }

  // ── Reset ───────────────────────────────────────────────────────────────────

  @override
  void resetear() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _sub = null;
    _idSala = null;
    _codigoSala = null;
    _estadoSala = 'esperando';
    _chat = [];
    super.resetear();
  }
}
