import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late UsuarioService _service;

  Map<String, dynamic>? _perfil;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _leaderboard;
  List<Map<String, dynamic>>? _historial;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final token = context.read<AuthProvider>().token!;
    _service = UsuarioService(token);
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getPerfil(),
        _service.getEstadisticas(),
        _service.getLeaderboard(),
        _service.getHistorial(),
      ]);
      setState(() {
        _perfil      = results[0] as Map<String, dynamic>;
        _stats       = results[1] as Map<String, dynamic>;
        _leaderboard = results[2] as List<Map<String, dynamic>>;
        _historial   = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withAlpha(200),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.gold, size: 18),
                    ),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.gold],
                      ).createShader(b),
                      child: Text(
                        'MI PERFIL',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                color: AppColors.bgCard,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.goldLight,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 2.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  dividerColor: AppColors.border,
                  tabs: const [
                    Tab(text: 'ESTADÍSTICAS'),
                    Tab(text: 'HISTORIAL'),
                    Tab(text: 'RANKING'),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.gold, strokeWidth: 2))
                    : _error != null
                        ? _ErrorView(error: _error!, onRetry: _cargar)
                        : TabBarView(
                            controller: _tabs,
                            children: [
                              _StatsTab(perfil: _perfil!, stats: _stats!),
                              _HistorialTab(entries: _historial!),
                              _LeaderboardTab(entries: _leaderboard!),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Estadísticas ─────────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> perfil;
  final Map<String, dynamic> stats;
  const _StatsTab({required this.perfil, required this.stats});

  @override
  Widget build(BuildContext context) {
    final jugadas = stats['partidas_jugadas'] as int? ?? 0;
    final ganadas = stats['partidas_ganadas'] as int? ?? 0;
    final perdidas = stats['partidas_perdidas'] as int? ?? 0;
    final puntos = stats['puntos_saldo'] as int? ?? 0;
    final winRate =
        jugadas > 0 ? (ganadas / jugadas * 100).toStringAsFixed(1) : '0.0';
    final nombre = perfil['nombre_usuario'] as String? ?? '?';
    final correo = perfil['correo'] as String? ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Hero avatar ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1400), Color(0xFF0D0E1A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withAlpha(100),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgCard,
                    ),
                    child: Center(
                      child: Text(
                        inicial,
                        style: GoogleFonts.rajdhani(
                          fontSize: 32,
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correo,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppBadge(
                      text: jugadas > 10 ? 'JUGADOR ACTIVO' : 'NUEVO JUGADOR',
                      color: AppColors.gold,
                      icon: Icons.military_tech_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Puntos totales ───────────────────────────────────────────────────
        GlassCard(
          borderColor: AppColors.borderGold,
          shadows: [
            BoxShadow(
              color: AppColors.gold.withAlpha(25),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PUNTOS TOTALES',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.gold],
                      ).createShader(b),
                      child: Text(
                        '$puntos',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Text(
                      'puntos acumulados',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 60,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Grid de stats ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'JUGADAS',
                value: '$jugadas',
                icon: Icons.casino_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'GANADAS',
                value: '$ganadas',
                icon: Icons.emoji_events_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'PERDIDAS',
                value: '$perdidas',
                icon: Icons.close_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Win rate ─────────────────────────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'WIN RATE',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$winRate%',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.success,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: jugadas > 0 ? ganadas / jugadas : 0,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    jugadas > 0 && ganadas / jugadas > 0.5
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$ganadas victorias de $jugadas partidas',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab Historial ────────────────────────────────────────────────────────────
class _HistorialTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _HistorialTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        message: 'Sin historial aún',
        sub: 'Tus partidas aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final tipo = e['tipo_movimiento'] as String? ?? '';
        final puntos = e['puntos_cambio'] as int? ?? 0;
        final saldo = e['saldo_resultante'] as int? ?? 0;
        final desc = e['descripcion'] as String? ?? '';
        final fecha = e['fecha'] as String? ?? '';
        final positivo = puntos >= 0;
        final color = positivo ? AppColors.success : AppColors.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Icon(
                positivo
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 18,
              ),
            ),
            title: Text(
              desc.isNotEmpty ? desc : tipo,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            subtitle: fecha.length >= 10
                ? Text(
                    fecha.substring(0, 10),
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11),
                  )
                : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  puntos >= 0 ? '+$puntos' : '$puntos',
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$saldo pts',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab Leaderboard ──────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _LeaderboardTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        icon: Icons.leaderboard_rounded,
        message: 'Sin jugadores aún',
        sub: 'El ranking aparecerá aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final pos = e['posicion'] as int? ?? i + 1;
        final nombre = e['nombre_usuario'] as String? ?? '?';
        final puntos = e['puntos_saldo'] as int? ?? 0;
        final ganadas = e['partidas_ganadas'] as int? ?? 0;
        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

        Color posColor;
        String posLabel;
        IconData? medal;
        if (pos == 1) {
          posColor = const Color(0xFFFFD700);
          posLabel = '🥇';
          medal = Icons.emoji_events_rounded;
        } else if (pos == 2) {
          posColor = const Color(0xFFC0C0C0);
          posLabel = '🥈';
          medal = Icons.emoji_events_rounded;
        } else if (pos == 3) {
          posColor = const Color(0xFFCD7F32);
          posLabel = '🥉';
          medal = Icons.emoji_events_rounded;
        } else {
          posColor = AppColors.textMuted;
          posLabel = '#$pos';
          medal = null;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: pos <= 3
                ? posColor.withAlpha(10)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pos <= 3
                  ? posColor.withAlpha(70)
                  : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Posición
                SizedBox(
                  width: 36,
                  child: medal != null
                      ? Icon(medal, color: posColor, size: 22)
                      : Text(
                          posLabel,
                          style: GoogleFonts.rajdhani(
                            color: posColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: posColor.withAlpha(22),
                    shape: BoxShape.circle,
                    border: Border.all(color: posColor.withAlpha(80)),
                  ),
                  child: Center(
                    child: Text(
                      inicial,
                      style: GoogleFonts.rajdhani(
                        color: posColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombre,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$puntos pts',
                      style: GoogleFonts.rajdhani(
                        color: pos <= 3 ? posColor : AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$ganadas victorias',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.rajdhani(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.danger.withAlpha(60)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
