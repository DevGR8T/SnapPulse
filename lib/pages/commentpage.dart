import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snap_pulse/services/firestoreservices.dart';
import 'package:snap_pulse/models/commentmodel.dart';

class CommentPage extends StatefulWidget {
  const CommentPage({required this.postId, super.key});
  final String postId;

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  late Stream<List<Comment>> _commentsStream;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  String? _profileImageUrl;
  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _initializeCommentsStream();
    _loadUserData();
  }

  //INITIALIZE THE SREAM OF COMMENTS FOR THE CURRENT POST
  void _initializeCommentsStream() {
    _commentsStream = FirestoreServices().getCommentsForPost(widget.postId);
  }

//LOAD THE CURRENT USER'S DATA FROM FIRESTORE
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _profileImageUrl = userData['profileImageUrl'];
            _currentUserId = user.uid;
            _currentUsername = userData['username'];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

//ADD A NEW COMMENT TO THE POST
  Future<void> _addComment() async {
    if (_currentUserId != null &&
        _currentUsername != null &&
        !_isPostingComment) {
      setState(() {
        _isPostingComment = true;
      });

      try {
        //CREATE A NEW COMMENT OBJECT
        Comment newComment = Comment(
          id: '',
          postId: widget.postId,
          userId: _currentUserId!,
          username: _currentUsername!,
          userProfileImageUrl: _profileImageUrl ?? '',
          text: _commentController.text,
          timestamp: DateTime.now(),
          likes: 0,
        );

        //ADD THE COMMENT TO FIRESTORE
        await FirestoreServices().addComment(newComment);
        _commentController.clear();

        // UPDATE THE COMMENT COUNT ON THE POST
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({'commentCount': FieldValue.increment(1)});
      } catch (e) {
        print('Error posting comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment. Please try again.')),
        );
      } finally {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          //DISPLAY THE LIST OF COMMENTS
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _commentsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<List<Comment>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No comments yet'));
                }
                List<Comment> comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    Comment comment = comments[index];
                    return CommentTile(
                      comment: comment,
                      key: ValueKey(comment.id),
                      onReplyAdded: () {},
                      isReply: false,
                      depth: 0,
                    );
                  },
                );
              },
            ),
          ),
          //COMMENT INPUT FIELD
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isPostingComment
                ? Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      //User Avatar

                      CircleAvatar(
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profileImageUrl ?? '',
                            placeholder: (context, url) =>
                                Image.asset('images/profileplaceholder.jpg'),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),

                      //comment text input
                      Expanded(
                        child: TextFormField(
                          controller: _commentController,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          scrollPhysics: BouncingScrollPhysics(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Add a comment...',
                            hintStyle:
                                TextStyle(color: Colors.black.withOpacity(0.3)),
                          ),
                        ),
                      ),

                      //post comment button
                      TextButton(
                        onPressed: _isPostingComment
                            ? null
                            : () {
                                if (_commentController.text.isNotEmpty) {
                                  _addComment();
                                }
                              },
                        child: Text(
                          'Post',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

//DIFFERENT CLASS

class CommentTile extends StatefulWidget {
  const CommentTile(
      {required this.comment,
      required this.onReplyAdded,
      required this.isReply,
      required this.depth,
      this.parentCommentId,
      super.key});
  final Comment comment;
  final VoidCallback onReplyAdded;
  final bool isReply;
  final int depth;
  final String? parentCommentId;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late Stream<QuerySnapshot> _repliesStream;
  late StreamSubscription<DocumentSnapshot> _commentSubscription;

  bool isExpanded = false;
  bool isLiked = false;
  int _likeCount = 0;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _showReplies = false;
  int _totalReplyCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRepliesStream();
    _fetchLikeStatus();
    _fetchLikeCount();
    _listenToCommentUpdates();
    _fetchTotalReplyCount();
  }

//FETCH TOTAL REPLY COUNT
  Future<void> _fetchTotalReplyCount() async {
  int count = await FirestoreServices().getTotalReplyCountForComment(widget.comment.id);
  setState(() {
    _totalReplyCount = count;
  });
}

//INITIALIZE THE STREAM FOR REPLIES TO THIS COMMENT
  void _initializeRepliesStream() {
    _repliesStream = FirebaseFirestore.instance
        .collection('comments')
        .where('parentCommentId', isEqualTo: widget.comment.id)
        .orderBy('timestamp', descending: false)
        .snapshots();
    print("Replies stream initialized for comment: ${widget.comment.id}");
  }

//LISTEN FOR UPDATES TO THE COMMENT AND UPDATE THE UI ACCORDINGLY
  void _listenToCommentUpdates() {
    _commentSubscription = FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.comment.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedComment = Comment.fromMap(snapshot.data()!, snapshot.id);
        setState(() {
          widget.comment.username = updatedComment.username;
          widget.comment.userProfileImageUrl =
              updatedComment.userProfileImageUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentSubscription.cancel();
    super.dispose();
  }

//TOGGLE THE LIKE STATUS OF THE COMMENT
  void _toggleLike() {
    final commentRef = FirebaseFirestore.instance
        .collection('comments')
        .doc(widget.comment.id);
    final likeRef = commentRef.collection('likes').doc(currentUserId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw Exception("Comment does not exist!");
      }

      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(commentRef, {'likes': FieldValue.increment(-1)});
        setState(() {
          isLiked = false;
          _likeCount--;
        });
      } else {
        //LIKE THE COMMENT
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.update(commentRef, {'likes': FieldValue.increment(1)});
        setState(() {
          isLiked = true;
          _likeCount++;
        });
      }
    }).catchError((error) {
      print('Failed to update like: $error');
      setState(() {
        isLiked = !isLiked;
        _likeCount += isLiked ? 1 : -1;
      });
    });
  }

//FETCH THE CURRENT LIKE STATUS FOR THE COMMENT
  Future<void> _fetchLikeStatus() async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection('comments')
          .doc(widget.comment.id);
      final likeRef = commentRef.collection('likes').doc(currentUserId);
      final likeSnapshot = await likeRef.get();
      setState(() {
        isLiked = likeSnapshot.exists;
      });
    } catch (e) {
      print('Error fetching like status: $e');
    }
  }

//FETCH THE CURRENT LIKE COUNT FOR THE COMMENT
  Future<void> _fetchLikeCount() async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection('comments')
          .doc(widget.comment.id);
      final commentSnapshot = await commentRef.get();
      if (commentSnapshot.exists) {
        final commentData = commentSnapshot.data();
        setState(() {
          _likeCount = commentData?['likes'] ?? 0;
        });
      } else {
        setState(() {
          _likeCount = 0;
        });
      }
    } catch (e) {
      print('Error fetching like count: $e');
    }
  }

  //SHOW THE REPLY INPUT BOTTOM SHEET
  void _toggleReplyInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ReplyBottomSheet(
          parentComment: widget.comment,
          onReplySent: widget.onReplyAdded,
        );
      },
    );
  }

//CALCULATE THE PADDING FOR THE NESTED REPLIES
 double _calculatePadding() {
  // Set a maximum indentation level (e.g., 3)
  int maxIndentationLevel = 1;
  // Use a smaller, fixed indentation amount
  double indentationAmount = 1;
  
  // Calculate the indentation, but cap it at the maximum level
  int effectiveDepth = widget.depth > maxIndentationLevel ? maxIndentationLevel : widget.depth;
  
  return effectiveDepth * indentationAmount;
}

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.aDLaMDisplayTextTheme();
    return Padding(
      padding: EdgeInsets.only(left: _calculatePadding()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 5),
            leading: CircleAvatar(
              radius: 20.0,
              backgroundImage: CachedNetworkImageProvider(
                  widget.comment.userProfileImageUrl),
            ),
            title: LayoutBuilder(
              builder: (context, constraints) {
                //BUILD THE COMMENT TEXT WITH USERNAME
                TextPainter textPainter = TextPainter(
                  text: TextSpan(
                    text: '${widget.comment.username} ${widget.comment.text}',
                    style: textTheme.bodyLarge?.copyWith(fontSize: 12),
                  ),
                  maxLines: 2,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: constraints.maxWidth);

                bool isTextOverflowing = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //DISPLAY COMMENT TEXT WITH EXPANDABLE FUNCTIONALITY
                    RichText(
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      text: TextSpan(
                        style: textTheme.bodyLarge,
                        children: [
                          TextSpan(
                            text: widget.comment.username,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0 ,
                            ),
                          ),
                          TextSpan(text: '   '),
                          if (widget.comment.text.startsWith('@'))
                            TextSpan(
                              text: widget.comment.text.split(' ').first,
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 13.0 - (widget.depth * 0.5),
                                color: Colors.blue,
                              ),
                            ),
                          TextSpan(
                            text: widget.comment.text.startsWith('@')
                                ? ' ' +
                                    widget.comment.text
                                        .split(' ')
                                        .skip(1)
                                        .join(' ')
                                : widget.comment.text,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 13.0 ,
                            ),
                          ),
                        ],
                      ),
                    ),

                    //Show 'show more' /'show less'button if text is overflowing
                    if (isTextOverflowing)
                      InkWell(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? 'show less' : 'show more',
                          style: TextStyle(
                              color: Colors.purple[900], fontSize: 15),
                        ),
                      ),
                  ],
                );
              },
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      //DISPLAY TIME AGO
                      Text(
                        _getTimeAgo(widget.comment.timestamp),
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 12),

                      //DISPLAY LIKE COUNT
                      Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$_likeCount likes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(width: 15),

                      //REPLY BUTTON
                      TextButton(
                        onPressed: _toggleReplyInput,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0 ,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(30, 20),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //LIKE BUTTON
            trailing: IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
                size: 17,
              ),
            ),
          ),

          //DISPLAY REPLIES IF THIS IS NOT A REPLY ITSELF
          
            StreamBuilder<QuerySnapshot>(
              stream: _repliesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox();
                }
                List<Comment> replies = snapshot.data!.docs
                    .map((doc) => Comment.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //BUTTON TO SHOW/HIDE REPLIES
                    if (widget.depth == 0)
                    Padding(
                      padding:
                          EdgeInsets.only(left: 80.0, top: 8.0, bottom: 8.0),
                      child: Container(
                        width: 120,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _showReplies = !_showReplies),
                          child: Text(
                            _showReplies
                                ? 'Hide replies'
                                : 'View $_totalReplyCount replies',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                   if (widget.depth > 0 || _showReplies)
                  Column(
                    children: replies
                        .map((reply) =>  CommentTile(
                                  comment: reply,
                                  onReplyAdded: widget.onReplyAdded,
                                  isReply: true,
                                  depth: widget.depth + 1,
                                  parentCommentId: widget.comment.id,
                                ),
                        
                            )
                        .toList(),
                  ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

//CONVERTS A DATETIME TO A HUMAN- READABLE RELATIVE TIME STRING
String _getTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'just now';
  }
}

//DISPLAYS A BOTTOM SHEET FOR REPLYING TO A COMMENT

class ReplyBottomSheet extends StatefulWidget {
  final Comment parentComment;
  final VoidCallback onReplySent;

  const ReplyBottomSheet({
    Key? key,
    required this.parentComment,
    required this.onReplySent,
  }) : super(key: key);

  @override
  _ReplyBottomSheetState createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<ReplyBottomSheet> {
  late TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;
  late String _currentUserId;
  late String _currentUsername;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    //INITIALIZE THE REPLY TEXT WITH THE PARENT COMMENT USERNAME
    _replyController =
        TextEditingController(text: "@${widget.parentComment.username} ");
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

//LOAD THE CURRENT USER'S DATA FROM FIRESTORE
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserId = user.uid;
          _currentUsername = userData['username'];
          _profileImageUrl = userData['profileImageUrl'] as String;
        });
      }
    }
  }

//SEND REPLY TO FIRESTORE
  Future<void> _sendReply() async {
    //Ensure the reply starts with the parent comment's username
    if (_replyController.text.isNotEmpty && !_isReplying) {
      setState(() {
        _isReplying = true;
      });

      try {
        String replyText = _replyController.text.trim();
        if (!replyText.startsWith("@${widget.parentComment.username} ")) {
          replyText = "@${widget.parentComment.username} $replyText";
        }

        //Create a new Comment object for the reply
        Comment newReply = Comment(
          id: '',
          postId: widget.parentComment.postId,
          userId: _currentUserId,
          username: _currentUsername,
          userProfileImageUrl: _profileImageUrl ?? '',
          text: replyText,
          timestamp: DateTime.now(),
          likes: 0,
          parentCommentId: widget.parentComment.id,
        );

        //Add the reply to the firestore

        await FirestoreServices().addReply(newReply, widget.parentComment.id);

        ///Notify the parent widget that a reply was added
        widget.onReplySent();
        Navigator.pop(context);
      } catch (e) {
        print('Error posting reply: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply. Please try again.')),
        );
      } finally {
        setState(() {
          _isReplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            //USER AVATAR

            CircleAvatar(
              backgroundImage: _profileImageUrl != null
                  ? CachedNetworkImageProvider(_profileImageUrl!)
                  : NetworkImage(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNwD-geCtaIaqxMoMoBNpvonJNKKqwiko5nA&s')
                      as ImageProvider,
            ),
            SizedBox(width: 15),

            //REPLY TEXT INPUT FIELD
            Expanded(
              child: TextField(
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                scrollPhysics: BouncingScrollPhysics(),
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.parentComment.username}...',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
              ),
            ),

            //SEND REPLY BUTTON
            TextButton(
                onPressed: _isReplying ? null : _sendReply, child: Text('Send'))
          ],
        ),
      ),
    );
  }
}
