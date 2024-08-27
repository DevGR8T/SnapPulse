import 'package:flutter/material.dart';
import 'package:snap_pulse/models/postsmodel.dart';
import 'package:snap_pulse/pages/profilepage.dart';
import 'package:snap_pulse/services/firestoreservices.dart';
import 'package:snap_pulse/widgets/postcard.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // STREAM OF POSTS FROM FIRESTORE
  late Stream<List<Post>> _postsStream;

  @override
  void initState() {
    super.initState();

    // Initialize the posts stream when the widget is created
    _initializePostsStream();

    _postsStream = FirestoreServices().getPosts();

    // Listen to username updates if necessary
    usernameUpdateStream.stream.listen((newUsername) {
      _refreshPosts();
      // Update the UI or data source with the new username
      setState(() {
        // Update relevant data or refresh the UI
      });
    });
  }

  void _initializePostsStream() {
    setState(() {
      _postsStream = FirestoreServices().getPosts();
    });
  }

  void _refreshPosts() {
    setState(() {
      _postsStream = FirestoreServices().getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapPulse'),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.mode_comment_outlined))
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          // SHOW LOADING INDICATOR WHILE WAITING FOR DATA
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // SHOW ERROR IF THERE'S AN ERROR
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // SHOW MESSAGE IF THERE ARE NO POSTS
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No posts available'));
          }

          // BUILD A SCROLLABLE LIST OF POSTS
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                PostCard(post: snapshot.data![index]),
          );
        },
      ),
    );
  }
}
