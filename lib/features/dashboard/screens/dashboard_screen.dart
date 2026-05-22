import 'package:chatapp/core/models/chat_conversation.dart';
import 'package:chatapp/core/models/chat_user.dart';
import 'package:chatapp/core/theme/app_colors.dart';
import 'package:chatapp/core/utils/relative_time.dart';
import 'package:chatapp/core/widgets/shimmer_box.dart';
import 'package:chatapp/core/widgets/user_avatar.dart';
import 'package:chatapp/features/auth/controllers/auth_controller.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:chatapp/features/chat/screens/chat_room_screen.dart';
import 'package:chatapp/features/search_user/screens/search_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSearchQueryProvider = StateProvider<String>((ref) => '');

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final uid = authUser?.uid;
    final query = ref.watch(dashboardSearchQueryProvider);

    if (uid == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final profileAsync = ref.watch(currentUserProfileProvider(uid));
    final chatsAsync = ref.watch(chatsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    profileAsync.when(
                      data: (profile) => _ProfilePill(profile: profile),
                      loading: () => const _ProfileSkeleton(),
                      error: (error, stackTrace) => const _ProfileSkeleton(),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchUserScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.person_search_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-time conversations with soft depth and sharp hierarchy.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          ref
                                  .read(dashboardSearchQueryProvider.notifier)
                                  .state =
                              value,
                      decoration: const InputDecoration(
                        hintText: 'Search chats',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            chatsAsync.when(
              data: (chats) {
                final filteredChats = _filterChats(chats, query);
                if (filteredChats.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyInbox(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chat = filteredChats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChatTile(
                          chat: chat,
                          currentUserId: uid,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(chatId: chat.id),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: filteredChats.length),
                  ),
                );
              },
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _InboxShimmer()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChatConversation> _filterChats(
    List<ChatConversation> chats,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return chats;
    return chats.where((chat) {
      return chat.title.toLowerCase().contains(normalized) ||
          chat.lastMessageText.toLowerCase().contains(normalized);
    }).toList();
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.profile});

  final ChatUser? profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(user: profile, radius: 24, showOnlineDot: true),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.displayName.isNotEmpty == true
                  ? profile!.displayName
                  : 'Your inbox',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              profile?.isOnline == true ? 'Online now' : 'Ready to chat',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(height: 48, width: 48, borderRadius: 24),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 16, width: 112),
            SizedBox(height: 8),
            ShimmerBox(height: 12, width: 90),
          ],
        ),
      ],
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  final ChatConversation chat;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(chatParticipantsProvider(chat.id));
    final unreadCount = chat.unreadCountFor(currentUserId);

    return participantsAsync.when(
      data: (participants) {
        final previewUser = _previewUser(chat, participants, currentUserId);
        final subtitle = chat.lastMessageText.isEmpty
            ? 'No messages yet'
            : chat.lastMessageText;
        final timestamp = chat.lastMessageAt == null
            ? ''
            : formatRelativeTime(chat.lastMessageAt!);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(user: previewUser, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.isGroup
                                    ? (chat.title.isEmpty
                                          ? 'Group chat'
                                          : chat.title)
                                    : previewUser.displayName.isEmpty
                                    ? 'Direct chat'
                                    : previewUser.displayName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timestamp.isNotEmpty)
                              Text(
                                timestamp,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: unreadCount > 0 ? 1 : 0.9,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: unreadCount > 0 ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.indigoViolet,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _ChatTileSkeleton(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  ChatUser _previewUser(
    ChatConversation chat,
    List<ChatUser> participants,
    String currentUserId,
  ) {
    if (chat.isGroup) {
      return ChatUser(
        uid: chat.id,
        email: '',
        displayName: chat.title.isEmpty ? 'Group' : chat.title,
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

    final otherUser = participants.firstWhere(
      (user) => user.uid != currentUserId,
      orElse: () => ChatUser(
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
      ),
    );
    return otherUser;
  }
}

class _ChatTileSkeleton extends StatelessWidget {
  const _ChatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            ShimmerBox(height: 48, width: 48, borderRadius: 24),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 16, width: 140),
                  SizedBox(height: 8),
                  ShimmerBox(height: 12, width: 220),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxShimmer extends StatelessWidget {
  const _InboxShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _ChatTileSkeleton(),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

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
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your inbox is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation or create a group.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
