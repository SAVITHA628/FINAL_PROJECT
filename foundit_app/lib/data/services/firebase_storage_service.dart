import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadItemImage(String userId, File imageFile) async {
    final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('item_images').child(userId).child(fileName);
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('profile_images').child(userId).child(fileName);
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
