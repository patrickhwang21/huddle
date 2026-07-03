import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref('users/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadEventCover(String eventId, File file) async {
    final ref = _storage.ref('events/$eventId/cover.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
