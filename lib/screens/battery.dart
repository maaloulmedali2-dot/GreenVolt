// ─── battery.dart ─────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/theme/app_theme.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});
  @override _BatteryPageState createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  double bv = 0; int bp = 0; double lp = 0; String bst = '--';

  @override
  void initState() {
    super.initState();
    FirebaseDatabase.instance.ref('system/sensors').onValue.listen((e) {
      if (!e.snapshot.exists) return;
      final d = Map<String, dynamic>.from(e.snapshot.value as Map);
      setState(() {
        bv = ((d['batteryVoltage'] ?? 0) as num).toDouble();
        bp = ((d['batteryPercent'] ?? 0) as num).toInt();
        lp = ((d['loadPower']      ?? 0) as num).toDouble();
      });
    });
    FirebaseDatabase.instance.ref('system/status/batteryState')
        .onValue.listen((e) {
      if (e.snapshot.exists)
        setState(() => bst = e.snapshot.value.toString().toUpperCase());
    });
  }

  Color _c() {
    if (bp >= 60) return AppTheme.accent;
    if (bp >= 30) return AppTheme.warning;
    return AppTheme.danger;
  }

  String _auto() {
    if (lp <= 0 || bv <= 0) return '--';
    final wh = bp * 0.5;
    final hrs = wh / lp;
    if (hrs > 24) return '> 24h';
    return '${hrs.floor()}h ${((hrs % 1) * 60).round()}m';
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    final c = _c();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGrad),
          child: SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha:0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent.withValues(alpha:0.3)),
                  ),
                  child: Icon(Icons.battery_charging_full_rounded,
                      color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Battery Status',
                    style: GoogleFonts.dmSans(fontSize: 20,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          // Big radial card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: AppTheme.card,
            child: Column(children: [
              SizedBox(width: 170, height: 170,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 170, height: 170,
                    child: CircularProgressIndicator(
                      value: bp / 100.0, strokeWidth: 12,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(c),
                      strokeCap: StrokeCap.round)),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.battery_charging_full_rounded, color: c, size: 26),
                    const SizedBox(height: 4),
                    Text('$bp%', style: AppTheme.metric(36, c)),
                    EcBadge(label: bst, color: c, size: 10),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _tile('${bv.toStringAsFixed(2)} V', 'Voltage',
                    Icons.electrical_services_rounded),
                Container(width: 1, height: 40, color: AppTheme.border),
                _tile('${lp.toStringAsFixed(0)} W', 'Load',
                    Icons.power_rounded),
                Container(width: 1, height: 40, color: AppTheme.border),
                _tile(_auto(), 'Autonomy', Icons.timer_rounded),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Health Thresholds', style: AppTheme.label(14)),
          const SizedBox(height: 10),
          _thresh('Good', '≥ 60%', AppTheme.accent, bp >= 60),
          const SizedBox(height: 8),
          _thresh('Low', '20% – 59%', AppTheme.warning, bp < 60 && bp >= 20),
          const SizedBox(height: 8),
          _thresh('Critical', '< 20%', AppTheme.danger, bp < 20),
        ])),
      ]),
    );
  }

  Widget _tile(String val, String lbl, IconData icon) => Column(children: [
    Icon(icon, color: AppTheme.textSec, size: 18),
    const SizedBox(height: 6),
    Text(val, style: AppTheme.metric(15, AppTheme.textPri)),
    Text(lbl, style: AppTheme.body(11)),
  ]);

  Widget _thresh(String title, String range, Color color, bool active) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha:0.07) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? color.withValues(alpha:0.35) : AppTheme.border,
          width: active ? 1.5 : 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(
                color: active ? color : AppTheme.border, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTheme.label(14,
            color: active ? color : AppTheme.textSec))),
        Text(range, style: AppTheme.body(13,
            color: active ? color : AppTheme.textSec)),
        if (active) ...[const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: color, size: 18)],
      ]),
    );
}