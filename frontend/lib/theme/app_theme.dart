import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SISTEMA DE DISEÑO — JUEGO 51
//  Inspirado en interfaces de casino premium (PokerStars, GGPoker)
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  // Fondos
  static const bg         = Color(0xFF080B12);   // negro azulado profundo
  static const bgCard     = Color(0xFF0F1420);   // panel oscuro
  static const bgElevated = Color(0xFF161D2E);   // panel elevado
  static const bgOverlay  = Color(0xFF1C2438);   // overlay

  // Dorado premium
  static const gold       = Color(0xFFFFB800);
  static const goldLight  = Color(0xFFFFD55E);
  static const goldDark   = Color(0xFFB8800A);
  static const goldMuted  = Color(0xFF6B5010);

  // Acento rojo/energía
  static const accent     = Color(0xFFE63946);
  static const accentDark = Color(0xFF9E1B26);

  // Colores de estado
  static const success    = Color(0xFF00C896);
  static const successDark= Color(0xFF007A5C);
  static const info       = Color(0xFF3B82F6);
  static const infoDark   = Color(0xFF1D4ED8);
  static const danger     = Color(0xFFEF4444);
  static const dangerDark = Color(0xFF991B1B);
  static const warning    = Color(0xFFF59E0B);

  // Texto
  static const textPrimary   = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);

  // Bordes
  static const border     = Color(0xFF1E2A3E);
  static const borderGold = Color(0xFF4A3800);
}

class AppTextStyles {
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 1.5,
      );

  static TextStyle heading(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 0.8,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle label(double size, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textMuted,
        letterSpacing: 1.5,
      );

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.gold,
        letterSpacing: 3,
      );
}

// ─── ThemeData global ─────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.accent,
          surface: AppColors.bgCard,
          error: AppColors.danger,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          titleTextStyle: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.goldLight,
            letterSpacing: 2,
          ),
          iconTheme: const IconThemeData(color: AppColors.gold),
        ),
        useMaterial3: true,
      );
}

// ─── Componentes reutilizables ────────────────────────────────────────────────

/// Tarjeta con borde y fondo oscuro premium
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.radius = 16,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );
  }
}

/// Badge/chip de estado
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón primario con gradiente
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? fromColor;
  final Color? toColor;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.fromColor,
    this.toColor,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final from = fromColor ?? AppColors.gold;
    final to = toColor ?? AppColors.goldDark;
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: [from, to])
              : null,
          color: enabled ? null : AppColors.bgOverlay,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: from.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.black87),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.rajdhani(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Botón secundario (outline)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.info;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c.withAlpha(180), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: c, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Campo de texto premium
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;
  final int? maxLength;
  final TextAlign? textAlign;
  final TextStyle? style;
  final String? hintText;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.capitalization = TextCapitalization.none,
    this.maxLength,
    this.textAlign,
    this.style,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: capitalization,
      maxLength: maxLength,
      textAlign: textAlign ?? TextAlign.start,
      style: style ??
          GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: '',
        labelStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 12,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textMuted, size: 18)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.bgElevated,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
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

/// Divisor decorativo con texto central
class AppDivider extends StatelessWidget {
  final String? label;
  const AppDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.border],
              ),
            ),
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              label!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.border, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Banner de error
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(20),
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
              message,
              style: GoogleFonts.inter(
                color: AppColors.danger,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo de pantalla con gradiente y decoraciones
class GameBackground extends StatelessWidget {
  final Widget child;
  final bool withSuits;

  const GameBackground({
    super.key,
    required this.child,
    this.withSuits = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.8,
              colors: [Color(0xFF0D1B35), AppColors.bg],
            ),
          ),
        ),
        if (withSuits) ...[
          const Positioned(
            top: -50, left: -60,
            child: _SuitWatermark(suit: '♠', size: 280, opacity: 0.018),
          ),
          const Positioned(
            bottom: -20, right: -60,
            child: _SuitWatermark(
                suit: '♥', size: 260, opacity: 0.022, red: true),
          ),
          const Positioned(
            top: 260, right: -30,
            child: _SuitWatermark(
                suit: '♦', size: 160, opacity: 0.018, red: true),
          ),
          const Positioned(
            bottom: 200, left: -25,
            child: _SuitWatermark(suit: '♣', size: 180, opacity: 0.015),
          ),
        ],
        child,
      ],
    );
  }
}

class _SuitWatermark extends StatelessWidget {
  final String suit;
  final double size;
  final double opacity;
  final bool red;

  const _SuitWatermark({
    required this.suit,
    required this.size,
    required this.opacity,
    this.red = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      suit,
      style: TextStyle(
        fontSize: size,
        color: (red ? const Color(0xFFE63946) : Colors.white)
            .withValues(alpha: opacity),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Stat card compacta
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color.withAlpha(160),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
