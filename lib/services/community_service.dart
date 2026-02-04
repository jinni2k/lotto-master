import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  Database? _db;
  final _postsController = StreamController<List<Post>>.broadcast();
  final _chatController = StreamController<List<ChatMessage>>.broadcast();
  String _currentUserId = 'local_user';
  String _currentUserName = '로또마스터';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'community.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            authorId TEXT NOT NULL,
            authorName TEXT NOT NULL,
            likeCount INTEGER DEFAULT 0,
            commentCount INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE comments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            postId INTEGER NOT NULL,
            authorId TEXT NOT NULL,
            authorName TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            authorName TEXT NOT NULL,
            message TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Stream<List<Post>> streamPosts({String? category}) {
    _loadPosts(category: category);
    return _postsController.stream;
  }

  Future<void> _loadPosts({String? category}) async {
    final db = await database;
    String query = 'SELECT * FROM posts ORDER BY createdAt DESC';
    List<dynamic> args = [];
    
    if (category != null && category.isNotEmpty) {
      query = 'SELECT * FROM posts WHERE category = ? ORDER BY createdAt DESC';
      args = [category];
    }
    
    final maps = await db.rawQuery(query, args);
    final posts = maps.map((map) => Post(
      id: map['id'].toString(),
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      likeCount: map['likeCount'] as int,
      commentCount: map['commentCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    )).toList();
    
    _postsController.add(posts);
  }

  Stream<Post?> streamPost(String postId) {
    return streamPosts().map((posts) => 
      posts.where((p) => p.id == postId).firstOrNull
    );
  }

  Future<void> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final db = await database;
    await db.insert('posts', {
      'title': title,
      'content': content,
      'category': category,
      'authorId': _currentUserId,
      'authorName': _currentUserName,
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _loadPosts();
  }

  Future<void> toggleLike(String postId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE posts SET likeCount = likeCount + 1 WHERE id = ?',
      [int.parse(postId)],
    );
    _loadPosts();
  }

  Future<void> addComment(String postId, String content) async {
    final db = await database;
    await db.insert('comments', {
      'postId': int.parse(postId),
      'authorId': _currentUserId,
      'authorName': _currentUserName,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await db.rawUpdate(
      'UPDATE posts SET commentCount = commentCount + 1 WHERE id = ?',
      [int.parse(postId)],
    );
    _loadPosts();
  }

  Stream<List<PostComment>> streamComments(String postId) {
    final controller = StreamController<List<PostComment>>();
    _loadComments(postId, controller);
    return controller.stream;
  }

  Future<void> _loadComments(String postId, StreamController<List<PostComment>> controller) async {
    final db = await database;
    final maps = await db.query(
      'comments',
      where: 'postId = ?',
      whereArgs: [int.parse(postId)],
      orderBy: 'createdAt',
    );
    final comments = maps.map((map) => PostComment(
      id: map['id'].toString(),
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    )).toList();
    controller.add(comments);
  }

  Future<void> reportPost(String postId, String reason) async {
    // 로컬에서는 리포트 기능 생략
  }

  Stream<List<ChatMessage>> streamChatMessages() {
    _loadChatMessages();
    return _chatController.stream;
  }

  Future<void> _loadChatMessages() async {
    final db = await database;
    final maps = await db.query('chat_messages', orderBy: 'createdAt');
    final messages = maps.map((map) => ChatMessage(
      id: map['id'].toString(),
      authorName: map['authorName'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    )).toList();
    _chatController.add(messages);
  }

  Future<void> sendChatMessage(String message) async {
    final db = await database;
    await db.insert('chat_messages', {
      'authorName': _currentUserName,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _loadChatMessages();
  }
}
