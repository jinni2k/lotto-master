import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
}

class CommunityService {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _posts => _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _chat => _firestore.collection('live_chat');

  Future<User> _ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  String _displayName(User user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    return '익명#${user.uid.substring(0, 4)}';
  }

  Stream<List<Post>> streamPosts({String? category}) {
    Query<Map<String, dynamic>> query = _posts.orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(Post.fromFirestore).toList(growable: false),
        );
  }

  Stream<Post?> streamPost(String postId) {
    return _posts.doc(postId).snapshots().map(
          (snapshot) => snapshot.exists ? Post.fromFirestore(snapshot) : null,
        );
  }

  Future<void> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final user = await _ensureSignedIn();
    final now = DateTime.now();
    await _posts.add({
      'title': title,
      'content': content,
      'category': category,
      'authorId': user.uid,
      'authorName': _displayName(user),
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': now.toIso8601String(),
    });
  }

  Future<void> toggleLike(String postId) async {
    final user = await _ensureSignedIn();
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final postSnapshot = await transaction.get(postRef);
      final currentLikes = postSnapshot.data()?['likeCount'] as int? ?? 0;

      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': currentLikes > 0 ? currentLikes - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(likeRef, {
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likeCount': currentLikes + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addComment(String postId, String content) async {
    final user = await _ensureSignedIn();
    final postRef = _posts.doc(postId);
    await postRef.collection('comments').add({
      'authorId': user.uid,
      'authorName': _displayName(user),
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PostComment>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) => PostComment(
                id: doc.id,
                authorId: doc['authorId'] as String? ?? '',
                authorName: doc['authorName'] as String? ?? '익명',
                content: doc['content'] as String? ?? '',
                createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ),
            )
            .toList(growable: false);
      },
    );
  }

  Future<void> reportPost(String postId, String reason) async {
    final user = await _ensureSignedIn();
    await _posts.doc(postId).collection('reports').add({
      'authorId': user.uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatMessage>> streamChatMessages() {
    return _chat.orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ChatMessage(
                  id: doc.id,
                  authorName: doc['authorName'] as String? ?? '익명',
                  message: doc['message'] as String? ?? '',
                  createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> sendChatMessage(String message) async {
    final user = await _ensureSignedIn();
    await _chat.add({
      'authorId': user.uid,
      'authorName': _displayName(user),
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
