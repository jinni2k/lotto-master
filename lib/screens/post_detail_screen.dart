import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/community_service.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _community = CommunityService.instance;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    await _community.toggleLike(widget.postId);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      _commentController.clear();
      await _community.addComment(widget.postId, text);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _reportPost() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고 사유'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '신고 사유를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('신고'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) {
      return;
    }
    await _community.reportPost(widget.postId, reason);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          IconButton(
            onPressed: _reportPost,
            icon: const Icon(Icons.report_gmailerrorred_rounded),
            tooltip: '신고',
          ),
        ],
      ),
      body: StreamBuilder<Post?>(
        stream: _community.streamPost(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snapshot.data;
          if (post == null) {
            return Center(
              child: Text(
                '게시글을 찾을 수 없어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      post.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleLike,
                          icon: const Icon(Icons.favorite_border),
                          label: Text('좋아요 ${post.likeCount}'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '댓글 ${post.commentCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '댓글',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _CommentList(postId: widget.postId),
                  ],
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
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _submitting ? null : _submitComment,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentList extends StatelessWidget {
  const _CommentList({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final community = CommunityService.instance;
    return StreamBuilder<List<PostComment>>(
      stream: community.streamComments(postId),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '첫 댓글을 남겨보세요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          );
        }
        return Column(
          children: comments
              .map(
                (comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                          comment.authorName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.content,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
