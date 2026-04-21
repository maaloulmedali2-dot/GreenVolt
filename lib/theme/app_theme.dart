import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  ENERCAMP  ·  Design System  ·  "Dark Precision / Field Terminal"
//
//  Dark mode adaptive: bg / surface / surfaceAlt / border /
//  textPri / textSec are getters that flip with _dark flag.
//  All accent / status colors are identical in both modes.
// ─────────────────────────────────────────────────────────────────

class AppTheme {
  // ── Dark mode flag (set by ThemeNotifier) ────────────────────
  static bool _dark = true;
  static bool get isDark => _dark;
  static void setDark(bool v) { _dark = v; }

  // ── Adaptive palette ─────────────────────────────────────────
  static Color get bg         => _dark ? const Color(0xFF0A1410) : const Color(0xFFF3F8F4);
  static Color get surface    => _dark ? const Color(0xFF111D16) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => _dark ? const Color(0xFF182318) : const Color(0xFFEDF5EF);
  static Color get border     => _dark ? const Color(0xFF1E3028) : const Color(0xFFDCEDE3);
  static Color get textPri    => _dark ? const Color(0xFFDFF0E8) : const Color(0xFF0D1F15);
  static Color get textSec    => _dark ? const Color(0xFF4A6A58) : const Color(0xFF6B8C7A);

  // ── Static palette ───────────────────────────────────────────
  static const Color headerDark  = Color(0xFF0D2318);
  static const Color headerMid   = Color(0xFF1A3A2A);
  static const Color headerLight = Color(0xFF1E4030);
  static const Color accent      = Color(0xFF00C853);
  static const Color accentDim   = Color(0xFF69F0AE);
  static const Color solar       = Color(0xFFF59E0B);
  static const Color generator   = Color(0xFFE64A19);
  static const Color danger      = Color(0xFFE53935);
  static const Color warning     = Color(0xFFFF9F0A);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient headerGrad = LinearGradient(
    colors: [headerDark, headerMid, headerLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGrad = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => _dark
      ? [BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18, offset: const Offset(0, 4))]
      : [BoxShadow(
          color: const Color(0xFF0D2318).withValues(alpha: 0.08),
          blurRadius: 20, offset: const Offset(0, 6))];

  static List<BoxShadow> get accentShadow => [
    BoxShadow(
        color: accent.withValues(alpha: 0.35),
        blurRadius: 16, offset: const Offset(0, 6))];

  static List<BoxShadow> get deepShadow => _dark
      ? [BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 28, offset: const Offset(0, 10))]
      : [BoxShadow(
          color: const Color(0xFF0D2318).withValues(alpha: 0.18),
          blurRadius: 28, offset: const Offset(0, 10))];

  // ── Typography ───────────────────────────────────────────────
  static TextStyle metric(double size, Color color) =>
      GoogleFonts.rajdhani(
          fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle label(double size, {Color? color}) =>
      GoogleFonts.dmSans(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color ?? textPri);

  static TextStyle body(double size, {Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, color: color ?? textSec);

  static TextStyle bold(double size, {Color? color}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: FontWeight.w700, color: color ?? textPri);

  // ── Decorations ──────────────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow,
        border: _dark
            ? Border.all(color: border)
            : null,
      );

  static BoxDecoration cardWithBorder(Color accentColor) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow,
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      );

  static BoxDecoration get inputBox => BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      );

  // ── System UI ────────────────────────────────────────────────
  static void setStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class EcHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? bottom;

  const EcHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/backimage.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.30),
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _DotGrid()),
            Positioned(
              right: -30, top: -30,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.35),
                              width: 1),
                        ),
                        child: Icon(icon, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title,
                            style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2)),
                      ),
                      ...?actions,
                    ],
                  ),
                ),
                if (bottom != null) bottom!,
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotPainter());
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class EcNav extends StatelessWidget {
  final int selected;
  const EcNav({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.4 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, Icons.dashboard_rounded, 'Dashboard', '/home', 0),
              _item(context, Icons.layers_rounded,    'Zones',     '/zones', 1),
              _item(context, Icons.tune_rounded,      'Control',   '/control', 2),
              _item(context, Icons.cloud_rounded,     'Weather',   '/weather', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label,
      String route, int idx) {
    final active = selected == idx;
    return GestureDetector(
      onTap: () { if (!active) Navigator.pushNamed(ctx, route); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppTheme.accent : AppTheme.textSec,
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: active ? AppTheme.accent : AppTheme.textSec,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  final IconData? icon;

  const StatTile({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTheme.metric(26, color)),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: AppTheme.body(12,
                        color: color.withValues(alpha: 0.75))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.body(11)),
        ],
      ),
    );
  }
}

class EcField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  const EcField({
    super.key,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.inputBox,
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.textPri),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.body(14,
              color: AppTheme.textSec.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: AppTheme.textSec, size: 18),
          suffixText: suffix,
          suffixStyle: AppTheme.bold(13, color: AppTheme.textSec),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class EcButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final IconData? icon;
  final double? width;

  const EcButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.color,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.accent;
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

class EcBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const EcBadge(
      {super.key,
      required this.label,
      required this.color,
      this.size = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}
