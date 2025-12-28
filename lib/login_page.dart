import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'student_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String _trAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Geçersiz e-posta adresi.";
      case 'user-disabled':
        return "Bu hesap devre dışı bırakılmış.";
      case 'user-not-found':
        return "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      case 'wrong-password':
        return "Şifre hatalı.";
      case 'invalid-credential':
        return "E-posta veya şifre hatalı.";
      case 'too-many-requests':
        return "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.";
      case 'network-request-failed':
        return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.";
      default:
        return "Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.";
    }
  }

  Future<void> _girisYap() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHome()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_trAuthError(e))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu. Lütfen tekrar deneyin.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Öğrenci Girişi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Geri",
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withAlpha(115)
                          : Colors.white.withAlpha(64),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_pin_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Öğrenci Paneli",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 26),

                        _inputBox(
                          isDark,
                          TextField(
                            controller: _emailController,
                            decoration: _dec("Email", Icons.email, isDark),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _inputBox(
                          isDark,
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _dec("Şifre", Icons.lock, isDark),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 22),

                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _girisYap,
                            style: _btnSty(),
                            child: const Text(
                              "Giriş Yap",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            "Kayıt Ol",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBox(bool isDark, Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(38),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white24),
    ),
    child: child,
  );

  InputDecoration _dec(String lbl, IconData icn, bool isDark) => InputDecoration(
    hintText: lbl,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icn, color: Colors.white),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.all(18),
  );

  ButtonStyle _btnSty() => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.deepPurple,
    minimumSize: const Size.fromHeight(60),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 6,
  );
}
