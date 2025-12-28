import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_home.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

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
      case 'invalid-credential': // yeni sürümlerde sık çıkıyor
        return "E-posta veya şifre hatalı.";
      case 'too-many-requests':
        return "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.";
      case 'network-request-failed':
        return "İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.";
      default:
        return "Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.";
    }
  }

  Future<void> _loginTeacher() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final uid = cred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('ogretmenler')
          .doc(uid)
          .get();

      final aktif = doc.data()?['aktif'] == true;

      if (!doc.exists || !aktif) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu hesap öğretmen yetkili değil.")),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherHome()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_trAuthError(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu. Lütfen tekrar deneyin.")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            colors: isDark
                ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 360,
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
                        Icons.admin_panel_settings,
                        size: 72,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Öğretmen Girişi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _input(
                        controller: _emailController,
                        hint: "E-posta",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),
                      _input(
                        controller: _passwordController,
                        hint: "Şifre",
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 26),
                      _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loginTeacher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            "Giriş Yap",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withAlpha(38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
