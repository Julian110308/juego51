import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contraCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _verContrasena = false;

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registro(
      _nombreCtrl.text.trim(),
      _correoCtrl.text.trim(),
      _contraCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Cuenta creada. Inicia sesión.'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
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
          // Fondo — mismo sistema visual que login
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, 0.2),
                radius: 1.3,
                colors: [Color(0xFF0A1A22), Color(0xFF080C14)],
              ),
            ),
          ),
          // Decoraciones de palos de cartas
          Positioned(
            top: -50,
            right: -40,
            child: AuthSuitDecor(suit: '♦', size: 210, opacity: 0.04, color: Colors.red),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: AuthSuitDecor(suit: '♣', size: 190, opacity: 0.03),
          ),
          Positioned(
            top: size.height * 0.35,
            right: -10,
            child: AuthSuitDecor(suit: '♠', size: 110, opacity: 0.03),
          ),
          // Contenido
          SafeArea(
            child: Column(
              children: [
                // Barra de navegación personalizada
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                      ),
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            const AuthLogoSection(),
                            const SizedBox(height: 32),
                            AuthGlassCard(
                              child: Form(
                                key: _form,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Nueva cuenta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Completa los datos para comenzar',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 13),
                                    ),
                                    const SizedBox(height: 28),
                                    AuthCampoTexto(
                                      controller: _nombreCtrl,
                                      label: 'Nombre de usuario',
                                      icono: Icons.person_outline_rounded,
                                      validador: (v) => v == null || v.isEmpty
                                          ? 'Ingresa un nombre'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    AuthCampoTexto(
                                      controller: _correoCtrl,
                                      label: 'Correo electrónico',
                                      icono: Icons.alternate_email_rounded,
                                      tipo: TextInputType.emailAddress,
                                      validador: (v) => v == null || v.isEmpty
                                          ? 'Ingresa tu correo'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    AuthCampoTexto(
                                      controller: _contraCtrl,
                                      label: 'Contraseña',
                                      icono: Icons.lock_outline_rounded,
                                      ocultarTexto: !_verContrasena,
                                      sufijo: IconButton(
                                        onPressed: () => setState(
                                            () => _verContrasena = !_verContrasena),
                                        icon: Icon(
                                          _verContrasena
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                      ),
                                      validador: (v) => v == null || v.length < 6
                                          ? 'Mínimo 6 caracteres'
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline,
                                            size: 13, color: Colors.white24),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Al menos 6 caracteres',
                                          style: TextStyle(
                                              color: Colors.white24, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (auth.error != null) ...[
                                      const SizedBox(height: 14),
                                      AuthErrorBanner(mensaje: auth.error!),
                                    ],
                                    const SizedBox(height: 28),
                                    AuthBotonPrimario(
                                      texto: 'Crear cuenta',
                                      cargando: auth.cargando,
                                      onPressed: _registrar,
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
                                  '¿Ya tienes cuenta?',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8)),
                                  child: const Text(
                                    'Inicia sesión',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
