import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static Future<void> logout() => FirebaseAuth.instance.signOut();
}
