import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _contraCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _verContrasena = false;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_correoCtrl.text.trim(), _contraCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          // Fondo con gradiente radial
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A0A22), Color(0xFF080C14)],
              ),
            ),
          ),
          // Decoraciones de palos de cartas
          Positioned(
            top: -40,
            left: -40,
            child: AuthSuitDecor(suit: '♠', size: 200, opacity: 0.04),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: AuthSuitDecor(suit: '♥', size: 180, opacity: 0.05, color: Colors.red),
          ),
          Positioned(
            top: size.height * 0.4,
            left: -20,
            child: AuthSuitDecor(suit: '♣', size: 120, opacity: 0.03),
          ),
          Positioned(
            top: 80,
            right: -10,
            child: AuthSuitDecor(suit: '♦', size: 130, opacity: 0.04, color: Colors.red),
          ),
          // Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthLogoSection(),
                    const SizedBox(height: 40),
                    AuthGlassCard(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bienvenido de vuelta',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                            const SizedBox(height: 28),
                            AuthCampoTexto(
                              controller: _correoCtrl,
                              label: 'Correo electrónico',
                              icono: Icons.alternate_email_rounded,
                              tipo: TextInputType.emailAddress,
                              validador: (v) =>
                                  v == null || v.isEmpty ? 'Ingresa tu correo' : null,
                            ),
                            const SizedBox(height: 16),
                            AuthCampoTexto(
                              controller: _contraCtrl,
                              label: 'Contraseña',
                              icono: Icons.lock_outline_rounded,
                              ocultarTexto: !_verContrasena,
                              sufijo: IconButton(
                                onPressed: () =>
                                    setState(() => _verContrasena = !_verContrasena),
                                icon: Icon(
                                  _verContrasena
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                              validador: (v) =>
                                  v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                            ),
                            if (auth.error != null) ...[
                              const SizedBox(height: 14),
                              AuthErrorBanner(mensaje: auth.error!),
                            ],
                            const SizedBox(height: 28),
                            AuthBotonPrimario(
                              texto: 'Ingresar',
                              cargando: auth.cargando,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/registro'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: Color(0xFFE94560),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
