import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  String? _token;
  bool _cargando = false;
  String? _error;

  String? get token => _token;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get autenticado => _token != null;

  Future<void> cargarToken() async {
    _token = await _service.getToken();
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _token = await _service.login(correo, contrasena);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registro(String nombreUsuario, String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _service.registro(nombreUsuario, correo, contrasena);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _token = null;
    notifyListeners();
  }
}
