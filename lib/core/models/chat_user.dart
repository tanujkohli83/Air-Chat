import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  const ChatUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.photoBase64,
    required this.photoMimeType,
    required this.isOnline,
    required this.createdAt,
    required this.lastSeen,
    required this.displayNameLower,
    required this.fcmToken,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? photoBase64;
  final String? photoMimeType;
  final bool isOnline;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final String displayNameLower;
  final String? fcmToken;

  bool get hasCompletedProfile => displayName.trim().isNotEmpty;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      final emailPrefix = email.split('@').first;
      return emailPrefix.isEmpty
          ? 'U'
          : emailPrefix.substring(0, 1).toUpperCase();
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  ChatUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? photoBase64,
    String? photoMimeType,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? displayNameLower,
    String? fcmToken,
  }) {
    return ChatUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoMimeType: photoMimeType ?? this.photoMimeType,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      displayNameLower: displayNameLower ?? this.displayNameLower,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'photoMimeType': photoMimeType,
      'isOnline': isOnline,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      'fcmToken': fcmToken,
    };
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      displayNameLower: map['displayNameLower'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      photoBase64: map['photoBase64'] as String?,
      photoMimeType: map['photoMimeType'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
      lastSeen: _readDate(map['lastSeen']),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
