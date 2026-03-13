import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
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
    if (ok) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GameBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AuthLogoSection(),
                  const SizedBox(height: 40),
                  AuthGlassCard(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Encabezado del form
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.goldLight,
                                      AppColors.goldDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: GoogleFonts.rajdhani(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Bienvenido de vuelta',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
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
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                            validador: (v) => v == null || v.isEmpty
                                ? 'Ingresa tu contraseña'
                                : null,
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: 16),
                            AuthErrorBanner(mensaje: auth.error!),
                          ],
                          const SizedBox(height: 28),
                          AuthBotonPrimario(
                            texto: 'INGRESAR',
                            cargando: auth.cargando,
                            onPressed: _login,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/registro'),
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          'Regístrate',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
    );
  }
}
