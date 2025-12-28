import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'teacher_login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDarkMode
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withAlpha(115) // ~0.45
                          : Colors.white.withAlpha(64), // ~0.25
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 90, color: Colors.white),
                        const SizedBox(height: 18),
                        const Text(
                          "Duyuru Sistemine\nHoş Geldiniz",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildBtn(
                          context,
                          "Öğrenci Girişi",
                          Colors.white,
                          Colors.deepPurple,
                          const LoginPage(),
                        ),
                        const SizedBox(height: 14),
                        _buildOutlineBtn(
                          context,
                          "Öğretmen Girişi",
                          const TeacherLoginPage(),
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

  // İŞLEYİŞ AYNI: sadece görünüm modernleştirildi
  Widget _buildBtn(
      BuildContext context, String txt, Color bg, Color clr, Widget page) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: clr,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 6,
        ),
        child: Text(
          txt,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOutlineBtn(BuildContext context, String txt, Widget page) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          foregroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          txt,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
