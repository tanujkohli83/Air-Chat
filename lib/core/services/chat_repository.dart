import 'package:chatapp/core/models/chat_conversation.dart';
import 'package:chatapp/core/models/chat_message.dart';
import 'package:chatapp/core/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  ChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<ChatConversation>> watchChats(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatConversation.fromMap(doc.id, doc.data()))
              .toList();
          chats.sort((a, b) {
            final aTime = a.lastMessageAt;
            final bTime = b.lastMessageAt;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return chats;
        });
  }

  Stream<ChatConversation?> watchChat(String chatId) {
    return _chats
        .doc(chatId)
        .snapshots()
        .map(
          (snapshot) => snapshot.data() == null
              ? null
              : ChatConversation.fromMap(snapshot.id, snapshot.data()!),
        );
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<Set<String>> watchTypingUserIds(String chatId) {
    return watchChat(
      chatId,
    ).map((chat) => chat?.typingUserIds.toSet() ?? <String>{});
  }

  Stream<List<ChatUser>> searchUsers(String query, {String? excludeUserId}) {
    final normalized = query.trim().toLowerCase();
    Query<Map<String, dynamic>> base = _users.orderBy('displayNameLower');

    if (normalized.isNotEmpty) {
      base = base.startAt([normalized]).endAt(['$normalized\uf8ff']);
    } else {
      base = base.limit(20);
    }

    return base.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ChatUser.fromMap(doc.data()))
          .where((user) => user.uid != excludeUserId)
          .toList(),
    );
  }

  Stream<List<ChatUser>> watchUsersByIds(List<String> userIds) {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return Stream.value(const <ChatUser>[]);
    }

    final queryIds = ids.take(30).toList();
    return _users
        .where(FieldPath.documentId, whereIn: queryIds)
        .snapshots()
        .map((snapshot) {
          final usersById = {
            for (final doc in snapshot.docs)
              doc.id: ChatUser.fromMap(doc.data()),
          };
          return [
            for (final id in queryIds)
              if (usersById[id] != null) usersById[id]!,
          ];
        });
  }

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _chats.doc(chatId).set({
      'typingUserIds': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    }, SetOptions(merge: true));
  }

  Future<void> markConversationRead({
    required String chatId,
    required String userId,
  }) async {
    await _chats.doc(chatId).set({
      'unreadCountByUser.$userId': 0,
    }, SetOptions(merge: true));
  }

  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required List<String> participantIds,
    required String text,
    required bool isGroup,
  }) async {
    final messageRef = _chats.doc(chatId).collection('messages').doc();
    final now = Timestamp.now();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'chatId': chatId,
      'senderId': senderId,
      'text': text.trim(),
      'type': ChatMessageType.text.name,
      'sentAt': now,
      'updatedAt': now,
      'seenBy': [senderId],
      'attachmentUrl': null,
      'replyToMessageId': null,
    });

    final unreadUpdates = <String, dynamic>{};
    for (final participantId in participantIds) {
      if (participantId == senderId) {
        unreadUpdates['unreadCountByUser.$participantId'] = 0;
      } else {
        unreadUpdates['unreadCountByUser.$participantId'] =
            FieldValue.increment(1);
      }
    }

    batch.set(_chats.doc(chatId), {
      'isGroup': isGroup,
      'lastMessageText': text.trim(),
      'lastMessageAt': now,
      'lastSenderId': senderId,
      'participantIds': participantIds,
      ...unreadUpdates,
    }, SetOptions(merge: true));

    await batch.commit();
    return messageRef.id;
  }

  Future<String> createDirectChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final participantIds = [currentUserId, otherUserId]..sort();
    final chatId = participantIds.join('_');
    final ref = _chats.doc(chatId);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      return chatId;
    }

    await ref.set({
      'isGroup': false,
      'title': '',
      'photoUrl': null,
      'participantIds': participantIds,
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'typingUserIds': <String>[],
      'unreadCountByUser': {
        for (final participantId in participantIds) participantId: 0,
      },
    });
    return chatId;
  }

  Future<String> createGroupChat({
    required String groupName,
    required String ownerId,
    required List<String> participantIds,
  }) async {
    final uniqueParticipants = {...participantIds, ownerId}.toList();
    final ref = _chats.doc();
    await ref.set({
      'isGroup': true,
      'title': groupName.trim(),
      'photoUrl': null,
      'participantIds': uniqueParticipants,
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'typingUserIds': <String>[],
      'unreadCountByUser': {
        for (final participantId in uniqueParticipants) participantId: 0,
      },
    });
    return ref.id;
  }
}
