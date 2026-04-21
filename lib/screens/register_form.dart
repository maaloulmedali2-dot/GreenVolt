import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/screens/login_form.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obs1 = true, _obs2 = true;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    _confirmCtrl.dispose(); super.dispose();
  }

  Future<void> _register() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Fill in all fields', true); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match', true); return;
    }
    if (_passCtrl.text.length < 6) {
      _snack('Password must be ≥ 6 characters', true); return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().signup(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        context: context,
      ).then((_) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final batch = FirebaseFirestore.instance.batch();
          final base = FirebaseFirestore.instance
              .collection('users').doc(user.uid);
          batch.set(base, {'uid': user.uid}, SetOptions(merge: true));
          batch.set(base.collection('zones').doc('zone1'),
              {'name': 'Zone 1', 'priority': 1, 'isActive': true,
               'totalWh': 0.0, 'totalW': 0.0, 'deviceCount': 0},
              SetOptions(merge: true));
          batch.set(base.collection('zones').doc('zone2'),
              {'name': 'Zone 2', 'priority': 2, 'isActive': true,
               'totalWh': 0.0, 'totalW': 0.0, 'deviceCount': 0},
              SetOptions(merge: true));
          await batch.commit();
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, bool error) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: error ? AppTheme.danger : AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  @override
  Widget build(BuildContext context) {
    AppTheme.setStatusBar();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.33,
            child: Stack(
              children: [
                Container(
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
                ),
                Positioned.fill(child: CustomPaint(painter: _DotP())),
                Positioned(right: -50, bottom: -50,
                    child: Container(width: 180, height: 180,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: AppTheme.accent.withValues(alpha: 0.06)))),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Container(width: 36, height: 3,
                          decoration: BoxDecoration(color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 10),
                      Text('Create Account',
                          style: GoogleFonts.dmSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Join EnerCamp today',
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: Colors.white54)),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                const SizedBox(height: 4),
                EcField(ctrl: _emailCtrl, hint: 'Email address',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _passField(_passCtrl, 'Password', _obs1,
                    () => setState(() => _obs1 = !_obs1)),
                const SizedBox(height: 12),
                _passField(_confirmCtrl, 'Confirm password', _obs2,
                    () => setState(() => _obs2 = !_obs2)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'By creating an account you agree to our Terms of Service.',
                    style: AppTheme.body(12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                EcButton(
                    text: 'Create Account',
                    icon: Icons.person_add_rounded,
                    loading: _loading,
                    onPressed: _register,
                    color: AppTheme.accent),
                const SizedBox(height: 28),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ', style: AppTheme.body(14)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: Text('Login', style: AppTheme.bold(14, color: AppTheme.accent)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint, bool obs,
      VoidCallback toggle) {
    return Container(
      decoration: AppTheme.inputBox,
      child: TextField(
        controller: ctrl,
        obscureText: obs,
        style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.textPri),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.body(14, color: AppTheme.textSec.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: AppTheme.textSec, size: 18),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(
                obs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppTheme.textSec, size: 18),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class _DotP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF00C853).withValues(alpha: 0.06);
    const s = 18.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}