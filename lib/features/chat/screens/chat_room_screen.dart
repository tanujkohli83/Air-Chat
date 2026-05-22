import 'dart:async';

import 'package:chatapp/core/models/chat_message.dart';
import 'package:chatapp/core/models/chat_conversation.dart';
import 'package:chatapp/core/models/chat_user.dart';
import 'package:chatapp/core/theme/app_colors.dart';
import 'package:chatapp/core/utils/relative_time.dart';
import 'package:chatapp/core/widgets/message_bubble.dart';
import 'package:chatapp/core/widgets/shimmer_box.dart';
import 'package:chatapp/core/widgets/typing_indicator.dart';
import 'package:chatapp/core/widgets/user_avatar.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({
    required String chatId,
    required ChatConversation chat,
    required String currentUserId,
  }) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await ref
        .read(chatRepositoryProvider)
        .sendTextMessage(
          chatId: chatId,
          senderId: currentUserId,
          participantIds: chat.participantIds,
          text: text,
          isGroup: chat.isGroup,
        );

    _textController.clear();
    await ref
        .read(chatRepositoryProvider)
        .setTyping(chatId: chatId, userId: currentUserId, isTyping: false);
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _setTyping(String chatId, String currentUserId, String value) {
    _typingTimer?.cancel();
    final isTyping = value.trim().isNotEmpty;
    ref
        .read(chatRepositoryProvider)
        .setTyping(chatId: chatId, userId: currentUserId, isTyping: isTyping);
    _typingTimer = Timer(const Duration(milliseconds: 900), () {
      ref
          .read(chatRepositoryProvider)
          .setTyping(chatId: chatId, userId: currentUserId, isTyping: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final chatAsync = ref.watch(chatConversationProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final participantsAsync = ref.watch(
      chatParticipantsProvider(widget.chatId),
    );
    final typingAsync = ref.watch(chatTypingProvider(widget.chatId));

    final chat = chatAsync.value;
    final messages = messagesAsync.value ?? const <ChatMessage>[];

    if (chat != null &&
        currentUserId != null &&
        _lastMessageCount != messages.length) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(chatRepositoryProvider)
            .markConversationRead(chatId: widget.chatId, userId: currentUserId);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }

    final typingUsers = typingAsync.value ?? const <String>{};

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              chatAsync: chatAsync,
              participantsAsync: participantsAsync,
              currentUserId: currentUserId,
              typingUsers: typingUsers,
            ),
            Expanded(
              child: chatAsync.when(
                data: (chatValue) {
                  if (chatValue == null) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  return messagesAsync.when(
                    data: (loadedMessages) {
                      if (loadedMessages.isEmpty) {
                        return const _EmptyConversation();
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: loadedMessages.length,
                        itemBuilder: (context, index) {
                          final message = loadedMessages[index];
                          final isMine = message.senderId == currentUserId;
                          final olderMessage = index + 1 < loadedMessages.length
                              ? loadedMessages[index + 1]
                              : null;
                          final isStacked =
                              olderMessage != null &&
                              olderMessage.senderId == message.senderId &&
                              message.sentAt
                                      .difference(olderMessage.sentAt)
                                      .inMinutes <
                                  4;

                          return MessageBubble(
                            message: message,
                            isMine: isMine,
                            isStacked: isStacked,
                            timeLabel: formatRelativeTime(message.sentAt),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, _) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (typingUsers.isNotEmpty && chat != null && currentUserId != null)
              _TypingRow(
                typingUsers: typingUsers,
                currentUserId: currentUserId,
              ),
            _ComposerBar(
              controller: _textController,
              onChanged: (value) {
                if (chat != null && currentUserId != null) {
                  _setTyping(widget.chatId, currentUserId, value);
                }
              },
              onSend: chat == null || currentUserId == null
                  ? null
                  : () => _sendMessage(
                      chatId: widget.chatId,
                      chat: chat,
                      currentUserId: currentUserId,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.chatAsync,
    required this.participantsAsync,
    required this.currentUserId,
    required this.typingUsers,
  });

  final AsyncValue<ChatConversation?> chatAsync;
  final AsyncValue<List<ChatUser>> participantsAsync;
  final String? currentUserId;
  final Set<String> typingUsers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: const Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          participantsAsync.when(
            data: (participants) {
              final chat = chatAsync.value;
              final previewUser = _previewUser(
                chat,
                participants,
                currentUserId,
              );
              final subtitle = _statusText(
                chat,
                participants,
                typingUsers,
                currentUserId,
              );
              return Row(
                children: [
                  UserAvatar(
                    user: previewUser,
                    radius: 22,
                    showOnlineDot: previewUser.isOnline,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat?.isGroup == true
                            ? (chat!.title.isEmpty ? 'Group chat' : chat.title)
                            : previewUser.displayName.isEmpty
                            ? 'Conversation'
                            : previewUser.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          subtitle,
                          key: ValueKey<String>(subtitle),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const _HeaderSkeleton(),
            error: (error, stackTrace) => const _HeaderSkeleton(),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  ChatUser _previewUser(
    ChatConversation? chat,
    List<ChatUser> participants,
    String? currentUserId,
  ) {
    if (chat == null) {
      return const ChatUser(
        uid: '',
        email: '',
        displayName: '',
        photoUrl: null,
        photoBase64: null,
        photoMimeType: null,
        isOnline: false,
        createdAt: null,
        lastSeen: null,
        displayNameLower: '',
        fcmToken: null,
      );
    }
    if (chat.isGroup) {
      return ChatUser(
        uid: chat.id,
        email: '',
        displayName: chat.title,
        photoUrl: chat.photoUrl,
        photoBase64: null,
        photoMimeType: null,
        isOnline: false,
        createdAt: chat.createdAt,
        lastSeen: chat.lastMessageAt,
        displayNameLower: chat.title.toLowerCase(),
        fcmToken: null,
      );
    }

    final peer = participants
        .where((user) => user.uid != currentUserId)
        .toList();
    if (peer.isNotEmpty) {
      return peer.first;
    }

    return ChatUser(
      uid: chat.id,
      email: '',
      displayName: 'Chat',
      photoUrl: null,
      photoBase64: null,
      photoMimeType: null,
      isOnline: false,
      createdAt: chat.createdAt,
      lastSeen: chat.lastMessageAt,
      displayNameLower: 'chat',
      fcmToken: null,
    );
  }

  String _statusText(
    ChatConversation? chat,
    List<ChatUser> participants,
    Set<String> typingUsers,
    String? currentUserId,
  ) {
    if (typingUsers.isNotEmpty) return 'typing...';
    if (chat?.isGroup == true) {
      return '${chat!.participantIds.length} members';
    }
    final peers = participants
        .where((user) => user.uid != currentUserId)
        .toList();
    final peer = peers.isNotEmpty ? peers.first : null;
    if (peer == null) return 'Active chat';
    return peer.isOnline ? 'online now' : 'last seen recently';
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(height: 44, width: 44, borderRadius: 22),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 16, width: 120),
            SizedBox(height: 8),
            ShimmerBox(height: 12, width: 88),
          ],
        ),
      ],
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.typingUsers, required this.currentUserId});

  final Set<String> typingUsers;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final count = typingUsers.where((id) => id != currentUserId).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TypingIndicator(color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                count <= 1 ? 'Typing...' : '$count people typing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppGradients.indigoViolet,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.34),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.indigoViolet,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hello',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Messages appear here in a slick, reverse-scrolled stream.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
