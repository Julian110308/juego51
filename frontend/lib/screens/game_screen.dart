import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'dart:math' as math;

// ─── Paleta casino premium ────────────────────────────────────────────────────
class _C {
  static const wood       = Color(0xFF140A02);
  static const rim        = Color(0xFF5C2A0A);
  static const rimLight   = Color(0xFF7A3D12);
  static const felt0      = Color(0xFF1A7A3A);
  static const felt1      = Color(0xFF0F6030);
  static const felt2      = Color(0xFF083D1E);
  static const gold       = Color(0xFFCFA535);
  static const goldLight  = Color(0xFFE8C96A);
  static const goldDim    = Color(0xFF8A6A1A);
  static const cream      = Color(0xFFF5EDD8);
  static const navy       = Color(0xFF0D0D2B);
  static const cardRed    = Color(0xFFAA1010);
  static const activeGold = Color(0xFFFFCA28);
  static const ok         = Color(0xFF2E7D32);
  static const okLight    = Color(0xFF4CAF50);
  static const danger     = Color(0xFF8B0000);
  static const blue       = Color(0xFF1565C0);
  static const orange     = Color(0xFFBF6000);
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    if (game.estado == null) {
      return Scaffold(
        backgroundColor: _C.wood,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _C.gold, strokeWidth: 2),
              const SizedBox(height: 20),
              Text(
                'PREPARANDO LA MESA',
                style: TextStyle(
                    color: _C.gold.withAlpha(160),
                    fontSize: 12,
                    letterSpacing: 3),
              ),
            ],
          ),
        ),
      );
    }

    if (game.finalizada) return _PantallaFin(game: game);

    return Scaffold(
      backgroundColor: _C.wood,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Cabecera
            _Header(game: game),
            // ── Notificaciones flotantes
            if (game.error != null) _ErrorStrip(mensaje: game.error!),
            if (game.iaLog.isNotEmpty) _LogIA(log: game.iaLog),
            // ── Mesa de juego (tapete)
            Expanded(child: _Mesa(game: game)),
            // ── Mano del jugador (fuera del tapete)
            _MiMano(game: game),
            // ── Barra de acciones
            _AccionesBar(game: game),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final GameProvider game;
  const _Header({required this.game});

  @override
  Widget build(BuildContext context) {
    final esMiTurno = game.esMiTurno;
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _C.wood,
        border: Border(bottom: BorderSide(color: _C.rim, width: 1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centro: título
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'JUEGO 51',
                style: TextStyle(
                  color: _C.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              Text(
                esMiTurno ? '◆ TU TURNO' : '◆ TURNO DE LA IA',
                style: TextStyle(
                  color: esMiTurno ? _C.goldLight : Colors.white30,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          // Izquierda: mazo
          Positioned(
            left: 14,
            child: Row(
              children: [
                const Icon(Icons.style, color: _C.goldDim, size: 13),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('MAZO',
                        style: TextStyle(
                            color: _C.goldDim, fontSize: 8, letterSpacing: 1)),
                    Text(
                      '${game.estado?['mazo_restante'] ?? 0}',
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Derecha: estado + rendirse
          Positioned(
            right: 4,
            child: Row(
              children: [
                _StatusPill(
                  label: game.miEstado?['bajado'] == true ? 'BAJADO' : 'SIN BAJAR',
                  active: game.miEstado?['bajado'] == true,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.flag_rounded,
                      color: Colors.redAccent, size: 18),
                  onPressed: () => _rendirseDialog(context, game),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _rendirseDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => _CasinoDialog(
        titulo: '¿Rendirse?',
        contenido: 'Perderás puntos por las cartas que tengas en mano.',
        acciones: [
          _DialogAction(
            texto: 'Cancelar',
            onTap: () => Navigator.pop(context),
          ),
          _DialogAction(
            texto: 'Rendirse',
            color: Colors.redAccent,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _C.ok.withAlpha(35) : Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active ? _C.okLight.withAlpha(100) : Colors.white.withAlpha(15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? _C.okLight : Colors.white30,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Mesa (tapete del juego) ──────────────────────────────────────────────────

class _Mesa extends StatelessWidget {
  final GameProvider game;
  const _Mesa({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Borde de cuero multicapa
          boxShadow: [
            BoxShadow(color: _C.rimLight.withAlpha(80), blurRadius: 0, spreadRadius: 14),
            BoxShadow(color: _C.rim.withAlpha(255), blurRadius: 0, spreadRadius: 10),
            BoxShadow(color: Colors.black.withAlpha(200), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Gradiente radial del tapete
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.1),
                      radius: 1.1,
                      colors: [_C.felt0, _C.felt1, _C.felt2],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // Contenido del tapete
              Column(
                children: [
                  // ① Zona del oponente
                  _AiZone(game: game),
                  // Separador ── BARAJA ──
                  _FeltDivider(label: 'BARAJA'),
                  // ② Mazo + Descarte
                  _BarajaZone(game: game),
                  // Separador ── COMBINACIONES ──
                  _FeltDivider(label: 'COMBINACIONES EN MESA'),
                  // ③ Combinaciones (expandible)
                  Expanded(child: _CombinacionesScroll(game: game)),
                  // ④ Panel del jugador
                  _MiPanelEnTapete(game: game),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separador de sección en el tapete
class _FeltDivider extends StatelessWidget {
  final String label;
  const _FeltDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.white.withAlpha(12))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(30),
                fontSize: 8,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: Colors.white.withAlpha(12))),
        ],
      ),
    );
  }
}

// ─── ① Zona oponente (IA) ────────────────────────────────────────────────────

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

    if (otros.isEmpty) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        children: otros.map((entry) {
          final id = int.tryParse(entry.key);
          final j = entry.value as Map<String, dynamic>;
          final numCartas = j['cartas_en_mano'] as int? ?? 0;
          final bajado = j['bajado'] == true;
          final esTurno = jugadorActivo == id;
          return Expanded(
            child: _AiPanel(
              numCartas: numCartas,
              bajado: bajado,
              esTurno: esTurno,
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
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(esTurno ? 200 : 130),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esTurno ? _C.activeGold : Colors.white.withAlpha(18),
          width: esTurno ? 1.5 : 1,
        ),
        boxShadow: esTurno
            ? [BoxShadow(color: _C.activeGold.withAlpha(50), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          _Avatar(active: esTurno),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'IA',
                      style: TextStyle(
                        color: esTurno ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (bajado)
                      _MicroBadge(label: 'BAJADO', color: _C.okLight),
                    if (esTurno && !bajado)
                      _MicroBadge(label: 'JUGANDO', color: _C.activeGold),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$numCartas cartas en mano',
                  style: TextStyle(
                    color: esTurno ? _C.goldLight : Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Cartas al dorso (máx 7 visibles)
          if (numCartas > 0)
            SizedBox(
              height: 38,
              child: _CartasDorsoRow(
                cantidad: numCartas.clamp(0, 8),
                activas: esTurno,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool active;
  const _Avatar({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active ? _C.gold.withAlpha(30) : Colors.white.withAlpha(8),
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? _C.gold : Colors.white.withAlpha(25),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        size: 17,
        color: active ? _C.gold : Colors.white38,
      ),
    );
  }
}

class _MicroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MicroBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CartasDorsoRow extends StatelessWidget {
  final int cantidad;
  final bool activas;
  const _CartasDorsoRow({required this.cantidad, required this.activas});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (cantidad * 14.0).clamp(0, 120),
      child: Stack(
        children: List.generate(cantidad, (i) {
          return Positioned(
            left: i * 14.0,
            child: _CartaDorso(activa: activas),
          );
        }),
      ),
    );
  }
}

class _CartaDorso extends StatelessWidget {
  final bool activa;
  const _CartaDorso({this.activa = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3080), Color(0xFF0D1B5E)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: activa ? _C.gold.withAlpha(150) : Colors.white.withAlpha(25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 3, offset: const Offset(1, 1)),
        ],
      ),
      child: CustomPaint(painter: _DorsoPainter()),
    );
  }
}

class _DorsoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(14)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width + size.height; i += 5) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── ② Baraja: mazo + descarte ───────────────────────────────────────────────

class _BarajaZone extends StatelessWidget {
  final GameProvider game;
  const _BarajaZone({required this.game});

  @override
  Widget build(BuildContext context) {
    final tope = game.estado?['tope_descarte'] as Map<String, dynamic>?;
    final mazoN = game.estado?['mazo_restante'] as int? ?? 0;
    final puedeRobar = game.esMiTurno && !game.faseAcciones && !game.cargando;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── MAZO ──
          _PilaCard(
            label: 'MAZO',
            sublabel: '$mazoN',
            activa: puedeRobar,
            onTap: puedeRobar ? () => game.robar() : null,
            child: _MazoStack(activo: puedeRobar),
          ),
          // ── Divisor central ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Container(width: 1, height: 20, color: Colors.white.withAlpha(12)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.swap_horiz_rounded,
                      size: 16, color: Colors.white.withAlpha(20)),
                ),
                Container(width: 1, height: 20, color: Colors.white.withAlpha(12)),
              ],
            ),
          ),
          // ── DESCARTE ──
          _PilaCard(
            label: 'DESCARTE',
            sublabel: tope != null
                ? '${tope['valor']} ${_suit(tope['palo'])}'
                : 'vacío',
            activa: puedeRobar && tope != null,
            onTap: puedeRobar && tope != null
                ? () => game.robar(fuente: 'descarte')
                : null,
            child: tope != null
                ? _CartaGrande(carta: tope, activa: puedeRobar)
                : _SlotVacio(),
          ),
        ],
      ),
    );
  }

  static String _suit(String? p) {
    switch (p) {
      case 'corazones': return '♥';
      case 'diamantes': return '♦';
      case 'treboles':  return '♣';
      case 'picas':     return '♠';
      default:          return '';
    }
  }
}

class _PilaCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool activa;
  final VoidCallback? onTap;
  final Widget child;
  const _PilaCard({
    required this.label,
    required this.sublabel,
    required this.activa,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: activa ? _C.goldLight : Colors.white.withAlpha(40),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          child,
          const SizedBox(height: 6),
          Text(
            sublabel,
            style: TextStyle(
              color: activa ? _C.goldLight : Colors.white.withAlpha(40),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (activa) ...[
            const SizedBox(height: 2),
            Text(
              'Toca para robar',
              style: TextStyle(
                color: _C.okLight.withAlpha(200),
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MazoStack extends StatelessWidget {
  final bool activo;
  const _MazoStack({required this.activo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra de profundidad
          for (int i = 6; i >= 1; i--)
            Positioned(
              left: i * 1.2,
              top: -(i * 1.2),
              child: _CartaDorsoGrande(activa: false),
            ),
          Positioned(left: 0, top: 0, child: _CartaDorsoGrande(activa: activo)),
        ],
      ),
    );
  }
}

class _CartaDorsoGrande extends StatelessWidget {
  final bool activa;
  const _CartaDorsoGrande({this.activa = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 65,
      height: 95,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3080), Color(0xFF0D1B5E)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activa ? _C.gold : Colors.white.withAlpha(30),
          width: activa ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: activa ? _C.gold.withAlpha(80) : Colors.black.withAlpha(180),
            blurRadius: activa ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DorsoPainter())),
            if (activa)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _C.gold.withAlpha(120), width: 1),
                  ),
                  child: const Text(
                    'ROBAR',
                    style: TextStyle(
                      color: _C.goldLight,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaGrande extends StatelessWidget {
  final Map<String, dynamic> carta;
  final bool activa;
  const _CartaGrande({required this.carta, this.activa = false});

  Color get _color {
    switch (carta['palo']) {
      case 'corazones':
      case 'diamantes': return _C.cardRed;
      default:          return _C.navy;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 65,
      height: 95,
      decoration: BoxDecoration(
        color: _C.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activa ? _C.gold : Colors.grey.shade500,
          width: activa ? 2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: activa ? _C.gold.withAlpha(100) : Colors.black.withAlpha(150),
            blurRadius: activa ? 14 : 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: esJoker
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🃏', style: TextStyle(fontSize: 30)),
                const Text('JOKER',
                    style: TextStyle(fontSize: 7, color: Colors.purple, fontWeight: FontWeight.bold)),
              ]))
          : Stack(children: [
              Positioned(left: 5, top: 4, child: _CornerLabel(valor, _simbolo, _color, 12)),
              Center(child: Text(_simbolo, style: TextStyle(fontSize: 32, color: _color))),
              Positioned(
                  right: 5,
                  bottom: 4,
                  child: Transform.rotate(
                      angle: math.pi,
                      child: _CornerLabel(valor, _simbolo, _color, 12))),
            ]),
    );
  }
}

class _SlotVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 95,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(18), width: 1),
        color: Colors.black.withAlpha(40),
      ),
      child: Center(
        child: Text('—', style: TextStyle(color: Colors.white.withAlpha(30), fontSize: 22)),
      ),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final String valor, simbolo;
  final Color color;
  final double fontSize;
  const _CornerLabel(this.valor, this.simbolo, this.color, this.fontSize);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(valor, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color, height: 1.0)),
        Text(simbolo, style: TextStyle(fontSize: fontSize - 2, color: color, height: 1.0)),
      ],
    );
  }
}

// ─── ③ Combinaciones en mesa ──────────────────────────────────────────────────

class _CombinacionesScroll extends StatelessWidget {
  final GameProvider game;
  const _CombinacionesScroll({required this.game});

  @override
  Widget build(BuildContext context) {
    final mesa = game.estado?['mesa'] as List? ?? [];
    final bajado = game.miEstado?['bajado'] == true;
    final puedeAgregar =
        bajado && game.esMiTurno && game.faseAcciones && game.seleccionadas.isNotEmpty;

    if (mesa.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.crop_landscape, size: 24, color: Colors.white.withAlpha(18)),
          const SizedBox(height: 6),
          Text('Ningún jugador se ha bajado aún',
              style: TextStyle(color: Colors.white.withAlpha(25), fontSize: 11, letterSpacing: 0.5)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      itemCount: mesa.length,
      itemBuilder: (_, i) {
        final comb = mesa[i] as Map<String, dynamic>;
        final combinacion = comb['combinacion'] as Map<String, dynamic>? ?? comb;
        final cartas = combinacion['cartas'] as List? ?? [];
        final tipo = combinacion['tipo'] as String? ?? '';
        final esEscalera = tipo == 'escalera';
        final accentColor = esEscalera ? _C.orange : _C.blue;
        final tipoBadge = esEscalera ? 'ESCALERA' : 'TERCIA';

        return GestureDetector(
          onTap: puedeAgregar ? () => _confirmarAgregar(context, game, i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(puedeAgregar ? 100 : 65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: puedeAgregar ? _C.gold.withAlpha(160) : accentColor.withAlpha(50),
                width: puedeAgregar ? 1.5 : 1,
              ),
              boxShadow: puedeAgregar
                  ? [BoxShadow(color: _C.gold.withAlpha(40), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: Row(
              children: [
                // Tipo badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: accentColor.withAlpha(70), width: 1),
                      ),
                      child: Text(tipoBadge,
                          style: TextStyle(
                              color: accentColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 4),
                    Text('${cartas.length}',
                        style: TextStyle(color: Colors.white.withAlpha(30), fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 8),
                // Cartas
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: cartas
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: _CartaChip(
                                    carta: c as Map<String, dynamic>,
                                    seleccionada: false,
                                    onTap: null),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                // Botón pegar
                if (puedeAgregar) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.gold.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _C.gold.withAlpha(80), width: 1),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.add_rounded, color: _C.goldLight, size: 14),
                        Text('PEGAR',
                            style: TextStyle(color: _C.goldLight, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarAgregar(BuildContext context, GameProvider game, int idx) {
    showDialog(
      context: context,
      builder: (_) => _CasinoDialog(
        titulo: 'Pegar carta(s)',
        contenido: '¿Pegar ${game.seleccionadas.length} carta(s) a esta combinación?',
        acciones: [
          _DialogAction(texto: 'Cancelar', onTap: () => Navigator.pop(context)),
          _DialogAction(
            texto: 'Pegar',
            color: _C.okLight,
            onTap: () {
              Navigator.pop(context);
              game.agregarACombinacion(idx);
            },
          ),
        ],
      ),
    );
  }
}

// ─── ④ Panel del jugador en el tapete ────────────────────────────────────────

class _MiPanelEnTapete extends StatelessWidget {
  final GameProvider game;
  const _MiPanelEnTapete({required this.game});

  @override
  Widget build(BuildContext context) {
    final esMiTurno = game.esMiTurno;
    final bajado = game.miEstado?['bajado'] == true;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esMiTurno ? _C.activeGold : Colors.white.withAlpha(18),
          width: esMiTurno ? 1.5 : 1,
        ),
        boxShadow: esMiTurno
            ? [BoxShadow(color: _C.activeGold.withAlpha(45), blurRadius: 14, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        children: [
          // Avatar propio
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: esMiTurno ? _C.gold.withAlpha(35) : Colors.white.withAlpha(8),
              shape: BoxShape.circle,
              border: Border.all(
                  color: esMiTurno ? _C.gold : Colors.white.withAlpha(25), width: 1.5),
            ),
            child: Icon(Icons.person_rounded,
                size: 18, color: esMiTurno ? _C.gold : Colors.white38),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TÚ · JUGADOR PRINCIPAL',
                  style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(
                bajado ? 'Bajado ✓' : 'Sin bajar',
                style: TextStyle(
                  color: bajado ? _C.okLight : Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (esMiTurno)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _C.activeGold.withAlpha(28),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _C.activeGold.withAlpha(140), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: _C.activeGold, size: 12),
                  SizedBox(width: 5),
                  Text('TU TURNO',
                      style: TextStyle(
                          color: _C.activeGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Mano del jugador (fuera del tapete) ─────────────────────────────────────

class _MiMano extends StatelessWidget {
  final GameProvider game;
  const _MiMano({required this.game});

  @override
  Widget build(BuildContext context) {
    final mano = game.miMano;
    final selCount = game.seleccionadas.length;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: _C.wood,
        border: Border(
          top: BorderSide(color: _C.rim.withAlpha(100), width: 1),
          bottom: BorderSide(color: Colors.black.withAlpha(60), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.style_rounded, color: _C.goldDim, size: 12),
                const SizedBox(width: 6),
                Text(
                  'MI MANO  ·  ${mano.length} CARTAS',
                  style: const TextStyle(color: _C.goldDim, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                if (selCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.ok.withAlpha(35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.okLight.withAlpha(90), width: 1),
                    ),
                    child: Text(
                      '$selCount SEL.',
                      style: const TextStyle(color: _C.okLight, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Cartas
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
              itemCount: mano.length,
              itemBuilder: (_, i) {
                final carta = mano[i];
                final iid = carta['iid'] as int;
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

// ─── Barra de acciones ────────────────────────────────────────────────────────

class _AccionesBar extends StatelessWidget {
  final GameProvider game;
  const _AccionesBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final esMiTurno = game.esMiTurno;
    final faseAcciones = game.faseAcciones;
    final haySeleccion = game.seleccionadas.isNotEmpty;

    return Container(
      color: const Color(0xFF060606),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Combinaciones pendientes
          if (game.combinacionesPendientes.isNotEmpty) _PendientesBanner(game: game),
          // Instrucción de fase
          _InstruccionStrip(esMiTurno: esMiTurno, faseAcciones: faseAcciones),
          // Botones
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  if (!faseAcciones) ...[
                    Expanded(
                      child: _ActionBtn(
                        label: 'ROBAR MAZO',
                        icon: Icons.inbox_rounded,
                        color: _C.blue,
                        enabled: esMiTurno && !game.cargando,
                        onTap: () => game.robar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'ROBAR DESCARTE',
                        icon: Icons.recycling_rounded,
                        color: const Color(0xFF4527A0),
                        enabled: esMiTurno && !game.cargando,
                        onTap: () => game.robar(fuente: 'descarte'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: _ActionBtn(
                        label: 'DESCARTAR',
                        icon: Icons.delete_rounded,
                        color: _C.danger,
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
                          color: _C.ok,
                          enabled: esMiTurno && haySeleccion && !game.cargando,
                          onTap: () => _bajarDialog(context, game),
                        ),
                      ),
                    if (game.combinacionesPendientes.isNotEmpty) ...[
                      Expanded(
                        child: _ActionBtn(
                          label: '+ COMB.',
                          icon: Icons.add_rounded,
                          color: _C.blue,
                          enabled: esMiTurno && haySeleccion && !game.cargando,
                          onTap: () => _bajarDialog(context, game),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          label: 'BAJAR (${game.combinacionesPendientes.length})',
                          icon: Icons.table_chart_rounded,
                          color: _C.ok,
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
      builder: (_) => _CasinoDialog(
        titulo: 'Tipo de combinación',
        contenido:
            'Tercia: mismo valor, palos distintos.\nEscalera: mismo palo, valores consecutivos.\n\nPuedes agregar más combinaciones antes de bajar.',
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
            color: _C.blue,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: _C.ok.withAlpha(15),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, color: _C.okLight, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              game.combinacionesPendientes
                  .asMap()
                  .entries
                  .map((e) => '${e.key + 1}. ${e.value['tipo']} (${(e.value['iids'] as List).length})')
                  .join('  ·  '),
              style: const TextStyle(color: _C.okLight, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: game.limpiarPendientes,
            child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 15),
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
    if (!esMiTurno) {
      texto = 'Esperando turno de la IA...';
      col = Colors.white24;
    } else if (!faseAcciones) {
      texto = 'Roba una carta del mazo o del descarte para comenzar tu turno';
      col = const Color(0xFF90CAF9);
    } else {
      texto = 'Selecciona cartas → combina o pega a la mesa → descarta para terminar';
      col = const Color(0xFF81C784);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Colors.white.withAlpha(4),
      child: Text(texto,
          style: TextStyle(color: col, fontSize: 11, letterSpacing: 0.2),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final bool highlight;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
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
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withAlpha(220), color.withAlpha(170)],
                )
              : null,
          color: enabled ? null : Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withAlpha(highlight ? 200 : 120) : Colors.white.withAlpha(12),
            width: highlight ? 1.5 : 1,
          ),
          boxShadow: enabled && highlight
              ? [BoxShadow(color: color.withAlpha(70), blurRadius: 10, offset: const Offset(0, 3))]
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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

// ─── Carta Chip ───────────────────────────────────────────────────────────────

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

  Color get _colorSuit {
    switch (carta['palo']) {
      case 'corazones':
      case 'diamantes': return _C.cardRed;
      default:          return _C.navy;
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
    final w = grande ? 55.0 : 40.0;
    final h = grande ? 80.0 : 58.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: seleccionada
            ? Matrix4.translationValues(0, -13, 0)
            : Matrix4.identity(),
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: seleccionada ? const Color(0xFFFFFBEE) : _C.cream,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: seleccionada ? _C.gold : Colors.grey.shade500,
            width: seleccionada ? 2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: seleccionada ? _C.gold.withAlpha(120) : Colors.black.withAlpha(150),
              blurRadius: seleccionada ? 12 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: esJoker
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🃏', style: TextStyle(fontSize: grande ? 26 : 18)),
                  if (grande)
                    const Text('JOKER',
                        style: TextStyle(fontSize: 7, color: Colors.purple, fontWeight: FontWeight.bold)),
                ]),
              )
            : Stack(
                children: [
                  Positioned(
                      left: 3, top: 2,
                      child: _CornerLabel(valor, _simbolo, _colorSuit, grande ? 11 : 9)),
                  Center(
                    child: Text(_simbolo,
                        style: TextStyle(fontSize: grande ? 22 : 16, color: _colorSuit)),
                  ),
                  Positioned(
                    right: 3, bottom: 2,
                    child: Transform.rotate(
                        angle: math.pi,
                        child: _CornerLabel(valor, _simbolo, _colorSuit, grande ? 11 : 9)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Strips de notificación ───────────────────────────────────────────────────

class _ErrorStrip extends StatelessWidget {
  final String mensaje;
  const _ErrorStrip({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: Colors.redAccent.withAlpha(25),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
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
      case 'robar_mazo':     return 'IA robó del mazo';
      case 'robar_descarte': return 'IA robó del descarte';
      case 'bajar':          return 'IA bajó (${a['puntos_bajada']} pts)';
      case 'agregar':        return 'IA pegó cartas a la mesa';
      case 'descartar':
        final c = a['carta'];
        return c != null ? 'IA descartó ${c['valor']} ${c['palo']}' : 'IA descartó';
      default: return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: const Color(0xFF1A1000),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_rounded, color: _C.gold, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.map(_describir).join('  ›  '),
              style: const TextStyle(color: _C.goldLight, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo estilo casino ────────────────────────────────────────────────────

class _CasinoDialog extends StatelessWidget {
  final String titulo;
  final String contenido;
  final List<_DialogAction> acciones;
  const _CasinoDialog({required this.titulo, required this.contenido, required this.acciones});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _C.goldDim, width: 1),
      ),
      title: Text(titulo,
          style: const TextStyle(
              color: _C.goldLight, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      content: Text(contenido, style: const TextStyle(color: Colors.white54, height: 1.6)),
      actions: acciones.map((a) {
        return TextButton(
          onPressed: a.onTap,
          child: Text(
            a.texto,
            style: TextStyle(
              color: a.color ?? Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DialogAction {
  final String texto;
  final Color? color;
  final VoidCallback onTap;
  const _DialogAction({required this.texto, required this.onTap, this.color});
}

// ─── Pantalla final ───────────────────────────────────────────────────────────

class _PantallaFin extends StatelessWidget {
  final GameProvider game;
  const _PantallaFin({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.wood,
      body: Stack(
        children: [
          Center(
            child: Text('♠',
                style: TextStyle(
                    fontSize: 360,
                    color: Colors.white.withAlpha(4),
                    fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [_C.gold, Color(0xFF7A5A00)]),
                    boxShadow: [
                      BoxShadow(
                          color: _C.gold.withAlpha(120),
                          blurRadius: 40,
                          spreadRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.emoji_events, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 28),
                const Text('PARTIDA TERMINADA',
                    style: TextStyle(
                        color: _C.gold, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 6),
                const Text('Gracias por jugar',
                    style: TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () {
                    game.resetear();
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_C.gold, Color(0xFF8B6914)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: _C.gold.withAlpha(80), blurRadius: 16, offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Text('VOLVER AL INICIO',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
