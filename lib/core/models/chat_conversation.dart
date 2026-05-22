import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.isGroup,
    required this.title,
    required this.photoUrl,
    required this.participantIds,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.createdAt,
    required this.unreadCountByUser,
    required this.typingUserIds,
  });

  final String id;
  final bool isGroup;
  final String title;
  final String? photoUrl;
  final List<String> participantIds;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final DateTime? createdAt;
  final Map<String, int> unreadCountByUser;
  final List<String> typingUserIds;

  int unreadCountFor(String userId) => unreadCountByUser[userId] ?? 0;

  ChatConversation copyWith({
    String? id,
    bool? isGroup,
    String? title,
    String? photoUrl,
    List<String>? participantIds,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastSenderId,
    DateTime? createdAt,
    Map<String, int>? unreadCountByUser,
    List<String>? typingUserIds,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      photoUrl: photoUrl ?? this.photoUrl,
      participantIds: participantIds ?? this.participantIds,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      createdAt: createdAt ?? this.createdAt,
      unreadCountByUser: unreadCountByUser ?? this.unreadCountByUser,
      typingUserIds: typingUserIds ?? this.typingUserIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGroup': isGroup,
      'title': title,
      'photoUrl': photoUrl,
      'participantIds': participantIds,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt == null
          ? null
          : Timestamp.fromDate(lastMessageAt!),
      'lastSenderId': lastSenderId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'unreadCountByUser': unreadCountByUser,
      'typingUserIds': typingUserIds,
    };
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    final unreadMap =
        (map['unreadCountByUser'] as Map<String, dynamic>?) ?? const {};
    return ChatConversation(
      id: id,
      isGroup: map['isGroup'] as bool? ?? false,
      title: map['title'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      participantIds: (map['participantIds'] as List<dynamic>? ?? const [])
          .cast<String>(),
      lastMessageText: map['lastMessageText'] as String? ?? '',
      lastMessageAt: _readDate(map['lastMessageAt']),
      lastSenderId: map['lastSenderId'] as String?,
      createdAt: _readDate(map['createdAt']),
      unreadCountByUser: unreadMap.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      typingUserIds: (map['typingUserIds'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
