import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
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
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.black, size: 18),
              const SizedBox(width: 10),
              Text(
                'Cuenta creada. Inicia sesión.',
                style: GoogleFonts.inter(
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.gold, size: 18),
                    ),
                    Text(
                      'Crear cuenta',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
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
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          const AuthLogoSection(),
                          const SizedBox(height: 32),
                          AuthGlassCard(
                            child: Form(
                              key: _form,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
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
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nueva cuenta',
                                            style: GoogleFonts.rajdhani(
                                              color: AppColors.textPrimary,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Completa los datos para comenzar',
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
                                    controller: _nombreCtrl,
                                    label: 'Nombre de usuario',
                                    icono: Icons.person_outline_rounded,
                                    validador: (v) =>
                                        v == null || v.isEmpty
                                            ? 'Ingresa un nombre'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  AuthCampoTexto(
                                    controller: _correoCtrl,
                                    label: 'Correo electrónico',
                                    icono: Icons.alternate_email_rounded,
                                    tipo: TextInputType.emailAddress,
                                    validador: (v) =>
                                        v == null || v.isEmpty
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
                                      onPressed: () => setState(() =>
                                          _verContrasena = !_verContrasena),
                                      icon: Icon(
                                        _verContrasena
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: AppColors.textMuted,
                                        size: 20,
                                      ),
                                    ),
                                    validador: (v) =>
                                        v == null || v.length < 6
                                            ? 'Mínimo 6 caracteres'
                                            : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 12,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Al menos 6 caracteres',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 16),
                                    AuthErrorBanner(mensaje: auth.error!),
                                  ],
                                  const SizedBox(height: 28),
                                  AuthBotonPrimario(
                                    texto: 'CREAR CUENTA',
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
                              Text(
                                '¿Ya tienes cuenta?',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'Inicia sesión',
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
            ],
          ),
        ),
      ),
    );
  }
}
