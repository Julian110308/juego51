import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Juego 51', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino, size: 100, color: Color(0xFFE94560)),
              const SizedBox(height: 32),
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 48),
              _BotonJuego(
                texto: 'Jugar vs IA (Fácil)',
                icono: Icons.smart_toy,
                color: const Color(0xFF0F3460),
                onTap: () => _iniciarPartida(context, auth, game, 'facil'),
              ),
              const SizedBox(height: 16),
              _BotonJuego(
                texto: 'Jugar vs IA (Medio)',
                icono: Icons.smart_toy,
                color: const Color(0xFF533483),
                onTap: () => _iniciarPartida(context, auth, game, 'medio'),
              ),
              const SizedBox(height: 16),
              _BotonJuego(
                texto: 'Jugar vs IA (Difícil)',
                icono: Icons.smart_toy,
                color: const Color(0xFFE94560),
                onTap: () => _iniciarPartida(context, auth, game, 'dificil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _iniciarPartida(
    BuildContext context,
    AuthProvider auth,
    GameProvider game,
    String dificultad,
  ) async {
    game.init(auth.token!);
    game.resetear();
    final ok = await game.crearPartida(dificultad: dificultad);
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushNamed(context, '/juego');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(game.error ?? 'Error al crear partida')),
      );
    }
  }
}

class _BotonJuego extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonJuego({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, color: Colors.white),
        label: Text(texto,
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
