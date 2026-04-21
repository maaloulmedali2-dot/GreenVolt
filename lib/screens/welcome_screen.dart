import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Full background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backimage.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dot grid texture
          Positioned.fill(child: CustomPaint(painter: _FullDotPainter())),

          // Decorative circles
          Positioned(top: -80, right: -80,
              child: _circle(260, AppTheme.accent.withValues(alpha:0.05))),
          Positioned(top: 120, right: 40,
              child: _circle(80, AppTheme.accent.withValues(alpha:0.06))),
          Positioned(bottom: 200, left: -60,
              child: _circle(200, AppTheme.accent.withValues(alpha:0.04))),

          SafeArea(
            child: Column(
              children: [
                // ── Top section: logo + name ──────────────────
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing icon
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha:0.12),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha:0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.accent.withValues(alpha:0.25),
                                blurRadius: 30,
                                spreadRadius: 4),
                          ],
                        ),
                        child: Icon(Icons.bolt_rounded,
                            color: AppTheme.accent, size: 52),
                      ),
                      const SizedBox(height: 24),
                      Text('EnerCamp',
                          style: GoogleFonts.rajdhani(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('Smart Energy · Outdoor Life',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white54,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 40),

                      // Feature pills
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _pill(Icons.wb_sunny_rounded, 'Solar'),
                          _pill(Icons.battery_charging_full_rounded, 'Battery'),
                          _pill(Icons.power_rounded, 'Generator'),
                          _pill(Icons.wifi_rounded, 'IoT'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Bottom card ───────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.accent.withValues(alpha:0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Get Started',
                          style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPri)),
                      const SizedBox(height: 6),
                      Text('Monitor and control your energy system.',
                          style: AppTheme.body(13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 22),
                      EcButton(
                        text: 'Login',
                        icon: Icons.login_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        color: AppTheme.headerMid,
                      ),
                      const SizedBox(height: 10),
                      EcButton(
                        text: 'Create Account',
                        icon: Icons.person_add_rounded,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _pill(IconData icon, String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppTheme.accentDim, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _FullDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha:0.05);
    const s = 22.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}