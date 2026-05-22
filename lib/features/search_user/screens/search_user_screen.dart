import 'package:chatapp/core/theme/app_colors.dart';
import 'package:chatapp/core/widgets/gradient_button.dart';
import 'package:chatapp/core/widgets/shimmer_box.dart';
import 'package:chatapp/core/widgets/user_avatar.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:chatapp/features/chat/screens/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchUserScreen extends ConsumerStatefulWidget {
  const SearchUserScreen({super.key});

  @override
  ConsumerState<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends ConsumerState<SearchUserScreen> {
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController(text: 'New group');
  final Set<String> _selectedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final query = _searchController.text.trim();
    final resultsAsync = ref.watch(userSearchProvider(query));
    final selectedCount = _selectedIds.length;
    final actionLabel = selectedCount == 0
        ? 'Select people to chat'
        : selectedCount == 1
        ? 'Start direct chat'
        : 'Create group chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find people'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    setState(_selectedIds.clear);
                  },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search users',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Group name',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Text(
                      '${_selectedIds.length} selected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Build a group chat',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: resultsAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const _NoResults();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: users.length + 1,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == users.length) {
                        return const SizedBox(height: 100);
                      }
                      final user = users[index];
                      final isSelected = _selectedIds.contains(user.uid);
                      final disabled = user.uid == currentUserId;

                      return AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: isSelected ? 1.01 : 1,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: disabled
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedIds.remove(user.uid);
                                      } else {
                                        _selectedIds.add(user.uid);
                                      }
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    user: user,
                                    radius: 22,
                                    showOnlineDot: user.isOnline,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName.isEmpty
                                              ? 'Unknown user'
                                              : user.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.isOnline ? 'online' : 'offline',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      opacity: isSelected ? 1 : 0,
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: 6,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => const _SearchSkeleton(),
                ),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GradientButton(
                label: actionLabel,
                onPressed: selectedCount == 0
                    ? null
                    : () async {
                        if (currentUserId == null) return;
                        final navigator = Navigator.of(context);
                        final repository = ref.read(chatRepositoryProvider);
                        final chatId = selectedCount == 1
                            ? await repository.createDirectChat(
                                currentUserId: currentUserId,
                                otherUserId: _selectedIds.first,
                              )
                            : await repository.createGroupChat(
                                groupName:
                                    _groupNameController.text.trim().isEmpty
                                    ? 'New group'
                                    : _groupNameController.text,
                                ownerId: currentUserId,
                                participantIds: _selectedIds.toList(),
                              );
                        if (!mounted) return;
                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(chatId: chatId),
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

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
            ),
            child: const Icon(
              Icons.manage_search_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text('No matches yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Try a different name or keep building your group.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            ShimmerBox(height: 44, width: 44, borderRadius: 22),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 14, width: 120),
                  SizedBox(height: 8),
                  ShimmerBox(height: 12, width: 84),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
