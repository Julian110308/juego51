import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Logo ─────────────────────────────────────────────────────────────────────
class AuthLogoSection extends StatelessWidget {
  const AuthLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icono con múltiples capas de glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow exterior
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(40),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Anillo dorado
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.goldLight,
                    AppColors.goldDark,
                    AppColors.gold,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(120),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Interior oscuro
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
              ),
              child: const Icon(
                Icons.style_rounded,
                color: AppColors.gold,
                size: 40,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Título con shader
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold, AppColors.goldLight],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'JUEGO 51',
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'RUMMY  ·  ESTRATEGIA  ·  DIVERSIÓN',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Card del formulario ──────────────────────────────────────────────────────
class AuthGlassCard extends StatelessWidget {
  final Widget child;
  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.gold.withAlpha(10),
            blurRadius: 60,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Campo de texto ───────────────────────────────────────────────────────────
class AuthCampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final TextInputType tipo;
  final bool ocultarTexto;
  final Widget? sufijo;
  final String? Function(String?)? validador;

  const AuthCampoTexto({
    super.key,
    required this.controller,
    required this.label,
    required this.icono,
    this.tipo = TextInputType.text,
    this.ocultarTexto = false,
    this.sufijo,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      keyboardType: tipo,
      obscureText: ocultarTexto,
      validator: validador,
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 12,
        ),
        prefixIcon: Icon(icono, color: AppColors.textMuted, size: 18),
        suffixIcon: sufijo,
        filled: true,
        fillColor: AppColors.bgElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(color: AppColors.danger, fontSize: 11),
      ),
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────
class AuthErrorBanner extends StatelessWidget {
  final String mensaje;
  const AuthErrorBanner({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón primario ───────────────────────────────────────────────────────────
class AuthBotonPrimario extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback onPressed;

  const AuthBotonPrimario({
    super.key,
    required this.texto,
    required this.cargando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: cargando
              ? null
              : const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldDark],
                ),
          color: cargando ? AppColors.bgOverlay : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cargando
              ? null
              : [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: cargando ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: cargando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: AppColors.gold, strokeWidth: 2.5),
                )
              : Text(
                  texto,
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Decoración de palo ───────────────────────────────────────────────────────
class AuthSuitDecor extends StatelessWidget {
  final String suit;
  final double size;
  final double opacity;
  final Color color;

  const AuthSuitDecor({
    super.key,
    required this.suit,
    required this.size,
    required this.opacity,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      suit,
      style: TextStyle(
        fontSize: size,
        color: color.withValues(alpha: opacity),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
