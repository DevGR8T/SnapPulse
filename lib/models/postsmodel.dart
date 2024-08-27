import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  late final String username;
  late final String userProfileImageUrl;
  final String caption;
  final String imageUrl;
  final DateTime timestamp;
  final int likes;
  int commentCount;
  bool isFollowing;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImageUrl,
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
    this.likes = 0,
    this.commentCount = 0, //Initialize with 0 comments
    this.isFollowing = false,
  });

  void updateUsername(String newUsername) {
    username = newUsername;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'caption': caption,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'commentCount': commentCount,
      'isFollowing': isFollowing,
    };
  }

  factory Post.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    print('Document data: $data'); // Log the document data

    return Post(
      id: snapshot.id,
      userId: data['userId'] ?? 'unknown',
      username: data['username'] ?? 'unknown',
      userProfileImageUrl: data['userProfileImageUrl'] ?? '',
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isFollowing: data['isFollowing'] ?? false,
    );
  }
}
