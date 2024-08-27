import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snap_pulse/models/commentmodel.dart';
import 'package:snap_pulse/models/postsmodel.dart';

class FirestoreServices {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');

  // Adds a new post to the Firestore 'posts' collection
  Future<void> addPosts(Post post) async {
    try {
      await _postsCollection.add(post.toMap());
      print('Post added to Firestore successfully');
    } catch (e) {
      print('Error adding post to Firestore: $e');
    }
  }

  // Retrieves a stream of posts, ordered by timestamp descending
  Stream<List<Post>> getPosts() {
    return _postsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromSnapshot(doc)).toList();
    });
  }

  // Updates an existing post in Firestore
  Future<void> updatePost(Post post) async {
    try {
      await _postsCollection.doc(post.id).update(post.toMap());
      print('Post updated successfully');
    } catch (e) {
      print('Error updating post: $e');
    }
  }

  // Deletes a post from Firestore by its ID
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
      print('Post deleted successfully');
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  final CollectionReference _commentsCollection =
      FirebaseFirestore.instance.collection('comments');

  // Adds a new comment to the Firestore 'comments' collection
  Future<void> addComment(Comment comment) async {
    await FirebaseFirestore.instance.collection('comments').add({
      'postId': comment.postId,
      'userId': comment.userId,
      'username': comment.username,
      'userProfileImageUrl': comment.userProfileImageUrl,
      'text': comment.text,
      'timestamp': comment.timestamp,
      'likes': comment.likes,
      'parentCommentId': null,
    });
  }

  // Retrieves a stream of comments for a specific post
  Stream<List<Comment>> getCommentsForPost(String postId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Retrieves a stream of top-level comments for a specific post
  Stream<List<Comment>> getTopLevelCommentsForPost(String postId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Updates an existing comment in Firestore
  Future<void> updateComment(Comment comment) async {
    try {
      await _commentsCollection.doc(comment.id).update(comment.toMap());
      print('Comment updated successfully');
    } catch (e) {
      print('Error updating comment: $e');
    }
  }

  // Deletes a comment from Firestore by its ID
  Future<void> deleteComment(String commentId) async {
    try {
      await _commentsCollection.doc(commentId).delete();
      print('Comment deleted successfully');
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  // Updates the username in all posts for a specific user
  Future<void> updateUsernameInPosts(String userId, String newUsername) async {
    try {
      QuerySnapshot userPostsSnapshot = await firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = firestore.batch();

      for (var doc in userPostsSnapshot.docs) {
        batch.update(doc.reference, {'username': newUsername});
      }

      await batch.commit();
      print('Username updated in all posts');
    } catch (e) {
      print('Error updating username in posts: $e');
    }
  }

  // Updates the username in all comments for a specific user
  Future<void> updateUsernameInComments(
      String userId, String newUsername) async {
    try {
      QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = firestore.batch();

      for (var doc in commentsSnapshot.docs) {
        batch.update(doc.reference, {'username': newUsername});
      }

      await batch.commit();
      print('Username updated in all comments');
    } catch (e) {
      print('Error updating username in comments: $e');
    }
  }

  // Adds a reply to an existing comment
  Future<void> addReply(Comment reply, String parentCommentId) async {
    await FirebaseFirestore.instance.collection('comments').add({
      'postId': reply.postId,
      'userId': reply.userId,
      'username': reply.username,
      'userProfileImageUrl': reply.userProfileImageUrl,
      'text': reply.text,
      'timestamp': reply.timestamp,
      'likes': reply.likes,
      'parentCommentId': parentCommentId,
    });
  }

  // Retrieves a stream of replies for a specific comment
  Stream<List<Comment>> getRepliesForComment(String commentId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Gets the count of direct replies to a specific comment
  Future<int> getReplyCountForComment(String commentId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .get();
    return querySnapshot.docs.length;
  }



  // Retrieves a stream of nested comments for a specific post
  Stream<List<Comment>> getNestedCommentsForPost(String postId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Comment> comments = [];
      for (var doc in snapshot.docs) {
        Comment comment = Comment.fromMap(doc.data(), doc.id);
        comment.replies = await getNestedReplies(comment.id);
        comments.add(comment);
      }
      return comments;
    });
  }

  // Recursively retrieves nested replies for a comment
  Future<List<Comment>> getNestedReplies(String parentCommentId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('timestamp', descending: false)
        .get();

    List<Comment> replies = [];
    for (var doc in snapshot.docs) {
      Comment reply =
          Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      reply.replies = await getNestedReplies(reply.id);
      replies.add(reply);
    }

    return replies;
  }

  // Retrieves all replies for a comment, including nested replies
  Future<List<Comment>> getAllRepliesForComment(String commentId) async {
    List<Comment> allReplies = [];

    Future<void> fetchReplies(String parentId) async {
      QuerySnapshot replySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentId)
          .orderBy('timestamp', descending: false)
          .get();

      for (var doc in replySnapshot.docs) {
        Comment reply =
            Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        allReplies.add(reply);
        await fetchReplies(reply.id); // Recursively fetch nested replies
      }
    }

    await fetchReplies(commentId);
    return allReplies;
  }

  // Gets the total count of all replies to a comment, including nested replies
  Future<int> getTotalReplyCountForComment(String commentId) async {
    int totalCount = 0;

    // Function to recursively count replies
    Future<void> countReplies(String parentId) async {
      QuerySnapshot repliesSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentId)
          .get();

      totalCount += repliesSnapshot.docs.length;

      // Recursively count replies for each reply
      for (var doc in repliesSnapshot.docs) {
        await countReplies(doc.id);
      }
    }

    await countReplies(commentId);
    return totalCount;
  }

  // Check if the current user is the author of the post
  Future<bool> isCurrentUserAuthor(String postId, String currentUserId) async {
    DocumentSnapshot postDoc = await _postsCollection.doc(postId).get();
    return postDoc.exists && postDoc['userId'] == currentUserId;
  }

  
  // Method to follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  // Method to unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .delete();
  }

  // Method to check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    DocumentSnapshot followerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .get();
    return followerDoc.exists;
  }

  // Method to get a stream of follower count
  Stream<int> getFollowerCount(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Method to toggle follow status
  
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    bool isCurrentlyFollowing = await isFollowing(currentUserId, targetUserId);
    
    if (isCurrentlyFollowing) {
      // Unfollow
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();
    } else {
      // Follow
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({'timestamp': FieldValue.serverTimestamp()});
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    }
  }

  // Method to get a stream of following count
  Stream<int> getFollowingCount(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
