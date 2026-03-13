class Api {
  static const String baseUrl = 'http://localhost:8000';
  static const String wsUrl = 'ws://localhost:8000';

  static const String login = '$baseUrl/auth/login';
  static const String registro = '$baseUrl/auth/registro';
  static const String me = '$baseUrl/auth/me';

  static const String crearPartida = '$baseUrl/partidas/crear';
  static String robar(int id) => '$baseUrl/partidas/$id/robar';
  static String bajar(int id) => '$baseUrl/partidas/$id/bajar';
  static String descartar(int id) => '$baseUrl/partidas/$id/descartar';
  static String agregar(int id) => '$baseUrl/partidas/$id/agregar';
  static String rendirse(int id) => '$baseUrl/partidas/$id/rendirse';
  static String swap(int id) => '$baseUrl/partidas/$id/swap';

  static String wsSala(int idSala, String token) =>
      '$wsUrl/ws/sala/$idSala?token=$token';

  static const String crearSala = '$baseUrl/salas/crear';
  static String unirseASala(String codigo) =>
      '$baseUrl/salas/unirse?codigo_sala=$codigo';

  static const String perfil = '$baseUrl/usuarios/perfil';
  static const String estadisticas = '$baseUrl/usuarios/estadisticas';
  static const String historial = '$baseUrl/usuarios/historial';
  static const String leaderboard = '$baseUrl/usuarios/leaderboard';
}
