class Api {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String wsUrl = 'ws://127.0.0.1:8000';

  static const String login = '$baseUrl/auth/login';
  static const String registro = '$baseUrl/auth/registro';
  static const String me = '$baseUrl/auth/me';

  static const String crearPartida = '$baseUrl/partidas/crear';
  static String robar(int id) => '$baseUrl/partidas/$id/robar';
  static String bajar(int id) => '$baseUrl/partidas/$id/bajar';
  static String descartar(int id) => '$baseUrl/partidas/$id/descartar';
  static String agregar(int id) => '$baseUrl/partidas/$id/agregar';
  static String rendirse(int id) => '$baseUrl/partidas/$id/rendirse';

  static String wsSala(int idSala, String token) =>
      '$wsUrl/ws/sala/$idSala?token=$token';
}
