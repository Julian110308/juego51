import 'package:flutter/material.dart';
import '../services/partida_service.dart';

class GameProvider extends ChangeNotifier {
  PartidaService? _service;
  Map<String, dynamic>? _estado;
  int? _idPartida;
  int? _idJugadorPartida;
  bool _cargando = false;
  String? _error;
  List<Map<String, dynamic>> _iaLog = [];
  List<int> _seleccionadas = [];
  List<Map<String, dynamic>> _combinacionesPendientes = [];

  Map<String, dynamic>? get estado => _estado;
  int? get idPartida => _idPartida;
  int? get idJugadorPartida => _idJugadorPartida;
  bool get cargando => _cargando;
  String? get error => _error;
  List<Map<String, dynamic>> get iaLog => _iaLog;
  List<int> get seleccionadas => _seleccionadas;
  List<Map<String, dynamic>> get combinacionesPendientes => _combinacionesPendientes;

  void init(String token) {
    _service = PartidaService(token);
  }

  void toggleSeleccion(int iid) {
    if (_seleccionadas.contains(iid)) {
      _seleccionadas.remove(iid);
    } else {
      _seleccionadas.add(iid);
    }
    notifyListeners();
  }

  void limpiarSeleccion() {
    _seleccionadas.clear();
    notifyListeners();
  }

  void agregarCombinacionPendiente(String tipo) {
    if (_seleccionadas.isEmpty) return;
    _combinacionesPendientes.add({'tipo': tipo, 'iids': _seleccionadas.toList()});
    _seleccionadas.clear();
    _error = null;
    notifyListeners();
  }

  void quitarCombinacionPendiente(int index) {
    _combinacionesPendientes.removeAt(index);
    notifyListeners();
  }

  void limpiarPendientes() {
    _combinacionesPendientes.clear();
    _seleccionadas.clear();
    notifyListeners();
  }

  Future<bool> crearPartida({String dificultad = 'medio', int numIas = 1}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service!.crearPartida(dificultadIa: dificultad, numIas: numIas);
      _idPartida = res['id_partida'];
      _idJugadorPartida = res['id_jugador_partida'];
      _estado = res['estado'];
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> robar({String fuente = 'mazo'}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service!.robar(_idPartida!, fuente: fuente);
      _estado = res['estado'];
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> descartar(int iidCarta) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service!.descartar(_idPartida!, iidCarta);
      _estado = res['estado'];
      _iaLog = List<Map<String, dynamic>>.from(res['ia_log'] ?? []);
      limpiarSeleccion();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> agregarACombinacion(int idxMesa) async {
    if (_seleccionadas.isEmpty) return false;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service!.agregar(_idPartida!, idxMesa, _seleccionadas.toList());
      _estado = res['estado'];
      limpiarSeleccion();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> bajarPendientes() async {
    return bajar(_combinacionesPendientes.toList());
  }

  Future<bool> bajar(List<Map<String, dynamic>> combinaciones) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service!.bajar(_idPartida!, combinaciones);
      _estado = res['estado'];
      _combinacionesPendientes.clear();
      limpiarSeleccion();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> rendirse() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _service!.rendirse(_idPartida!);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? get miEstado {
    if (_estado == null || _idJugadorPartida == null) return null;
    final jugadores = _estado!['jugadores'] as Map<String, dynamic>?;
    return jugadores?['$_idJugadorPartida'] as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> get miMano {
    final mano = miEstado?['mano'];
    if (mano == null) return [];
    return List<Map<String, dynamic>>.from(mano);
  }

  bool get esMiTurno {
    if (_estado == null || _idJugadorPartida == null) return false;
    return _estado!['jugador_activo'] == _idJugadorPartida;
  }

  bool get faseAcciones => _estado?['fase'] == 'acciones';
  bool get finalizada => _estado?['finalizada'] == true;

  void resetear() {
    _estado = null;
    _idPartida = null;
    _idJugadorPartida = null;
    _iaLog = [];
    _seleccionadas = [];
    _error = null;
    notifyListeners();
  }
}
