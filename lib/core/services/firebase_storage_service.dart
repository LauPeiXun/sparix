import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadImage(String path, String filename, File imageFile) async {
    try {
      final ref = _storage.ref().child('$path/$filename');
      await ref.putFile(imageFile);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getImage(String path, String filename) async {
    try {
      final ref = _storage.ref().child('$path/$filename');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String path, String filename) async {
    try {
      final ref = _storage.ref().child('$path/$filename');
      await ref.delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }
}

