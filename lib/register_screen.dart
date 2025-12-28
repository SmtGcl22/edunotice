import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedClass = '10-A';
  bool _isLoading = false;

  final List<String> _classes = ['10-A', '10-B', '11-A', '11-B', '12-A'];

  Future<void> _kayitOl() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('ogrenciler')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'isim': _nameController.text.trim(),
        'sinif': _selectedClass,
        'email': _emailController.text.trim(),
        'rol': 'ogrenci',

        // okundu/okunmadı kullanacaksan dursun (kapatmak istersen alttan siliyoruz)
        'okunanDuyurular': <String>[],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt Başarılı! Giriş yapabilirsiniz.")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt Hatası: ${e.message}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDarkMode
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF667EEA), const Color(0xFF764BA2)];

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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradColors,
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
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 74,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Yeni Hesap Oluştur",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 26),

                        _box(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec("Ad Soyad", Icons.person),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _box(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF0F2027)
                                : const Color(0xFF667EEA),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            items: _classes
                                .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedClass = val!),
                            decoration:
                            _dec("Sınıf Seçiniz", Icons.class_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _box(
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec("Okul Email", Icons.email),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _box(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec("Şifre", Icons.lock),
                          ),
                        ),

                        const SizedBox(height: 22),

                        _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _kayitOl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 6,
                            ),
                            child: const Text(
                              "Kayıt Ol",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Geri Dön",
                            style: TextStyle(color: Colors.white70),
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

  // Fonksiyon isimlerini korudum, sadece görünümü login ile uyumlu yaptım
  Widget _box({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(38), // ~0.15
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white24),
    ),
    child: child,
  );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.all(18),
  );
}
