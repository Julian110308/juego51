import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sala_provider.dart';
import '../theme/app_theme.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _codigoCtrl = TextEditingController();
  final _chatCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SalaProvider>().addListener(_onSalaChange);
  }

  @override
  void dispose() {
    context.read<SalaProvider>().removeListener(_onSalaChange);
    _codigoCtrl.dispose();
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSalaChange() {
    final sala = context.read<SalaProvider>();
    if (sala.estadoSala == 'en_juego' && mounted) {
      Navigator.pushReplacementNamed(context, '/juego-sala');
    }
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sala = context.watch<SalaProvider>();
    final enSala = sala.idSala != null;

    if (enSala) _scrollChat();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Navbar
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
                      onPressed: () {
                        if (enSala) sala.resetear();
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        enSala
                            ? Icons.logout_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        color: enSala ? AppColors.danger : AppColors.gold,
                        size: 18,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.gold],
                      ).createShader(b),
                      child: Text(
                        enSala
                            ? 'SALA  ${sala.codigoSala ?? ''}'
                            : 'MULTIJUGADOR',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (enSala)
                      AppBadge(
                        text: 'CONECTADO',
                        color: AppColors.success,
                        icon: Icons.circle,
                      ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: enSala
                    ? _WaitingRoom(
                        sala: sala,
                        scrollCtrl: _scrollCtrl,
                        chatCtrl: _chatCtrl,
                      )
                    : _EntryForm(codigoCtrl: _codigoCtrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────
class _EntryForm extends StatefulWidget {
  final TextEditingController codigoCtrl;
  const _EntryForm({required this.codigoCtrl});

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  String _dificultad = 'medio';
  bool _cargando = false;

  Future<void> _crear() async {
    final auth = context.read<AuthProvider>();
    final sala = context.read<SalaProvider>();
    setState(() => _cargando = true);
    await sala.crearSala(auth.token!, dificultad: _dificultad);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _unirse() async {
    final codigo = widget.codigoCtrl.text.trim().toUpperCase();
    if (codigo.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final sala = context.read<SalaProvider>();
    setState(() => _cargando = true);
    await sala.unirseASala(auth.token!, codigo);
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final sala = context.watch<SalaProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 10),
            // Hero
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldLight, AppColors.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withAlpha(90),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: Colors.black87, size: 36),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.gold],
                    ).createShader(b),
                    child: Text(
                      'JUGAR EN LÍNEA',
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea una sala o únete con un código de 6 dígitos',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Crear sala ───────────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTitle(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'CREAR SALA PRIVADA',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dificultad de la IA',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DificultadPicker(
                    value: _dificultad,
                    onChanged: (v) => setState(() => _dificultad = v),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'CREAR SALA',
                    icon: Icons.add_rounded,
                    fromColor: AppColors.success,
                    toColor: AppColors.successDark,
                    onPressed: _cargando ? null : _crear,
                    loading: _cargando,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Unirse ───────────────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTitle(
                    icon: Icons.login_rounded,
                    title: 'UNIRSE A SALA',
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: widget.codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.goldLight,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '· · · · · ·',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
                        fontSize: 22,
                        letterSpacing: 6,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.bgElevated,
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
                        borderSide: const BorderSide(
                            color: AppColors.gold, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: 'UNIRSE A LA SALA',
                    icon: Icons.arrow_forward_rounded,
                    color: AppColors.info,
                    onPressed: _cargando ? null : _unirse,
                    loading: _cargando,
                  ),
                ],
              ),
            ),

            // Error
            if (sala.error != null) ...[
              const SizedBox(height: 14),
              ErrorBanner(message: sala.error!),
            ],
            if (_cargando) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _CardTitle({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Sala de espera ───────────────────────────────────────────────────────────
class _WaitingRoom extends StatelessWidget {
  final SalaProvider sala;
  final ScrollController scrollCtrl;
  final TextEditingController chatCtrl;
  const _WaitingRoom({
    required this.sala,
    required this.scrollCtrl,
    required this.chatCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Código de sala
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1400), Color(0xFF0D0E1A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGold),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withAlpha(25),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'CÓDIGO DE SALA',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.gold],
                    ).createShader(b),
                    child: Text(
                      sala.codigoSala ?? '——',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: AppColors.gold, size: 18),
                    onPressed: () {
                      if (sala.codigoSala != null) {
                        Clipboard.setData(
                            ClipboardData(text: sala.codigoSala!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.black, size: 16),
                                const SizedBox(width: 8),
                                Text('Código copiado',
                                    style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        color: AppColors.gold, strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Esperando que otro jugador se una...',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Chat
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: sala.chat.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Sin mensajes aún',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: sala.chat.length,
                    itemBuilder: (_, i) {
                      final m = sala.chat[i];
                      final esSistema = m['autor'] == '— Sistema —';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!esSistema)
                              Padding(
                                padding: const EdgeInsets.only(right: 6, top: 1),
                                child: Text(
                                  m['hora'] as String? ?? '',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${m['autor']}  ',
                                      style: GoogleFonts.inter(
                                        color: esSistema
                                            ? AppColors.textMuted
                                            : AppColors.goldLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: m['mensaje'] as String? ?? '',
                                      style: GoogleFonts.inter(
                                        color: esSistema
                                            ? AppColors.textMuted
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontStyle: esSistema
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Input chat
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatCtrl,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(
                          color: AppColors.gold, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _enviarChat(context),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _enviarChat(context),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.goldLight, AppColors.goldDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black87, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _enviarChat(BuildContext context) {
    final texto = chatCtrl.text.trim();
    if (texto.isEmpty) return;
    context.read<SalaProvider>().enviarChat(texto);
    chatCtrl.clear();
  }
}

// ─── Selector de dificultad ───────────────────────────────────────────────────
class _DificultadPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _DificultadPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DifChip(
          label: 'Fácil',
          val: 'facil',
          group: value,
          color: AppColors.success,
          onTap: onChanged,
        ),
        const SizedBox(width: 8),
        _DifChip(
          label: 'Medio',
          val: 'medio',
          group: value,
          color: AppColors.info,
          onTap: onChanged,
        ),
        const SizedBox(width: 8),
        _DifChip(
          label: 'Difícil',
          val: 'dificil',
          group: value,
          color: AppColors.danger,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _DifChip extends StatelessWidget {
  final String label, val, group;
  final Color color;
  final ValueChanged<String> onTap;
  const _DifChip({
    required this.label,
    required this.val,
    required this.group,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = val == group;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withAlpha(35) : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? color : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: sel ? Colors.white : AppColors.textMuted,
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
