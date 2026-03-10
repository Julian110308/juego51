import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarToken()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const _AuthGate(),
        '/home': (_) => const HomeScreen(),
        '/registro': (_) => const RegistroScreen(),
        '/juego': (_) => const GameScreen(),
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
