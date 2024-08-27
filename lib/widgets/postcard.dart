import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snap_pulse/models/postsmodel.dart';
import 'package:snap_pulse/services/firestoreservices.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({required this.post, Key? key}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Post _post;
  bool _isMounted = false;
  bool isLiked = false;
  int likeCount = 0;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late StreamSubscription<DocumentSnapshot> _postSubscription;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    likeCount = widget.post.likes;
    _post = widget.post;
    _fetchLikeStatus();
    _listenToPostUpdates();
  }

  // Safe setState to avoid calling setState after dispose
  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  // Listen for updates to the post document
  void _listenToPostUpdates() {
    _postSubscription = FirebaseFirestore.instance
        .collection('posts')
        .doc(_post.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedPost = Post.fromSnapshot(snapshot);
        if (mounted) {
          setState(() {
            _post = updatedPost;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _postSubscription.cancel();
    super.dispose();
  }

  // Fetch the like status for the current user on this post
  void _fetchLikeStatus() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .collection('likes')
        .doc(currentUserId)
        .get()
        .then((docSnapshot) {
      _safeSetState(() {
        isLiked = docSnapshot.exists;
      });
    }).catchError((error) {
      print('Failed to fetch like status: $error');
    });
  }

  // Toggle the like status for the current user on this post
  void _toggleLike() {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    final likeRef = postRef.collection('likes').doc(currentUserId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        // Unlike the post
        transaction.delete(likeRef);
        transaction.update(postRef, {'likes': FieldValue.increment(-1)});
        _safeSetState(() {
          isLiked = false;
          likeCount--;
        });
      } else {
        // Like the post
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(postRef, {'likes': FieldValue.increment(1)});
        _safeSetState(() {
          isLiked = true;
          likeCount++;
        });
      }
    }).catchError((error) {
      print('Failed to update like: $error');
      // Revert the like state if the update fails
      _safeSetState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
    });
  }

  // Display a dialog with options when the more_vert icon is clicked
  void _showMoreOptions() async {
    // Check if the current user is the author of the post
    final isAuthor = await FirestoreServices().isCurrentUserAuthor(widget.post.id, currentUserId);
    // Check if the current user is following the post's author
    final isFollowing = await FirestoreServices().isFollowing(currentUserId, widget.post.userId);
    
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show delete option only if the current user is the author
              if (isAuthor)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _deletePost(); // Call delete method
                  },
                  child: Text('Delete Post',style: TextStyle(color: Colors.black),),
                ),
                // Show follow/unfollow option if the current user is not the author
              if (!isAuthor)
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Toggle follow status
                    await FirestoreServices().toggleFollow(currentUserId, widget.post.userId);
                    setState(() {}); // Refresh the UI
                  },
                  child: Text(isFollowing ? 'Unfollow' : 'Follow',style: TextStyle(color: Colors.black),),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel',style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

    // Method to handle post deletion
  void _deletePost() async {
    try {
      // Call the deletePost method from FirestoreServices
      await FirestoreServices().deletePost(widget.post.id);
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully'),backgroundColor: Colors.red,duration:Duration(seconds: 1),),
      );
    } catch (e) {
      // Show an error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $e')),
      );
    }
  }


    // Method to handle follow/unfollow functionality
  void _toggleFollow() async {
    try {
      // Toggle the isFollowing state
      bool newFollowState = !_post.isFollowing;
      
      // Update the post in Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(_post.id)
          .update({'isFollowing': newFollowState});

      // Update the local state
      setState(() {
        _post.isFollowing = newFollowState;
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newFollowState ? 'User followed' : 'User unfollowed'),backgroundColor: newFollowState ? Colors.green : Colors.orange,duration: Duration(seconds: 1),),
      );
    } catch (e) {
      // Show an error message if the operation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = GoogleFonts.aDLaMDisplayTextTheme();

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              children: [
                // User profile image
                CircleAvatar(
                  radius: 15,
                  backgroundImage:
                      NetworkImage(widget.post.userProfileImageUrl),
                ),
                SizedBox(width: 10),
                // Username
                Text(
                  widget.post.username,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                // More options button
                IconButton(onPressed: _showMoreOptions, icon: Icon(Icons.more_vert))
              ],
            ),
          ),

          // Post image
          CachedNetworkImage(
            imageUrl: widget.post.imageUrl,
            placeholder: (context, url) => Container(
              height: size.height / 2,
              width: size.width,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
            fit: BoxFit.cover,
            width: size.width,
          ),

          // Action buttons row
          Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/commentpage',
                      arguments: widget.post.id);
                },
                icon: Icon(Icons.mode_comment_outlined),
              ),
            
              Spacer(),
              IconButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmarked'),backgroundColor: Colors.green,duration: Duration(seconds: 1),));
              }, icon: Icon(Icons.bookmark_border))
            ],
          ),

          // Likes count
          Text(' $likeCount likes'),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8.0),
            child: RichText(
              text: TextSpan(
                style: textTheme.bodyLarge,
                children: [
                  TextSpan(
                    text: '${widget.post.username} ',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  TextSpan(
                    text: widget.post.caption,
                    style: textTheme.bodyLarge?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // View all comments
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/commentpage',
                arguments: widget.post.id),
            child: Text(
              'View all ${_post.commentCount} comments',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            '${_getTimeAgo(widget.post.timestamp)}',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 22)
        ],
      ),
    );
  }

  // Helper method to calculate and format time since post
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
