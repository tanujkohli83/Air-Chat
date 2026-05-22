import 'package:chatapp/core/models/chat_conversation.dart';
import 'package:chatapp/core/models/chat_message.dart';
import 'package:chatapp/core/models/chat_user.dart';
import 'package:chatapp/core/services/auth_repository.dart';
import 'package:chatapp/core/services/chat_repository.dart';
import 'package:chatapp/core/services/profile_repository.dart';
import 'package:chatapp/core/services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(firestoreProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseMessagingProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

final currentUserProfileProvider = StreamProvider.autoDispose
    .family<ChatUser?, String>((ref, uid) {
      return ref.watch(authRepositoryProvider).watchUser(uid);
    });

final chatsProvider = StreamProvider.autoDispose
    .family<List<ChatConversation>, String>((ref, userId) {
      // Firestore snapshots are mapped here into immutable Dart models so Riverpod can
      // rebuild only the widgets that depend on the latest chat list.
      return ref.watch(chatRepositoryProvider).watchChats(userId);
    });

final chatConversationProvider = StreamProvider.autoDispose
    .family<ChatConversation?, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchChat(chatId);
    });

final chatParticipantsProvider = StreamProvider.autoDispose
    .family<List<ChatUser>, String>((ref, chatId) {
      final chat = ref.watch(chatConversationProvider(chatId)).value;
      if (chat == null) {
        return Stream.value(const <ChatUser>[]);
      }
      return ref
          .watch(chatRepositoryProvider)
          .watchUsersByIds(chat.participantIds);
    });

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchMessages(chatId);
    });

final chatTypingProvider = StreamProvider.autoDispose
    .family<Set<String>, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchTypingUserIds(chatId);
    });

final userSearchProvider = StreamProvider.autoDispose
    .family<List<ChatUser>, String>((ref, query) {
      return ref
          .watch(chatRepositoryProvider)
          .searchUsers(query, excludeUserId: ref.watch(currentUserIdProvider));
    });

enum AuthFormMode { signIn, signUp }

final authFormModeProvider = StateProvider<AuthFormMode>(
  (ref) => AuthFormMode.signIn,
);
