import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  ENERGY CONTROL  —  RTDB-linked
//
//  Commands node:  system/commands  {mode, source}
//  Status  node:   system/status    {activeSource, systemMode,
//                                    generatorRunning, batteryState}
//
//  Source buttons: AUTO · BATTERY · RESCUE  (OFF removed)
//  Generator control section removed.
//  All taps write to RTDB instantly.
// ─────────────────────────────────────────────────────────────────

class EnergyControlPage extends StatefulWidget {
  const EnergyControlPage({super.key});
  @override
  _EnergyControlPageState createState() => _EnergyControlPageState();
}

class _EnergyControlPageState extends State<EnergyControlPage> {
  final _cRef = FirebaseDatabase.instance.ref('system/commands');
  final _sRef = FirebaseDatabase.instance.ref('system/status');

  // ── Commanded values (from commands node) ─────────────────────
  String _mode = 'auto';
  String _src  = 'auto';

  // ── Live status (from status node) ────────────────────────────
  String _aSrc  = '--';
  String _sMode = '--';
  String _bst    = '--';

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Sync commanded state from RTDB on load
    _cRef.onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() {
        _mode = (d['mode']   ?? 'auto').toString().toLowerCase();
        _src  = (d['source'] ?? 'auto').toString().toLowerCase();
      });
    });
    // Live system status
    _sRef.onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() {
        _aSrc  = (d['activeSource'] ?? '--').toString().toUpperCase();
        _sMode = (d['mode']        ?? '--').toString().toUpperCase();
        _bst   = (d['batteryState'] ?? '--').toString().toUpperCase();
      });
    });
  }

  // ── Write command to RTDB ─────────────────────────────────────
  Future<void> _setSource(String mode, String src) async {
    setState(() => _sending = true);
    await _cRef.update({'mode': mode, 'source': src});
    setState(() { _mode = mode; _src = src; _sending = false; });
  }

  Color _batteryColor(String s) {
    switch (s.toUpperCase()) {
      case 'GOOD':
      case 'NORMAL':   return AppTheme.accent;
      case 'LOW':      return AppTheme.warning;
      case 'CRITICAL': return AppTheme.danger;
      default:         return AppTheme.textSec;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        EcHeader(
          title: 'Energy Control',
          icon: Icons.tune_rounded,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 22),
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const WelcomeScreen()));
                }
              },
            ),
          ],
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Live status banner ───────────────────────────
              _liveStatusCard(),
              const SizedBox(height: 24),

              // ── Source selection ─────────────────────────────
              _sectionLabel(
                'Source Selection',
                Icons.power_settings_new_rounded,
                AppTheme.accent,
                trailing: _sending
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent))
                    : null,
              ),
              const SizedBox(height: 14),
              _sourceRow(),
              const SizedBox(height: 28),

              // ── System info card ─────────────────────────────
              _infoCard(),
            ],
          ),
        ),

        const EcNav(selected: 2),
      ]),
    );
  }

  // ── Live status card ──────────────────────────────────────────
  Widget _liveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2318), Color(0xFF1A3A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.deepShadow,
      ),
      child: Stack(children: [
        // dot texture
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: CustomPaint(painter: _DotPainter()),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Live System Status',
              style: GoogleFonts.dmSans(
                  color: Colors.white54, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _liveChip('Mode', _sMode,
                  _sMode == 'AUTO' ? AppTheme.accent : Colors.orangeAccent),
              _liveDivider(),
              _liveChip('Source', _aSrc.isEmpty ? '--' : _aSrc,
                  Colors.lightBlueAccent),
              _liveDivider(),
              _liveChip('Battery', _bst, _batteryColor(_bst)),
            ],
          ),
        ]),
      ]),
    );
  }

  Widget _liveChip(String lbl, String val, Color c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(lbl,
              style: GoogleFonts.dmSans(
                  color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withValues(alpha: 0.35)),
            ),
            child: Text(val,
                style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c)),
          ),
        ],
      );

  Widget _liveDivider() =>
      Container(width: 1, height: 32, color: Colors.white12);

  // ── Section label ─────────────────────────────────────────────
  Widget _sectionLabel(String title, IconData icon, Color c,
      {Widget? trailing}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title, style: AppTheme.label(15)),
      if (trailing != null) ...[
        const SizedBox(width: 10),
        trailing,
      ],
    ]);
  }

  // ── Source row — 3 compact chips ─────────────────────────────
  Widget _sourceRow() {
    final opts = [
      SrcOpt(
        label: 'AUTO',
        subtitle: 'Smart switch',
        mode: 'auto',
        src: 'auto',
        icon: Icons.auto_mode_rounded,
        color: Colors.teal,
      ),
      SrcOpt(
        label: 'BATTERY',
        subtitle: 'Force battery',
        mode: 'manual',
        src: 'BAT',
        icon: Icons.battery_charging_full_rounded,
        color: AppTheme.accent,
      ),
      SrcOpt(
        label: 'RESCUE',
        subtitle: 'Force second source',
        mode: 'manual',
        src: 'SEC',
        icon: Icons.emergency_rounded,
        color: AppTheme.generator,
      ),
    ];

    return Row(
      children: opts
          .map((o) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: o == opts.last ? 0 : 10),
                  child: _sourceChip(o),
                ),
              ))
          .toList(),
    );
  }

  Widget _sourceChip(SrcOpt o) {
    final selected = _mode == o.mode && _src == o.src;
    final c = o.color;

    return GestureDetector(
      onTap: _sending ? null : () => _setSource(o.mode, o.src),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? c : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? c
                : AppTheme.border,
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: c.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 5))]
              : AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : c.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(o.icon,
                  color: selected ? Colors.white : c, size: 22),
            ),
            const SizedBox(height: 10),
            Text(o.label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textPri)),
            const SizedBox(height: 2),
            Text(o.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: selected
                        ? Colors.white70
                        : AppTheme.textSec)),
          ],
        ),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────
  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: AppTheme.isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.accent, size: 15),
          const SizedBox(width: 6),
          Text('AUTO Mode Logic',
              style: AppTheme.label(12, color: AppTheme.accent)),
        ]),
        const SizedBox(height: 12),
        _infoRow('☀️', 'PV available → charge battery + power load'),
        _infoRow('🔋', 'Battery ≥ 30% → power from battery '),
        _infoRow('⚡', 'Battery critical → rescue starts'),
        _infoRow('🔒', 'MANUAL → forces the selected source'),
      ]),
    );
  }

  Widget _infoRow(String emoji, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTheme.body(12, color: AppTheme.textPri)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
//  DATA CLASS
// ─────────────────────────────────────────────────────────────────

class SrcOpt {
  final String label;
  final String subtitle;
  final String mode;
  final String src;
  final IconData icon;
  final Color color;

  const SrcOpt({
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.src,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────
//  DOT PAINTER  (reused from zone card)
// ─────────────────────────────────────────────────────────────────

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const s = 18.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.3, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
