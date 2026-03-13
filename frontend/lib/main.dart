import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/sala_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/lobby_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarToken()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SalaProvider()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juego 51',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const _AuthGate(),
        '/home': (_) => const HomeScreen(),
        '/registro': (_) => const RegistroScreen(),
        '/juego': (_) => const GameScreen(),
        '/perfil': (_) => const ProfileScreen(),
        '/lobby': (_) => const LobbyScreen(),
        // Ruta sala: provee SalaProvider como GameProvider al GameScreen
        '/juego-sala': (ctx) => ChangeNotifierProvider<GameProvider>.value(
              value: ctx.read<SalaProvider>(),
              child: const GameScreen(),
            ),
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.autenticado) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
