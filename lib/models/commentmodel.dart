import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  late final String username;
  late final String userProfileImageUrl;
  final String text;
  final DateTime timestamp;
  final int likes;
  final String? parentCommentId;
  List<Comment> replies = []; //to store nested replies

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.parentCommentId,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  void updateUsername(String newUsername) {
    username = newUsername;
  }

  factory Comment.fromMap(Map<String, dynamic> map, String documentId) {
    return Comment(
      id: documentId,
      postId: map['postId'] as String,
      userId: map['userId'] as String,
      username: map['username'] as String,
      userProfileImageUrl: map['userProfileImageUrl'] as String,
      text: map['text'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      likes: map['likes'] as int,
      parentCommentId: map['parentCommentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'parentCommentId': parentCommentId,
    };
  }
}
