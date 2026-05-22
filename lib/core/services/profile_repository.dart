import 'dart:convert';
import 'dart:typed_data';

import 'package:chatapp/core/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AvatarImageData {
  const AvatarImageData({required this.base64, required this.mimeType});

  final String base64;
  final String? mimeType;
}

class ProfileRepository {
  ProfileRepository(this._firestore);

  static const int maxAvatarBase64Length = 750 * 1024;

  final FirebaseFirestore _firestore;

  Future<AvatarImageData?> encodeAvatar({
    required XFile? image,
  }) async {
    if (image == null) return null;

    final Uint8List bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);
    if (base64.length > maxAvatarBase64Length) {
      throw StateError(
        'Selected image is too large. Please choose a smaller profile photo.',
      );
    }

    return AvatarImageData(base64: base64, mimeType: image.mimeType);
  }

  Future<void> saveProfile({
    required String uid,
    required String email,
    required String displayName,
    AvatarImageData? avatarImage,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName.trim(),
      'displayNameLower': displayName.trim().toLowerCase(),
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    };

    if (avatarImage != null) {
      data.addAll({
        'photoBase64': avatarImage.base64,
        'photoMimeType': avatarImage.mimeType,
        'photoUrl': null,
      });
    }

    await _firestore.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Stream<ChatUser?> watchCurrentUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.data() == null
              ? null
              : ChatUser.fromMap(snapshot.data()!),
        );
  }
}
