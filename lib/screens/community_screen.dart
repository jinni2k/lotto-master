import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/community_service.dart';
import 'post_detail_screen.dart';
import 'write_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  static const List<String> _categories = [
    '자유게시판',
    '꿈 공유',
    '번호 공유',
    '당첨 후기',
  ];

  late TabController _tabController;
  final CommunityService _community = CommunityService.instance;
  final TextEditingController _chatController = TextEditingController();

  bool get _isChatTab => _tabController.index == _categories.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _openWriteScreen() {
    final category = _isChatTab ? _categories.first : _categories[_tabController.index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(initialCategory: category),
      ),
    );
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) {
      return;
    }
    _chatController.clear();
    await _community.sendChatMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final category in _categories) Tab(text: category),
            const Tab(text: '실시간 채팅'),
          ],
        ),
      ),
      floatingActionButton: _isChatTab
          ? null
          : FloatingActionButton.extended(
              onPressed: _openWriteScreen,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('글쓰기'),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final category in _categories) _PostList(category: category),
          _LiveChatRoom(
            community: _community,
            controller: _chatController,
            onSend: _sendChatMessage,
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final community = CommunityService.instance;
    return StreamBuilder<List<Post>>(
      stream: community.streamPosts(category: category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              '아직 글이 없어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PostCard(post: post),
            );
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final excerpt = post.content.length > 80 ? '${post.content.substring(0, 80)}...' : post.content;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              excerpt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  post.authorName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                const Icon(Icons.favorite_border, size: 16, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  post.likeCount.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  post.commentCount.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveChatRoom extends StatelessWidget {
  const _LiveChatRoom({
    required this.community,
    required this.controller,
    required this.onSend,
  });

  final CommunityService community;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: community.streamChatMessages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    '추첨 시간에 함께 이야기 나눠보세요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.authorName,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: '응원 메시지를 남겨보세요',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
