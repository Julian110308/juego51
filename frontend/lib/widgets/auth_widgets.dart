import 'package:flutter/material.dart';

// ─── Logo ────────────────────────────────────────────────────────────────────

class AuthLogoSection extends StatelessWidget {
  const AuthLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFE94560), Color(0xFF6B0020)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94560).withAlpha(100),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.casino_rounded, color: Colors.white, size: 46),
        ),
        const SizedBox(height: 16),
        const Text(
          'JUEGO 51',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rummy · Estrategia · Diversión',
          style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

// ─── Panel glassmorphism ──────────────────────────────────────────────────────

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 30,
            offset: const Offset(0, 8),
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: tipo,
      obscureText: ocultarTexto,
      validator: validador,
      cursorColor: const Color(0xFFE94560),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: Color(0xFFE94560), fontSize: 13),
        prefixIcon: Icon(icono, color: Colors.white38, size: 20),
        suffixIcon: sufijo,
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE94560), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
        color: Colors.redAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE94560), Color(0xFFA01535)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE94560).withAlpha(80),
              blurRadius: 14,
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
                borderRadius: BorderRadius.circular(14)),
          ),
          child: cargando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Decoración de palo de carta ──────────────────────────────────────────────

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
