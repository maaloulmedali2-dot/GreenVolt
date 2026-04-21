import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:greenvolt/providers/theme_notifier.dart';
import 'package:greenvolt/providers/zone_provider.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sRef = FirebaseDatabase.instance.ref('system/sensors');
  final _tRef = FirebaseDatabase.instance.ref('system/status');
  final _cRef = FirebaseDatabase.instance.ref('system/commands');

  double bv = 0; int bp = 0;
  double pv = 0; double pc = 0;
  String src = '--'; bool gen = false;
  String bst = '--'; String mode = '--';

  @override
  void initState() {
    super.initState();
    _sRef.onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() {
        bv = ((d['batteryVoltage'] ?? 0) as num).toDouble();
        bp = ((d['batteryPercent'] ?? 0) as num).toInt();
        pv = ((d['pvVoltage']      ?? 0) as num).toDouble();
        pc = ((d['pvCurrent']      ?? 0) as num).toDouble();
      });
    });
    _tRef.onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() {
        src = (d['activeSource'] ?? '--').toString().toUpperCase();
        gen = d['generatorRunning'] == true || d['generatorRunning'] == 1;
        bst = (d['batteryState'] ?? '--').toString().toUpperCase();
      });
    });
    _cRef.child('mode').onValue.listen((e) {
      if (!e.snapshot.exists) return;
      setState(() => mode = e.snapshot.value.toString().toUpperCase());
    });
  }

  Color _bc() {
    if (bp >= 60) return AppTheme.accent;
    if (bp >= 30) return AppTheme.warning;
    return AppTheme.danger;
  }

  Color _sc(String s) {
    switch (s) {
      case 'GOOD':   return AppTheme.accent;
      case 'LOW':      return AppTheme.warning;
      case 'CRITICAL': return AppTheme.danger;
      default:         return AppTheme.textSec;
    }
  }

  String get _greet {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _user =>
      FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'User';

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    final pw = pv * pc * 100 ;
    final themeN = context.watch<ThemeNotifier>();
    final zoneP  = context.watch<ZoneProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          EcHeader(
            title: 'EnerCamp',
            icon: Icons.bolt_rounded,
            actions: [
              // Dark mode toggle
              IconButton(
                icon: Icon(
                  themeN.isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: themeN.toggle,
              ),
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
            bottom: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_greet, $_user',
                      style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  // Status strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _strip('Mode', mode,
                            mode == 'AUTO'
                                ? AppTheme.accentDim
                                : Colors.orangeAccent),
                        _vd(),
                        _strip('Source', src.isEmpty ? '--' : src,
                            Colors.lightBlueAccent),
                        _vd(),
                        _strip('Battery', bst,
                            bst == 'GOOD' || bst == 'NORMAL'
                                ? AppTheme.accentDim
                                : bst == 'LOW'
                                    ? Colors.orangeAccent
                                    : AppTheme.danger),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Solar ──────────────────────────────────────
                _secLabel('Solar', Icons.wb_sunny_rounded, AppTheme.solar),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _numCard('PV Voltage',
                      pv.toStringAsFixed(1), 'V', AppTheme.solar,
                      Icons.bolt_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _numCard('PV Current',
                      pc.toStringAsFixed(2), 'A', AppTheme.accent,
                      Icons.electric_bolt_rounded)),
                ]),
                const SizedBox(height: 12),
                _wideNumCard('PV Power',
                    pw.toStringAsFixed(1), 'W',
                    Icons.solar_power_rounded, AppTheme.headerMid),

                const SizedBox(height: 22),

                // ── Battery (full inline) ──────────────────────
                _secLabel('Battery',
                    Icons.battery_charging_full_rounded, _bc()),
                const SizedBox(height: 10),
                _batteryCard(),

                const SizedBox(height: 22),

                // ── Active Consumption ────────────────────────
                _secLabel('Active Consumption',
                    Icons.power_rounded, Colors.indigo),
                const SizedBox(height: 10),
                _consumptionCard(zoneP),
              ],
            ),
          ),

          const EcNav(selected: 0),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────
  Widget _secLabel(String t, IconData i, Color c) => Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(i, color: c, size: 15),
        ),
        const SizedBox(width: 8),
        Text(t, style: AppTheme.label(14)),
      ]);

  Widget _strip(String lbl, String val, Color vc) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(lbl,
              style: GoogleFonts.dmSans(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: vc.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: vc.withValues(alpha: 0.45)),
            ),
            child: Text(val,
                style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700, color: vc)),
          ),
        ],
      );

  Widget _vd() =>
      Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.15));

  // ── Num card ───────────────────────────────────────────────────
  Widget _numCard(String lbl, String val, String unit, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: c, size: 16),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(val, style: AppTheme.metric(24, c)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 3),
            Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: AppTheme.body(11,
                        color: c.withValues(alpha: 0.7)))),
          ],
        ]),
        const SizedBox(height: 2),
        Text(lbl, style: AppTheme.body(11)),
      ]),
    );
  }

  Widget _wideNumCard(
      String lbl, String val, String unit, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.headerDark, AppTheme.headerMid]),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AppTheme.accent, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(val, style: AppTheme.metric(28, AppTheme.accent)),
            Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 3),
                child: Text(unit,
                    style: AppTheme.body(12,
                        color: AppTheme.accentDim))),
          ]),
          Text(lbl, style: AppTheme.body(12)),
        ]),
      ]),
    );
  }

  // ── Full battery card (inline — no nav button) ─────────────────
  Widget _batteryCard() {
    final c = _bc();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
        border: AppTheme.isDark
            ? Border.all(color: AppTheme.border)
            : Border(left: BorderSide(color: c, width: 4)),
      ),
      child: Column(children: [
        // Top row: percent + badge + voltage
        Row(children: [
          // Circular arc indicator
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: bp / 100.0,
                  strokeWidth: 7,
                  backgroundColor: AppTheme.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(c),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$bp%', style: AppTheme.metric(18, c)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EcBadge(label: bst, color: _sc(bst)),
                const SizedBox(height: 6),
                Text('${bv.toStringAsFixed(2)} V',
                    style: AppTheme.label(15, color: c)),
                const SizedBox(height: 2),
                Text('Battery voltage',
                    style: AppTheme.body(11)),
              ],
            ),
          ),
          // Health thresholds compact
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _threshDot('Good ≥60%',  AppTheme.accent,  bp >= 60),
            const SizedBox(height: 6),
            _threshDot('Low 20–59%', AppTheme.warning, bp < 60 && bp >= 20),
            const SizedBox(height: 6),
            _threshDot('Crit <20%',  AppTheme.danger,  bp < 20),
          ]),
        ]),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: bp / 100.0,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(c),
          ),
        ),
        const SizedBox(height: 14),
        // Bottom stats row
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _batStat('${bv.toStringAsFixed(2)} V', 'Voltage',
              Icons.electrical_services_rounded),
          Container(width: 1, height: 36, color: AppTheme.border),
          _batStat(_autonomy(), 'Autonomy', Icons.timer_rounded),
          Container(width: 1, height: 36, color: AppTheme.border),
          _batStat(bst, 'State',
              Icons.battery_charging_full_rounded),
        ]),
      ]),
    );
  }

  String _autonomy() {
    if (bp <= 0) return '--';
    // rough estimate: 50 Wh per percent at 12V nominal
    const wh = 50.0;
    final zoneW = context.read<ZoneProvider>().totalConsumption;
    if (zoneW <= 0) return '--';
    final hrs = (bp * wh) / zoneW;
    if (hrs > 24) return '>24h';
    return '${hrs.floor()}h ${((hrs % 1) * 60).round()}m';
  }

  Widget _threshDot(String label, Color c, bool active) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? c : AppTheme.border),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTheme.body(9,
                  color: active ? c : AppTheme.textSec)),
        ],
      );

  Widget _batStat(String val, String lbl, IconData icon) =>
      Column(children: [
        Icon(icon, color: AppTheme.textSec, size: 16),
        const SizedBox(height: 4),
        Text(val, style: AppTheme.metric(14, AppTheme.textPri)),
        Text(lbl, style: AppTheme.body(10)),
      ]);

  // ── Active consumption card ────────────────────────────────────
  Widget _consumptionCard(ZoneProvider zp) {
    final total = zp.totalConsumption;
    final z1    = zp.zoneById('zone1');
    final z2    = zp.zoneById('zone2');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.card,
      child: Column(children: [
        // Total
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D1F4A), Color(0xFF1A3080)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.electrical_services_rounded,
                color: Color(0xFF82B1FF), size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                total >= 1000
                    ? (total / 1000).toStringAsFixed(2)
                    : total.toStringAsFixed(0),
                style: AppTheme.metric(28,
                    total > 0
                        ? const Color(0xFF82B1FF)
                        : AppTheme.textSec),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 3),
                child: Text(total >= 1000 ? 'kW' : 'W',
                    style: AppTheme.body(12,
                        color: const Color(0xFF82B1FF)
                            .withValues(alpha: 0.7))),
              ),
            ]),
            Text('Total active load', style: AppTheme.body(12)),
          ]),
        ]),
        const SizedBox(height: 14),
        Container(height: 1, color: AppTheme.border),
        const SizedBox(height: 12),
        // Per-zone breakdown
        Row(children: [
          Expanded(child: _zoneConsRow(z1, AppTheme.accent)),
          const SizedBox(width: 12),
          Expanded(
              child: _zoneConsRow(z2, const Color(0xFF448AFF))),
        ]),
      ]),
    );
  }

  Widget _zoneConsRow(dynamic zone, Color c) {
    final bool   isActive = zone.isActive as bool;
    final double total    = zone.totalConsumption as double;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive
                ? c.withValues(alpha: 0.3)
                : AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? c : AppTheme.border)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(zone.name as String,
                style: AppTheme.body(11,
                    color: isActive ? AppTheme.textPri : AppTheme.textSec),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          isActive ? '${total.toStringAsFixed(0)} W' : 'OFF',
          style: AppTheme.metric(
              18, isActive ? c : AppTheme.textSec),
        ),
      ]),
    );
  }
}
