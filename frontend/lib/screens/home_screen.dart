import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _NavBar(auth: auth),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeroBanner(),
                          const SizedBox(height: 32),
                          _SectionHeader(
                            icon: Icons.smart_toy_rounded,
                            title: 'JUGAR VS IA',
                            subtitle: 'Elige tu nivel de dificultad',
                          ),
                          const SizedBox(height: 14),
                          // Fácil
                          _ModeCard(
                            title: 'Modo Fácil',
                            description:
                                'La IA comete errores estratégicos. Perfecto para aprender las reglas.',
                            icon: Icons.spa_rounded,
                            badge: 'PRINCIPIANTE',
                            badgeColor: AppColors.success,
                            accentColor: AppColors.success,
                            gradient: const [
                              Color(0xFF0A2016),
                              Color(0xFF071410),
                            ],
                            onTap: () =>
                                _iniciarPartida(context, auth, game, 'facil'),
                          ),
                          const SizedBox(height: 10),
                          // Medio
                          _ModeCard(
                            title: 'Modo Medio',
                            description:
                                'Desafío equilibrado. La IA analiza y planifica sus movimientos.',
                            icon: Icons.psychology_rounded,
                            badge: 'INTERMEDIO',
                            badgeColor: AppColors.info,
                            accentColor: AppColors.info,
                            gradient: const [
                              Color(0xFF081628),
                              Color(0xFF050E1A),
                            ],
                            onTap: () =>
                                _iniciarPartida(context, auth, game, 'medio'),
                          ),
                          const SizedBox(height: 10),
                          // Difícil
                          _ModeCard(
                            title: 'Modo Difícil',
                            description:
                                '¿Puedes vencer a una IA que juega al máximo nivel estratégico?',
                            icon: Icons.local_fire_department_rounded,
                            badge: 'EXPERTO',
                            badgeColor: AppColors.danger,
                            accentColor: AppColors.danger,
                            gradient: const [
                              Color(0xFF2A0808),
                              Color(0xFF180505),
                            ],
                            onTap: () =>
                                _iniciarPartida(context, auth, game, 'dificil'),
                          ),
                          const SizedBox(height: 28),
                          _SectionHeader(
                            icon: Icons.public_rounded,
                            title: 'MULTIJUGADOR',
                            subtitle: 'Juega contra personas reales',
                          ),
                          const SizedBox(height: 14),
                          _OnlineBanner(
                            onTap: () =>
                                Navigator.pushNamed(context, '/lobby'),
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
        SnackBar(
          content: Text(game.error ?? 'Error al crear partida',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.dangerDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// ─── Barra de navegación ──────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final AuthProvider auth;
  const _NavBar({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withAlpha(200),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.goldLight, AppColors.goldDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withAlpha(80),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.style_rounded,
                color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
            ).createShader(bounds),
            child: Text(
              'JUEGO 51',
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          // Botón perfil
          _NavButton(
            icon: Icons.person_rounded,
            label: 'PERFIL',
            onTap: () => Navigator.pushNamed(context, '/perfil'),
          ),
          const SizedBox(width: 8),
          // Botón salir
          _NavButton(
            icon: Icons.logout_rounded,
            label: 'SALIR',
            color: AppColors.danger,
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner hero ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1400), Color(0xFF0D0E1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGold),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(25),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBadge(
                  text: 'RUMMY · ESTRATEGIA',
                  color: AppColors.gold,
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.goldLight,
                      AppColors.gold,
                      AppColors.goldLight,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'JUEGO\nDE 51',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Forma combinaciones, supera los 51 puntos\ny gana la partida.',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Naipes decorativos
          SizedBox(
            width: 80,
            height: 100,
            child: Stack(
              children: [
                _MiniCard(
                  left: 20,
                  top: 0,
                  rotation: 0.15,
                  suit: '♠',
                  value: 'K',
                  color: AppColors.textPrimary,
                ),
                _MiniCard(
                  left: 0,
                  top: 20,
                  rotation: -0.1,
                  suit: '♥',
                  value: 'A',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final double left, top, rotation;
  final String suit, value;
  final Color color;

  const _MiniCard({
    required this.left,
    required this.top,
    required this.rotation,
    required this.suit,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 52,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EDD8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                suit,
                style: TextStyle(color: color, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withAlpha(50)),
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Tarjeta de modo ──────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final Color accentColor;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: gradient, begin: Alignment.topLeft),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withAlpha(70)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor.withAlpha(70)),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.rajdhani(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(text: badge, color: badgeColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: accentColor, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banner multijugador ──────────────────────────────────────────────────────
class _OnlineBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OnlineBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1400), Color(0xFF0A0D1A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withAlpha(100)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withAlpha(40),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.goldDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(80),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Colors.black87, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'En Línea',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.goldLight,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            text: 'EN VIVO',
                            color: AppColors.success,
                            icon: Icons.circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crea o únete a una sala privada. Invita a tus amigos con un código.',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.gold, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
