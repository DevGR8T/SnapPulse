import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snap_pulse/models/postsmodel.dart';
import 'package:snap_pulse/services/firestoreservices.dart';
import 'package:snap_pulse/services/storageservice.dart';

class PostReadyPage extends StatefulWidget {
  final File selectedImage;

  const PostReadyPage({required this.selectedImage, super.key});

  @override
  State<PostReadyPage> createState() => _PostReadyPageState();
}

class _PostReadyPageState extends State<PostReadyPage> {
  bool _isPosting = false;
  TextEditingController _captionController = TextEditingController();
  String? _profileImageUrl;

//METHOD TO HANDLE POST CREATION
  Future<void> _handlePost() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Upload the image and get its URL
      final imageUrl = await StorageService().uploadImage(widget.selectedImage);
      print('Image uploaded successfully: $imageUrl');

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Create a new post
      final post = Post(
        id: '',
        userId: user.uid,
        username: userData['username'] ?? 'Unknown',
        userProfileImageUrl: userData['profileImageUrl'] ?? '',
        caption: _captionController.text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      // Add post to Firestore
      await FirestoreServices().addPosts(post);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Post uploaded successfully!'),
        backgroundColor: Colors.green,
      ));

      // Navigate to root page after posting
      Navigator.of(context).pushReplacementNamed('/rootpage');
    } catch (e) {
      print('Error posting: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error uploading post: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    //GET THE CURRENT USERS'S ID FROM FIREBASE AUTHENTICATION
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
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Post to', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _handlePost,
            child: Text('Post', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
      body: Column(
        children: [
          //SHOW PROGRESS INDICATOR WHILE POSTING
          _isPosting ? LinearProgressIndicator() : SizedBox(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                //USER AVATAR
                CircleAvatar(
                  radius: 20,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _profileImageUrl ?? '',
                      placeholder: (context, url) =>
                          Image.asset('images/profileplaceholder.jpg'),
                      fit: BoxFit.cover,
                      width: 127,
                      height: 127,
                    ),
                  ),
                ),
                SizedBox(width: 10),

                //CAPTION INPUT FIELD
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                        hintText: 'Write a caption...',
                        border: InputBorder.none,
                        counterText: ''),
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 60,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                ),
                SizedBox(width: 10),

                //PREVIEW OF THE SELCTED IMAGE
                Container(
                  width: size.width / 5,
                  height: size.height / 11,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      widget.selectedImage,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
