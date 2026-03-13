import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import 'dart:math' as math;

// ─── Paleta de diseño premium ──────────────────────────────────────────────────
class _C {
  // Fondos
  static const bg          = Color(0xFF07090F);
  static const bgPanel     = Color(0xFF0D1117);
  static const bgCard      = Color(0xFF111827);

  // Mesa (tapete oscuro lujo)
  static const felt0       = Color(0xFF0C1829);
  static const felt1       = Color(0xFF071221);
  static const felt2       = Color(0xFF040C17);

  // Borde dorado
  static const gold        = Color(0xFFFFB800);
  static const goldLight   = Color(0xFFFFD55E);
  static const goldDark    = Color(0xFF8B6914);

  // Estados
  static const success     = Color(0xFF00C896);
  static const successDim  = Color(0xFF00402E);
  static const danger      = Color(0xFFEF4444);
  static const dangerDim   = Color(0xFF450A0A);
  static const info        = Color(0xFF3B82F6);
  static const orange      = Color(0xFFF97316);

  // Cartas
  static const cardFace    = Color(0xFFFFFFF8);
  static const cardRed     = Color(0xFFCC0000);
  static const cardBlack   = Color(0xFF111111);

  // Texto
  static const text1       = Color(0xFFE2E8F0);
  static const text2       = Color(0xFF94A3B8);
  static const text3       = Color(0xFF475569);
}

// ─── Pantalla principal ────────────────────────────────────────────────────────

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    if (game.estado == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.gold.withAlpha(40), width: 2),
                ),
                child: const CircularProgressIndicator(
                  color: _C.gold,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PREPARANDO LA MESA',
                style: GoogleFonts.rajdhani(
                  color: _C.goldLight.withAlpha(180),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (game.finalizada) return _PantallaFin(game: game);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(game: game),
            if (game.error != null) _ErrorStrip(mensaje: game.error!),
            if (game.iaLog.isNotEmpty) _LogIA(log: game.iaLog),
            Expanded(child: _Mesa(game: game)),
            _MiMano(game: game),
            _AccionesBar(game: game),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera premium ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final GameProvider game;
  const _Header({required this.game});

  @override
  Widget build(BuildContext context) {
    final esMiTurno = game.esMiTurno;
    final mazoRestante = game.estado?['mazo_restante'] ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 58,
      decoration: BoxDecoration(
        color: _C.bgPanel,
        border: Border(
          bottom: BorderSide(
            color: esMiTurno ? _C.gold.withAlpha(100) : Colors.white.withAlpha(15),
            width: 1,
          ),
        ),
        boxShadow: [
          if (esMiTurno)
            BoxShadow(color: _C.gold.withAlpha(20), blurRadius: 12),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // ── Izquierda: mazo count
            SizedBox(
              width: 70,
              child: Row(
                children: [
                  const Icon(Icons.style_rounded, color: _C.goldDark, size: 13),
                  const SizedBox(width: 5),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAZO', style: GoogleFonts.inter(color: _C.text3, fontSize: 7, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                      Text('$mazoRestante', style: GoogleFonts.rajdhani(color: _C.text1, fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            // ── Centro: título + turno (verdaderamente centrado)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_C.goldLight, _C.gold, _C.goldDark],
                    ).createShader(bounds),
                    child: Text(
                      'JUEGO 51',
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: esMiTurno ? _C.gold.withAlpha(25) : Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      esMiTurno ? '◆  TU TURNO' : '◆  TURNO IA',
                      style: GoogleFonts.inter(
                        color: esMiTurno ? _C.goldLight : _C.text3,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Derecha: estado + rendirse
            SizedBox(
              width: 110,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StatusPill(
                    label: game.miEstado?['bajado'] == true ? 'BAJADO' : 'SIN BAJAR',
                    active: game.miEstado?['bajado'] == true,
                  ),
                  const SizedBox(width: 2),
                  _HeaderIconBtn(
                    icon: Icons.flag_rounded,
                    color: _C.danger,
                    onTap: () => _rendirseDialog(context, game),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rendirseDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => _PremiumDialog(
        titulo: 'Rendirse',
        icono: Icons.flag_rounded,
        iconoColor: _C.danger,
        contenido: 'Perderás puntos por todas las cartas que tengas en mano.\n\n¿Estás seguro?',
        acciones: [
          _DialogAction(
            texto: 'Cancelar',
            onTap: () => Navigator.pop(context),
          ),
          _DialogAction(
            texto: 'Rendirse',
            color: _C.danger,
            onTap: () async {
              Navigator.pop(context);
              await game.rendirse();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(60), width: 1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _C.successDim : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? _C.success.withAlpha(120) : Colors.white.withAlpha(15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: active ? _C.success : _C.text3,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Mesa de juego ─────────────────────────────────────────────────────────────

class _Mesa extends StatelessWidget {
  final GameProvider game;
  const _Mesa({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _C.gold.withAlpha(18), blurRadius: 0, spreadRadius: 2),
          BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: _C.gold.withAlpha(40), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Fondo tapete premium
            Positioned.fill(
              child: CustomPaint(painter: _FeltPainter()),
            ),
            // Contenido
            Column(
              children: [
                _AiZone(game: game),
                _FeltDivider(label: 'BARAJA'),
                _BarajaZone(game: game),
                _FeltDivider(label: 'COMBINACIONES EN MESA'),
                Expanded(child: _CombinacionesScroll(game: game)),
                _MiPanelEnTapete(game: game),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente radial de fondo
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.2,
        colors: const [_C.felt0, _C.felt1, _C.felt2],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Patrón de puntos sutil
    final dotPaint = Paint()
      ..color = Colors.white.withAlpha(6)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    // Brillo central
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.8,
        colors: [Colors.white.withAlpha(10), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), glowPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FeltDivider extends StatelessWidget {
  final String label;
  const _FeltDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, _C.gold.withAlpha(40)]),
          ))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: _C.gold.withAlpha(80),
                fontSize: 7,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_C.gold.withAlpha(40), Colors.transparent]),
          ))),
        ],
      ),
    );
  }
}

// ─── Zona IA ───────────────────────────────────────────────────────────────────

class _AiZone extends StatelessWidget {
  final GameProvider game;
  const _AiZone({required this.game});

  @override
  Widget build(BuildContext context) {
    final jugadores = game.estado?['jugadores'] as Map<String, dynamic>? ?? {};
    final jugadorActivo = game.estado?['jugador_activo'];
    final otros = jugadores.entries
        .where((e) => int.tryParse(e.key) != game.idJugadorPartida)
        .toList();

    if (otros.isEmpty) return const SizedBox(height: 10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        children: otros.map((entry) {
          final id = int.tryParse(entry.key);
          final j = entry.value as Map<String, dynamic>;
          return Expanded(
            child: _AiPanel(
              numCartas: j['cartas_en_mano'] as int? ?? 0,
              bajado: j['bajado'] == true,
              esTurno: jugadorActivo == id,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  final int numCartas;
  final bool bajado;
  final bool esTurno;
  const _AiPanel({required this.numCartas, required this.bajado, required this.esTurno});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: esTurno
            ? LinearGradient(
                colors: [_C.gold.withAlpha(25), _C.gold.withAlpha(10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(colors: [Colors.black.withAlpha(100), Colors.black.withAlpha(60)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esTurno ? _C.gold.withAlpha(120) : Colors.white.withAlpha(15),
          width: esTurno ? 1.5 : 1,
        ),
        boxShadow: esTurno
            ? [BoxShadow(color: _C.gold.withAlpha(40), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        children: [
          // Avatar IA
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: esTurno
                    ? [_C.gold.withAlpha(80), _C.gold.withAlpha(20)]
                    : [Colors.white.withAlpha(25), Colors.white.withAlpha(8)],
              ),
              border: Border.all(
                color: esTurno ? _C.gold.withAlpha(150) : Colors.white.withAlpha(30),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: esTurno ? _C.goldLight : _C.text3,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Oponente',
                      style: GoogleFonts.inter(
                        color: esTurno ? _C.goldLight : _C.text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (bajado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _C.successDim,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _C.success.withAlpha(80)),
                        ),
                        child: Text('BAJADO', style: GoogleFonts.inter(color: _C.success, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    if (esTurno) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _C.gold.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('JUGANDO', style: GoogleFonts.inter(color: _C.goldLight, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                _CartasOcultas(numCartas: numCartas),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartasOcultas extends StatelessWidget {
  final int numCartas;
  const _CartasOcultas({required this.numCartas});

  @override
  Widget build(BuildContext context) {
    final mostrar = numCartas.clamp(0, 8);
    return Row(
      children: [
        ...List.generate(mostrar, (i) => Container(
          width: 12,
          height: 18,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)],
            ),
            border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
          ),
        )),
        if (numCartas > 8) ...[
          const SizedBox(width: 2),
          Text('+${numCartas - 8}', style: GoogleFonts.inter(color: _C.text3, fontSize: 9)),
        ],
        const SizedBox(width: 6),
        Text(
          '$numCartas cartas',
          style: GoogleFonts.inter(color: _C.text3, fontSize: 9, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Zona de Baraja ────────────────────────────────────────────────────────────

class _BarajaZone extends StatelessWidget {
  final GameProvider game;
  const _BarajaZone({required this.game});

  @override
  Widget build(BuildContext context) {
    final descarte = game.estado?['tope_descarte'];
    final mazoRestante = game.estado?['mazo_restante'] ?? 0;
    final puedeRobar = game.esMiTurno && !game.faseAcciones && !game.cargando;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mazo — tapeable para robar
          GestureDetector(
            onTap: puedeRobar ? () => game.robar() : null,
            child: _MazoStack(numCartas: mazoRestante, activo: puedeRobar),
          ),
          const SizedBox(width: 20),
          // Descarte — tapeable para robar
          GestureDetector(
            onTap: puedeRobar && descarte != null ? () => game.robar(fuente: 'descarte') : null,
            child: descarte != null
                ? _PilaDescarte(carta: descarte, activo: puedeRobar)
                : _SlotVacio(label: 'DESCARTE'),
          ),
        ],
      ),
    );
  }
}

class _MazoStack extends StatelessWidget {
  final int numCartas;
  final bool activo;
  const _MazoStack({required this.numCartas, this.activo = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sombras de cartas
              for (int i = 2; i >= 0; i--)
                Positioned(
                  left: i * 0.8,
                  top: i * 0.8,
                  child: Container(
                    width: 52,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: const Color(0xFF0D1F3C),
                      border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
                    ),
                  ),
                ),
              // Carta principal
              Positioned(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)],
                    ),
                    border: Border.all(
                      color: activo ? _C.gold : _C.gold.withAlpha(60),
                      width: activo ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 8, offset: const Offset(2, 4)),
                      if (activo)
                        BoxShadow(color: _C.gold.withAlpha(100), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: CustomPaint(painter: _DorsoPainter()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activo ? 'TAP PARA ROBAR' : 'MAZO · $numCartas',
          style: GoogleFonts.inter(
            color: activo ? _C.gold : _C.text3,
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PilaDescarte extends StatelessWidget {
  final Map<String, dynamic> carta;
  final bool activo;
  const _PilaDescarte({required this.carta, this.activo = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            boxShadow: activo
                ? [BoxShadow(color: _C.info.withAlpha(120), blurRadius: 16, spreadRadius: 2)]
                : null,
          ),
          child: _CartaGrande(carta: carta),
        ),
        const SizedBox(height: 4),
        Text(
          activo ? 'TAP PARA ROBAR' : 'DESCARTE',
          style: GoogleFonts.inter(
            color: activo ? _C.info : _C.text3,
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SlotVacio extends StatelessWidget {
  final String label;
  const _SlotVacio({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1, style: BorderStyle.solid),
            color: Colors.white.withAlpha(5),
          ),
          child: Icon(Icons.add_rounded, color: Colors.white.withAlpha(30), size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(color: _C.text3, fontSize: 9, letterSpacing: 1),
        ),
      ],
    );
  }
}

class _DorsoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Patrón de rombos
    const step = 10.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
    }

    // Borde interior dorado
    final borderPaint = Paint()
      ..color = const Color(0xFFFFB800).withAlpha(50)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final inset = 4.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
        const Radius.circular(4),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// Carta boca arriba (para descarte y mesa)
class _CartaGrande extends StatelessWidget {
  final Map<String, dynamic> carta;
  const _CartaGrande({required this.carta});

  Color get _suitColor {
    switch (carta['palo']) {
      case 'corazones':
      case 'diamantes': return _C.cardRed;
      default:          return _C.cardBlack;
    }
  }

  String get _simbolo {
    if (carta['es_joker'] == true) return '🃏';
    switch (carta['palo']) {
      case 'corazones': return '♥';
      case 'diamantes': return '♦';
      case 'treboles':  return '♣';
      case 'picas':     return '♠';
      default:          return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final esJoker = carta['es_joker'] == true;
    final valor = carta['valor'] ?? '';

    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: _C.cardFace,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.grey.shade600, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(200), blurRadius: 10, offset: const Offset(2, 5)),
          BoxShadow(color: _C.gold.withAlpha(30), blurRadius: 12),
        ],
      ),
      child: esJoker
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🃏', style: TextStyle(fontSize: 22)),
              Text('JOKER', style: GoogleFonts.inter(fontSize: 6, color: Colors.purple, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]))
          : Stack(
              children: [
                Positioned(left: 3, top: 1, child: _CornerLabel(valor, _simbolo, _suitColor, 10)),
                Center(child: Text(_simbolo, style: TextStyle(fontSize: 20, color: _suitColor))),
                Positioned(right: 3, bottom: 1, child: Transform.rotate(
                    angle: math.pi,
                    child: _CornerLabel(valor, _simbolo, _suitColor, 10))),
              ],
            ),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final String valor;
  final String simbolo;
  final Color color;
  final double size;
  const _CornerLabel(this.valor, this.simbolo, this.color, this.size);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(valor, style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w800, height: 1.0)),
        Text(simbolo, style: TextStyle(fontSize: size - 1, color: color, height: 1.0)),
      ],
    );
  }
}

// ─── Combinaciones en mesa ─────────────────────────────────────────────────────

class _CombinacionesScroll extends StatelessWidget {
  final GameProvider game;
  const _CombinacionesScroll({required this.game});

  @override
  Widget build(BuildContext context) {
    // El backend retorna: estado['mesa'] = [{propietario, combinacion: {tipo, cartas}}]
    final mesa = (game.estado?['mesa'] as List?) ?? [];

    if (mesa.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, color: Colors.white.withAlpha(20), size: 24),
            const SizedBox(height: 6),
            Text(
              'MESA VACÍA',
              style: GoogleFonts.inter(
                color: Colors.white.withAlpha(25),
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: mesa.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final comb = item['combinacion'] as Map<String, dynamic>? ?? {};
          final cartas = (comb['cartas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final tieneJoker = cartas.any((c) => c['es_joker'] == true);
          return _CombinacionEnMesa(
            cartas: cartas,
            indice: idx,
            game: game,
            tieneJoker: tieneJoker,
          );
        }).toList(),
      ),
    );
  }
}

class _CombinacionEnMesa extends StatelessWidget {
  final List<Map<String, dynamic>> cartas;
  final int indice;
  final GameProvider game;
  final bool tieneJoker;
  const _CombinacionEnMesa({
    required this.cartas,
    required this.indice,
    required this.game,
    required this.tieneJoker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tieneJoker ? _C.gold.withAlpha(60) : Colors.white.withAlpha(15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tieneJoker)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('★ COMODÍN', style: GoogleFonts.inter(color: _C.gold.withAlpha(160), fontSize: 7, letterSpacing: 1, fontWeight: FontWeight.w700)),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: cartas.map((c) {
              final esJoker = c['es_joker'] == true;
              return GestureDetector(
                onTap: esJoker && game.esMiTurno && game.faseAcciones && game.miEstado?['bajado'] == true
                    ? () => _swapDialog(context, c)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _CartaChip(carta: c, seleccionada: false, onTap: null, grande: false),
                ),
              );
            }).toList(),
          ),
          if (game.esMiTurno && game.faseAcciones && game.miEstado?['bajado'] == true) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                if (game.seleccionadas.isEmpty) return;
                game.agregarACombinacion(indice);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.info.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _C.info.withAlpha(60)),
                ),
                child: Text('+ PEGAR', style: GoogleFonts.inter(color: _C.info, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _swapDialog(BuildContext context, Map<String, dynamic> cartaJoker) {
    showDialog(
      context: context,
      builder: (_) => _PremiumDialog(
        titulo: 'Swap de Comodín',
        icono: Icons.swap_horiz_rounded,
        iconoColor: _C.gold,
        contenido: 'El Joker vuelve a tu mano y debes usarlo en esta jugada.',
        acciones: [
          _DialogAction(texto: 'Cancelar', onTap: () => Navigator.pop(context)),
          _DialogAction(
            texto: 'Hacer Swap',
            color: _C.gold,
            onTap: () {
              Navigator.pop(context);
              final iidReal = game.seleccionadas.isNotEmpty ? game.seleccionadas.first : 0;
              final iidJoker = cartaJoker['iid'] as int? ?? 0;
              game.swap(indice, iidReal, iidJoker);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Panel jugador en tapete ───────────────────────────────────────────────────

class _MiPanelEnTapete extends StatelessWidget {
  final GameProvider game;
  const _MiPanelEnTapete({required this.game});

  @override
  Widget build(BuildContext context) {
    final puntos = game.miEstado?['puntos_acumulados'] ?? 0;
    final numCartas = (game.miEstado?['mano'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        border: Border(top: BorderSide(color: _C.gold.withAlpha(30), width: 1)),
      ),
      child: Row(
        children: [
          // Avatar jugador
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              border: Border.all(color: _C.gold.withAlpha(80), width: 1.5),
              boxShadow: [BoxShadow(color: _C.info.withAlpha(60), blurRadius: 8)],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tú', style: GoogleFonts.inter(color: _C.text1, fontSize: 11, fontWeight: FontWeight.w700)),
              Text('$numCartas cartas  ·  $puntos pts acum.', style: GoogleFonts.inter(color: _C.text3, fontSize: 9)),
            ],
          ),
          const Spacer(),
          // Indicador ronda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Text(
              'RONDA ${game.estado?['ronda'] ?? 1}',
              style: GoogleFonts.inter(color: _C.text3, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mano del jugador ──────────────────────────────────────────────────────────

class _MiMano extends StatelessWidget {
  final GameProvider game;
  const _MiMano({required this.game});

  @override
  Widget build(BuildContext context) {
    final mano = (game.miEstado?['mano'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      height: 96,
      color: _C.bgPanel,
      child: Column(
        children: [
          Container(height: 1, color: _C.gold.withAlpha(30)),
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6, bottom: 2),
            child: Row(
              children: [
                Text(
                  'MI MANO',
                  style: GoogleFonts.inter(color: _C.text3, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w700),
                ),
                if (game.seleccionadas.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _C.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${game.seleccionadas.length} SELECCIONADA(S)',
                      style: GoogleFonts.inter(color: _C.goldLight, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: mano.length,
              itemBuilder: (context, index) {
                final carta = mano[index];
                final iid = carta['iid'] ?? '$index';
                final sel = game.seleccionadas.contains(iid);
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: _CartaChip(
                    carta: carta,
                    seleccionada: sel,
                    onTap: () => game.toggleSeleccion(iid),
                    grande: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carta en mano (chip interactivo) ─────────────────────────────────────────

class _CartaChip extends StatelessWidget {
  final Map<String, dynamic> carta;
  final bool seleccionada;
  final VoidCallback? onTap;
  final bool grande;

  const _CartaChip({
    required this.carta,
    required this.seleccionada,
    required this.onTap,
    this.grande = false,
  });

  Color get _suitColor {
    switch (carta['palo']) {
      case 'corazones':
      case 'diamantes': return _C.cardRed;
      default:          return _C.cardBlack;
    }
  }

  String get _simbolo {
    if (carta['es_joker'] == true) return '🃏';
    switch (carta['palo']) {
      case 'corazones': return '♥';
      case 'diamantes': return '♦';
      case 'treboles':  return '♣';
      case 'picas':     return '♠';
      default:          return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final esJoker = carta['es_joker'] == true;
    final valor = carta['valor'] ?? '';
    final w = grande ? 48.0 : 36.0;
    final h = grande ? 68.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: seleccionada
            ? Matrix4.translationValues(0, -16, 0)
            : Matrix4.identity(),
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _C.cardFace,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionada ? _C.gold : Colors.grey.shade600,
            width: seleccionada ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: seleccionada ? _C.gold.withAlpha(140) : Colors.black.withAlpha(200),
              blurRadius: seleccionada ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: esJoker
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🃏', style: TextStyle(fontSize: grande ? 24 : 16)),
                  if (grande)
                    Text('JOKER', style: GoogleFonts.inter(fontSize: 7, color: Colors.purple, fontWeight: FontWeight.w800)),
                ]),
              )
            : Stack(
                children: [
                  Positioned(left: 3, top: 2,
                      child: _CornerLabel(valor, _simbolo, _suitColor, grande ? 10 : 8)),
                  Center(child: Text(_simbolo, style: TextStyle(fontSize: grande ? 20 : 14, color: _suitColor))),
                  Positioned(right: 3, bottom: 2,
                    child: Transform.rotate(
                        angle: math.pi,
                        child: _CornerLabel(valor, _simbolo, _suitColor, grande ? 10 : 8))),
                ],
              ),
      ),
    );
  }
}

// ─── Barra de acciones ─────────────────────────────────────────────────────────

class _AccionesBar extends StatelessWidget {
  final GameProvider game;
  const _AccionesBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final esMiTurno = game.esMiTurno;
    final faseAcciones = game.faseAcciones;
    final haySeleccion = game.seleccionadas.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _C.bgCard,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(12), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner de pendientes
          if (game.combinacionesPendientes.isNotEmpty) _PendientesBanner(game: game),
          // Strip de instrucción
          _InstruccionStrip(esMiTurno: esMiTurno, faseAcciones: faseAcciones),
          // Botones
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  if (!faseAcciones) ...[
                    Expanded(
                      child: _ActionBtn(
                        label: 'ROBAR MAZO',
                        icon: Icons.inbox_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                        glowColor: _C.info,
                        enabled: esMiTurno && !game.cargando,
                        onTap: () => game.robar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'ROBAR DESCARTE',
                        icon: Icons.recycling_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                        glowColor: const Color(0xFF7C3AED),
                        enabled: esMiTurno && !game.cargando,
                        onTap: () => game.robar(fuente: 'descarte'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _ActionBtn(
                        label: 'DESCARTAR',
                        icon: Icons.delete_rounded,
                        gradient: LinearGradient(colors: [_C.danger, _C.danger.withAlpha(200)]),
                        glowColor: _C.danger,
                        enabled: esMiTurno &&
                            haySeleccion &&
                            game.combinacionesPendientes.isEmpty &&
                            !game.cargando,
                        onTap: () => game.descartar(game.seleccionadas.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (game.combinacionesPendientes.isEmpty)
                      Expanded(
                        child: _ActionBtn(
                          label: 'AGREGAR COMB.',
                          icon: Icons.add_box_rounded,
                          gradient: LinearGradient(colors: [_C.success, _C.success.withAlpha(200)]),
                          glowColor: _C.success,
                          enabled: esMiTurno && haySeleccion && !game.cargando,
                          onTap: () => _bajarDialog(context, game),
                        ),
                      ),
                    if (game.combinacionesPendientes.isNotEmpty) ...[
                      Expanded(
                        child: _ActionBtn(
                          label: '+ COMB.',
                          icon: Icons.add_rounded,
                          gradient: LinearGradient(colors: [_C.info, _C.info.withAlpha(200)]),
                          glowColor: _C.info,
                          enabled: esMiTurno && haySeleccion && !game.cargando,
                          onTap: () => _bajarDialog(context, game),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          label: 'BAJAR (${game.combinacionesPendientes.length})',
                          icon: Icons.table_chart_rounded,
                          gradient: LinearGradient(colors: [_C.gold, _C.goldDark]),
                          glowColor: _C.gold,
                          enabled: esMiTurno && !game.cargando,
                          onTap: () => game.bajarPendientes(),
                          highlight: true,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bajarDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => _PremiumDialog(
        titulo: 'Tipo de combinación',
        icono: Icons.style_rounded,
        iconoColor: _C.gold,
        contenido: 'Tercia: mismo valor, palos distintos.\nEscalera: mismo palo, valores consecutivos.\n\nPuedes agregar más combinaciones antes de bajar.',
        acciones: [
          _DialogAction(
            texto: '+ ESCALERA',
            color: _C.orange,
            onTap: () {
              Navigator.pop(context);
              game.agregarCombinacionPendiente('escalera');
            },
          ),
          _DialogAction(
            texto: '+ TERCIA',
            color: _C.info,
            onTap: () {
              Navigator.pop(context);
              game.agregarCombinacionPendiente('tercia');
            },
          ),
        ],
      ),
    );
  }
}

class _PendientesBanner extends StatelessWidget {
  final GameProvider game;
  const _PendientesBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _C.success.withAlpha(12),
        border: Border(bottom: BorderSide(color: _C.success.withAlpha(40), width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions_rounded, color: _C.success, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              game.combinacionesPendientes
                  .asMap()
                  .entries
                  .map((e) => '${e.key + 1}. ${e.value['tipo']} (${(e.value['iids'] as List).length} cartas)')
                  .join('  ·  '),
              style: GoogleFonts.inter(color: _C.success, fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: game.limpiarPendientes,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _C.danger.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, color: _C.danger, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionStrip extends StatelessWidget {
  final bool esMiTurno;
  final bool faseAcciones;
  const _InstruccionStrip({required this.esMiTurno, required this.faseAcciones});

  @override
  Widget build(BuildContext context) {
    String texto;
    Color col;
    IconData icono;

    if (!esMiTurno) {
      texto = 'Esperando turno del oponente...';
      col = _C.text3;
      icono = Icons.hourglass_empty_rounded;
    } else if (!faseAcciones) {
      texto = 'Roba una carta del mazo o del descarte para comenzar tu turno';
      col = const Color(0xFF93C5FD);
      icono = Icons.touch_app_rounded;
    } else {
      texto = 'Selecciona cartas → combina o pega a la mesa → descarta para terminar';
      col = const Color(0xFF6EE7B7);
      icono = Icons.swipe_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Colors.white.withAlpha(4),
      child: Row(
        children: [
          Icon(icono, color: col.withAlpha(150), size: 12),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.inter(color: col, fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final bool enabled;
  final VoidCallback onTap;
  final bool highlight;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.enabled,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? glowColor.withAlpha(highlight ? 220 : 100) : Colors.white.withAlpha(10),
            width: highlight ? 2 : 1,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: glowColor.withAlpha(highlight ? 100 : 40), blurRadius: 14, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: enabled ? Colors.white : Colors.white24),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : Colors.white24,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Strips de notificación ────────────────────────────────────────────────────

class _ErrorStrip extends StatelessWidget {
  final String mensaje;
  const _ErrorStrip({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _C.dangerDim,
        border: Border(bottom: BorderSide(color: _C.danger.withAlpha(80), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.danger, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje,
                style: GoogleFonts.inter(color: _C.danger, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _LogIA extends StatelessWidget {
  final List<Map<String, dynamic>> log;
  const _LogIA({required this.log});

  String _describir(Map<String, dynamic> a) {
    final tipo = a['accion'] ?? a['error'] ?? '?';
    switch (tipo) {
      case 'robar_mazo':     return 'Robó del mazo';
      case 'robar_descarte': return 'Robó del descarte';
      case 'bajar':          return 'Bajó (${a['puntos_bajada']} pts)';
      case 'agregar':        return 'Pegó cartas a la mesa';
      case 'descartar':
        final c = a['carta'];
        return c != null ? 'Descartó ${c['valor']} ${c['palo']}' : 'Descartó';
      default: return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _C.gold.withAlpha(8),
        border: Border(bottom: BorderSide(color: _C.gold.withAlpha(30), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_rounded, color: _C.goldDark, size: 13),
          const SizedBox(width: 8),
          Text('IA ›', style: GoogleFonts.inter(color: _C.goldDark, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              log.map(_describir).join('  ·  '),
              style: GoogleFonts.inter(color: _C.goldLight.withAlpha(200), fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo premium ───────────────────────────────────────────────────────────

class _PremiumDialog extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color iconoColor;
  final String contenido;
  final List<_DialogAction> acciones;
  const _PremiumDialog({
    required this.titulo,
    required this.icono,
    required this.iconoColor,
    required this.contenido,
    required this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.gold.withAlpha(50), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(200), blurRadius: 40, spreadRadius: 4),
            BoxShadow(color: iconoColor.withAlpha(30), blurRadius: 40),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconoColor.withAlpha(20),
                border: Border.all(color: iconoColor.withAlpha(80), width: 1.5),
              ),
              child: Icon(icono, color: iconoColor, size: 26),
            ),
            const SizedBox(height: 16),
            // Título
            Text(
              titulo,
              style: GoogleFonts.rajdhani(
                color: _C.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Contenido
            Text(
              contenido,
              style: GoogleFonts.inter(color: _C.text2, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: acciones.asMap().entries.map((entry) {
                final a = entry.value;
                final isFirst = entry.key == 0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 0 : 8),
                    child: GestureDetector(
                      onTap: a.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: a.color != null
                              ? LinearGradient(colors: [a.color!, a.color!.withAlpha(200)])
                              : null,
                          color: a.color == null ? Colors.white.withAlpha(10) : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: a.color?.withAlpha(120) ?? Colors.white.withAlpha(20),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          a.texto,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: a.color != null ? Colors.white : _C.text2,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction {
  final String texto;
  final Color? color;
  final VoidCallback onTap;
  const _DialogAction({required this.texto, required this.onTap, this.color});
}

// ─── Pantalla final ────────────────────────────────────────────────────────────

class _PantallaFin extends StatelessWidget {
  final GameProvider game;
  const _PantallaFin({required this.game});

  @override
  Widget build(BuildContext context) {
    final resultado = game.resultadoFin;
    final ganadorId = resultado?['ganador'] as int?
        ?? game.estado?['ganador_ronda'] as int?;
    final yo = game.idJugadorPartida;
    final gane = ganadorId != null && ganadorId == yo;

    final penalizaciones = (resultado?['penalizaciones'] as Map?)
        ?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {};
    final miPenalizacion = gane ? 0 : (penalizaciones[yo?.toString()] ?? 0);

    final jugadores = game.estado?['jugadores'] as Map<String, dynamic>? ?? {};
    final ias = jugadores.entries
        .where((e) => (e.value as Map)['es_ia'] == true)
        .toList();

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Fondo dramático
          Positioned.fill(
            child: CustomPaint(painter: _FinPainter(gane: gane)),
          ),
          // Contenido
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Icono resultado con glow
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.5, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: gane
                            ? [_C.goldLight, _C.gold, _C.goldDark]
                            : [const Color(0xFFEF4444), const Color(0xFF991B1B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (gane ? _C.gold : _C.danger).withAlpha(140),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha(40),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      gane ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Texto resultado
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gane
                        ? [_C.goldLight, _C.gold]
                        : [const Color(0xFFFF6B6B), _C.danger],
                  ).createShader(bounds),
                  child: Text(
                    gane ? '¡GANASTE!' : 'DERROTA',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gane
                      ? 'Cerraste la ronda sin penalización'
                      : 'Penalización de esta ronda: $miPenalizacion pts',
                  style: GoogleFonts.inter(
                    color: gane ? _C.success : _C.danger.withAlpha(200),
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // Tabla resultados
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Cabecera tabla
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text('JUGADOR', style: GoogleFonts.inter(color: _C.text3, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700))),
                              Text('CARTAS', style: GoogleFonts.inter(color: _C.text3, fontSize: 9, letterSpacing: 1)),
                              const SizedBox(width: 16),
                              SizedBox(width: 88, child: Text('PENALIZACIÓN', textAlign: TextAlign.right, style: GoogleFonts.inter(color: _C.text3, fontSize: 9, letterSpacing: 1))),
                            ],
                          ),
                        ),
                        Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _C.gold.withAlpha(60), Colors.transparent]))),
                        const SizedBox(height: 8),
                        // Fila jugador humano
                        _FilaResultado(
                          nombre: 'Tú',
                          esIa: false,
                          esGanador: gane,
                          numCartas: (jugadores[yo?.toString()] as Map?)?['cartas_en_mano'] as int? ?? 0,
                          penalizacion: miPenalizacion,
                        ),
                        // Filas IAs
                        ...ias.map((e) {
                          final pen = penalizaciones[e.key] ?? 0;
                          final esGanadorIa = ganadorId?.toString() == e.key;
                          return _FilaResultado(
                            nombre: 'IA',
                            esIa: true,
                            esGanador: esGanadorIa,
                            numCartas: (e.value as Map)['cartas_en_mano'] as int? ?? 0,
                            penalizacion: esGanadorIa ? 0 : pen,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Botón volver
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: GestureDetector(
                    onTap: () {
                      game.resetear();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.goldLight, _C.gold, _C.goldDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: _C.gold.withAlpha(100), blurRadius: 24, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'VOLVER AL INICIO',
                          style: GoogleFonts.rajdhani(
                            color: _C.bg,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
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

class _FinPainter extends CustomPainter {
  final bool gane;
  const _FinPainter({required this.gane});

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _C.bg);

    // Gradiente radial dramático desde arriba
    final topGradient = RadialGradient(
      center: const Alignment(0, -1),
      radius: 1.5,
      colors: gane
          ? [_C.gold.withAlpha(30), Colors.transparent]
          : [_C.danger.withAlpha(25), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = topGradient,
    );

    // Símbolo gigante de fondo
    final textPainter = TextPainter(
      text: TextSpan(
        text: gane ? '♛' : '♠',
        style: TextStyle(
          fontSize: 300,
          color: Colors.white.withAlpha(4),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FilaResultado extends StatelessWidget {
  final String nombre;
  final bool esIa;
  final bool esGanador;
  final int numCartas;
  final int penalizacion;
  const _FilaResultado({
    required this.nombre,
    required this.esIa,
    required this.esGanador,
    required this.numCartas,
    required this.penalizacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: esGanador
            ? LinearGradient(colors: [_C.gold.withAlpha(25), _C.gold.withAlpha(10)])
            : null,
        color: esGanador ? null : Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esGanador ? _C.gold.withAlpha(80) : Colors.white.withAlpha(12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esGanador
                  ? _C.gold.withAlpha(40)
                  : (esIa ? Colors.white.withAlpha(15) : _C.info.withAlpha(30)),
              border: Border.all(
                color: esGanador ? _C.gold.withAlpha(100) : Colors.white.withAlpha(20),
              ),
            ),
            child: Icon(
              esIa ? Icons.smart_toy_rounded : Icons.person_rounded,
              color: esGanador ? _C.goldLight : _C.text2,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(nombre, style: GoogleFonts.inter(color: esGanador ? _C.goldLight : _C.text1, fontWeight: FontWeight.w700, fontSize: 13)),
                if (esGanador) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('GANÓ', style: GoogleFonts.inter(color: _C.gold, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$numCartas',
            style: GoogleFonts.rajdhani(color: esGanador ? _C.gold : _C.text2, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 88,
            child: Text(
              esGanador ? '0 pts' : '-$penalizacion pts',
              textAlign: TextAlign.right,
              style: GoogleFonts.rajdhani(
                color: esGanador ? _C.success : _C.danger,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
