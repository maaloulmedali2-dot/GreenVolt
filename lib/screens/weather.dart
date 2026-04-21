import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/screens/welcome_screen.dart';
import 'package:greenvolt/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherScreen extends StatefulWidget {
  @override _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final city = "Sfax";
  final apiKey = "69af3c774e644468a42164412250802";
  Map<String, dynamic>? data;
  String sr = '', ss = '', sh = '';
  double cc = 0, ash = 0;
  bool loading = true; String? err;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { loading = true; err = null; });
    try {
      final r = await http.get(Uri.parse(
          'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=3&aqi=no'));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        _parseSun(d);
        double tot = 0;
        final hrs = d['forecast']['forecastday'][0]['hour'] as List;
        for (final h in hrs) tot += (h['cloud'] as num).toDouble();
        cc  = tot / hrs.length;
        ash = double.parse(sh.split('h')[0]) * (1 - cc / 100);
        setState(() { data = d; loading = false; });
      } else { setState(() { err = 'Error ${r.statusCode}'; loading = false; }); }
    } catch (e) { setState(() { err = 'Connection error'; loading = false; }); }
  }

  void _parseSun(Map<String, dynamic> d) {
    try {
      sr = d['forecast']['forecastday'][0]['astro']['sunrise'];
      ss = d['forecast']['forecastday'][0]['astro']['sunset'];
      final fmt = DateFormat('h:mm a');
      final dur = fmt.parse(ss).difference(fmt.parse(sr));
      sh = '${dur.inHours}h ${dur.inMinutes % 60}m';
    } catch (_) { sr = ss = 'N/A'; sh = '0h 0m'; }
  }

  IconData _icon(int c) {
    if (c == 1000) return WeatherIcons.day_sunny;
    if (c == 1003) return WeatherIcons.day_cloudy;
    if (c <= 1030) return WeatherIcons.cloudy;
    if (c <= 1069) return WeatherIcons.rain;
    return WeatherIcons.cloudy;
  }

  Color _tc(double t) {
    if (t >= 35) return Colors.red.shade600;
    if (t >= 25) return AppTheme.solar;
    if (t >= 15) return AppTheme.accent;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(children: [
        EcHeader(
          title: 'Weather — $city',
          icon: Icons.cloud_rounded,
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetch),
            IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  await AuthService().logout();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()));
                }),
          ],
        ),
        Expanded(child: loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : err != null ? _err()
            : _body()),
        const EcNav(selected: 3),
      ]),
    );
  }

  Widget _body() {
    final cur  = data!['current'];
    final temp = (cur['temp_c'] as num).toDouble();
    final wind = (cur['wind_kph'] as num).toDouble();
    final hum  = (cur['humidity'] as num).toDouble();
    final cond = cur['condition']['text'] as String;
    final code = cur['condition']['code'] as int;
    final fc   = data!['forecast']['forecastday'] as List;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Main weather card (dark) ────────────────────────────
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0D2540), Color(0xFF1A3A60)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.deepShadow,
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -20,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha:0.08)))),
          Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(city, style: GoogleFonts.rajdhani(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                Text(cond, style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white60)),
              ]),
              BoxedIcon(_icon(code), color: Colors.white70, size: 44),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${temp.toStringAsFixed(0)}°C',
                  style: GoogleFonts.rajdhani(fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: _tc(temp), height: 1)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _ws(Icons.air_rounded, '${wind.toStringAsFixed(0)} km/h'),
                const SizedBox(height: 6),
                _ws(Icons.water_drop_rounded, '${hum.toStringAsFixed(0)}%'),
              ]),
            ]),
          ]),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Solar info ───────────────────────────────────────────
      Row(children: [
        Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.solar.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.wb_sunny_rounded, color: AppTheme.solar, size: 15)),
        const SizedBox(width: 8),
        Text('Sun & Solar', style: AppTheme.label(14)),
      ]),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(18), decoration: AppTheme.card,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _sun(WeatherIcons.sunrise, sr, 'Sunrise', Colors.orange.shade300),
            Container(width: 1, height: 50, color: AppTheme.border),
            _sun(WeatherIcons.sunset, ss, 'Sunset', Colors.orange.shade700),
            Container(width: 1, height: 50, color: AppTheme.border),
            _sun(WeatherIcons.day_sunny, sh, 'Sun Hours', AppTheme.solar),
          ]),
          const SizedBox(height: 16),
          // Cloud cover
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Cloud Cover', style: AppTheme.body(12)),
            Text('${cc.toStringAsFixed(0)}%', style: AppTheme.label(12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: cc / 100,
                  minHeight: 7, backgroundColor: AppTheme.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(Colors.blueGrey))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.solar.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.solar.withValues(alpha:0.25)),
            ),
            child: Row(children: [
              Icon(Icons.solar_power_rounded, color: AppTheme.solar, size: 20),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Effective Solar Hours', style: AppTheme.body(11)),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(ash.toStringAsFixed(1),
                      style: AppTheme.metric(22, AppTheme.solar)),
                  Padding(padding: const EdgeInsets.only(bottom: 2, left: 3),
                      child: Text('h/day', style: AppTheme.body(12, color: AppTheme.solar))),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // ── 3-day forecast ───────────────────────────────────────
      Row(children: [
        Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.calendar_today_rounded, color: AppTheme.accent, size: 15)),
        const SizedBox(width: 8),
        Text('3-Day Forecast', style: AppTheme.label(14)),
      ]),
      const SizedBox(height: 10),
      Container(decoration: AppTheme.card,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fc.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppTheme.border.withValues(alpha:0.5)),
          itemBuilder: (_, i) {
            final day  = fc[i];
            final date = DateTime.parse(day['date']);
            final max  = (day['day']['maxtemp_c'] as num).toDouble();
            final min  = (day['day']['mintemp_c'] as num).toDouble();
            final c    = day['day']['condition']['code'] as int;
            final lbl  = i == 0 ? 'Today' : DateFormat('EEE, d MMM').format(date);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                SizedBox(width: 90, child: Text(lbl,
                    style: AppTheme.label(13, color: i == 0 ? AppTheme.textPri : AppTheme.textSec))),
                BoxedIcon(_icon(c), color: Colors.blueGrey, size: 18),
                const Spacer(),
                Text('${min.toStringAsFixed(0)}°',
                    style: AppTheme.body(13)),
                const SizedBox(width: 6),
                Container(width: 50, height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                          colors: [Colors.blue.shade200, _tc(max)]),
                    )),
                const SizedBox(width: 6),
                Text('${max.toStringAsFixed(0)}°',
                    style: AppTheme.bold(13, color: _tc(max))),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _ws(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, color: Colors.white54, size: 13),
        const SizedBox(width: 4),
        Text(t, style: GoogleFonts.dmSans(
            color: Colors.white70, fontSize: 12)),
      ]);

  Widget _sun(IconData i, String v, String l, Color c) => Column(children: [
    BoxedIcon(i, color: c, size: 22),
    const SizedBox(height: 6),
    Text(v, style: AppTheme.label(13)),
    Text(l, style: AppTheme.body(11)),
  ]);

  Widget _err() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.border),
      const SizedBox(height: 12),
      Text(err!, style: AppTheme.body(15)),
      const SizedBox(height: 20),
      EcButton(text: 'Retry', onPressed: _fetch, width: 120),
    ],
  ));
}