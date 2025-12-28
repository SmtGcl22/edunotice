import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadFile({
    required File file,
    required String folder,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('$folder/$fileName');
    final task = ref.putFile(file);
    final snap = await task;
    return snap.ref.getDownloadURL();
  }
}
