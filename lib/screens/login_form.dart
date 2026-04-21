import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenvolt/screens/home.dart';
import 'package:greenvolt/screens/register_form.dart';
import 'package:greenvolt/services/auth_service.dart';
import 'package:greenvolt/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Please fill in all fields', true); return;
    }
    setState(() => _loading = true);
    try {
      final user = await AuthService()
          .login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (user != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Login failed', true);
    } catch (_) {
      _snack('Unexpected error', true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, bool error) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
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
          // ── Dark header ─────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
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
                Positioned.fill(
                    child: CustomPaint(painter: _MiniDotPainter())),
                // Glow circle
                Positioned(
                  right: -40, top: -40,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(alpha: 0.07),
                    ),
                  ),
                ),
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
                        Container(
                          width: 36, height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Welcome Back',
                            style: GoogleFonts.dmSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Sign in to continue',
                            style: GoogleFonts.dmSans(
                                fontSize: 14, color: Colors.white54)),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const SizedBox(height: 4),

                  // Email
                  EcField(
                    ctrl: _emailCtrl,
                    hint: 'Email address',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Password (single field with visibility toggle)
                  Container(
                    decoration: AppTheme.inputBox,
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.dmSans(
                          fontSize: 15, color: AppTheme.textPri),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: AppTheme.body(14,
                            color: AppTheme.textSec.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: AppTheme.textSec, size: 18),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSec,
                            size: 18,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Forgot password?',
                          style: AppTheme.body(13,
                              color: AppTheme.accent)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  EcButton(
                    text: 'Login',
                    icon: Icons.login_rounded,
                    loading: _loading,
                    onPressed: _login,
                    color: AppTheme.headerMid,
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: AppTheme.body(14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterScreen()),
                        ),
                        child: Text('Sign up',
                            style: AppTheme.bold(14,
                                color: AppTheme.accent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.06);
    const s = 18.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
