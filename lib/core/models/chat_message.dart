import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, image, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.sentAt,
    required this.updatedAt,
    required this.seenBy,
    required this.attachmentUrl,
    required this.replyToMessageId,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final ChatMessageType type;
  final DateTime sentAt;
  final DateTime? updatedAt;
  final List<String> seenBy;
  final String? attachmentUrl;
  final String? replyToMessageId;

  bool isSentBy(String userId) => senderId == userId;

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    ChatMessageType? type,
    DateTime? sentAt,
    DateTime? updatedAt,
    List<String>? seenBy,
    String? attachmentUrl,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seenBy: seenBy ?? this.seenBy,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'seenBy': seenBy,
      'attachmentUrl': attachmentUrl,
      'replyToMessageId': replyToMessageId,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ChatMessageType.text,
      ),
      sentAt: _readDate(map['sentAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']),
      seenBy: (map['seenBy'] as List<dynamic>? ?? const []).cast<String>(),
      attachmentUrl: map['attachmentUrl'] as String?,
      replyToMessageId: map['replyToMessageId'] as String?,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
