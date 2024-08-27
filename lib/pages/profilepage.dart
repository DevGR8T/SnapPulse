import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_pulse/classes/signingout.dart';
import 'package:snap_pulse/services/firestoreservices.dart';
import 'package:snap_pulse/widgets/profilepageitem.dart';

// Create a stream controller for username updates
final StreamController<String> usernameUpdateStream =
    StreamController<String>.broadcast();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirestoreServices firestoreServices = FirestoreServices();
  late Stream<QuerySnapshot> _postsStream;

  // Stream controller for username updates
  StreamController<String> usernameUpdateStream =
      StreamController<String>.broadcast();
  late StreamSubscription<String> _usernameSubscription;

//current User's ID
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Stream to listen for changes in follower count
  late Stream<int> _followerCountStream;

  // Stream to listen for changes in following count
  late Stream<int> _followingCountStream;

  // Variables to store user data and state
  bool postedphoto = false;
  final ImagePicker picker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;
  String? _name;
  String? _username;
  String? _email;
  String? _bio;

  @override
  void initState() {
    super.initState();
    // Initialize posts stream and load user data
    _postsStream = Stream.empty();
    _loadUserData();

    // Listen for username updates
    _usernameSubscription = usernameUpdateStream.stream.listen((newUsername) {
      setState(() {
        _username = newUsername;
      });
    });

    // Set up the posts stream
    _postsStream = FirebaseFirestore.instance.collection('posts').snapshots();

    // Initialize the follower count stream
    _followerCountStream = firestoreServices.getFollowerCount(currentUserId);

    // Initialize the following count stream
    _followingCountStream = firestoreServices.getFollowingCount(currentUserId);

// Initialize the posts stream to listen for changes in the user's posts
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();
  }

  @override
  void dispose() {
    // Clean up resources
    _usernameSubscription.cancel();
    usernameUpdateStream.close();
    super.dispose();
  }

  // Load user data and posts from Firestore
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Update state with user data
          setState(() {
            _profileImageUrl = userData['profileImageUrl'];
            _username = userData['username'];
            _email = userData['email'];
            _bio = userData['bio'];
            _name = userData['name'];
          });

          // Fetch user's posts
          QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .get();

          // Update state based on posts
          setState(() {
            postedphoto = postsSnapshot.docs.isNotEmpty;
            _postsStream = FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots();
          });
        }
      }
      print('Current user ID: $currentUserId');
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        Navigator.of(context).pop();
        Navigator.of(context)
            .pushNamed('/postreadypage', arguments: _selectedImage);
      } else {
        print('No image selected.');
      }
    });
  }

  // Update user profile with new username
  Future<void> updateUserProfile(String newUsername) async {
    print('Updating user profile to username: $newUsername');
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update user document
      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'username': newUsername});

      // Update username in all posts by this user
      await firestoreServices.updateUsernameInPosts(user.uid, newUsername);

      // Notify listeners of username change
      usernameUpdateStream.add(newUsername);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username updated successfully')),
      );

      // Reload user data
      await _loadUserData();
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username')),
      );
    }
  }

  // Method to toggle follow status for a user
  Future<void> _toggleFollow(String targetUserId) async {
    // Check if the current user is already following the target user
    bool isCurrentlyFollowing =
        await firestoreServices.isFollowing(currentUserId, targetUserId);

    if (isCurrentlyFollowing) {
      // If already following, unfollow the user
      await firestoreServices.unfollowUser(currentUserId, targetUserId);
    } else {
      // If not following, follow the user
      await firestoreServices.followUser(currentUserId, targetUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_name ?? 'No Name'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with avatar and stats
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // Profile avatar
                      CircleAvatar(
                        backgroundColor: Colors.purple[200],
                        radius: 37,
                        child: CircleAvatar(
                          radius: 34,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _profileImageUrl ?? 'https://www.delvinia.com/wp-content/uploads/2020/05/placeholder-headshot.png',
                              placeholder: (context, url) =>
                                  Image.asset('images/profileplaceholder.jpg'),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              fit: BoxFit.cover,
                              width: 127,
                              height: 127,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Profile stats and sign out button
                      Column(
                        children: [
                          Row(
                            children: [
                              // StreamBuilder to dynamically update the post count
                              StreamBuilder<QuerySnapshot>(
                                stream: _postsStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    // If we have data, display the current number of posts
                                    return Profileitem(
                                      count:
                                          snapshot.data!.docs.length.toString(),
                                      label: 'Posts',
                                    );
                                  } else {
                                    // If no data yet, show 0 posts
                                    return Profileitem(
                                        count: '0', label: 'Posts');
                                  }
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: StreamBuilder<int>(
                                  stream: _followerCountStream,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      // If data is available, display the follower count
                                      return Profileitem(
                                        count: snapshot.data.toString(),
                                        label: 'Followers',
                                      );
                                    } else {
                                      // If no data, display 0 followers
                                      return Profileitem(
                                          count: '0', label: 'Followers');
                                    }
                                  },
                                ),
                              ),
                              // Followers StreamBuilder
                              StreamBuilder<int>(
                                stream: _followingCountStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Profileitem(
                                      count: snapshot.data.toString(),
                                      label: 'Following',
                                    );
                                  } else {
                                    return Profileitem(
                                        count: '0', label: 'Following');
                                  }
                                },
                              ),
                            ],
                          ),
                          // Sign out button
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            width: size.width / 1.6,
                            height: size.height / 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.4)),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              onPressed: () =>
                                  SigningOut.showSignOutDialog(context),
                              child: Text('Sign out'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                // User info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? 'No username',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(_bio ?? 'No Bio'),
                      ),
                      Text(
                        _email ?? 'No Email',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                // Edit profile button
                Container(
                  margin: EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  width: size.width,
                  height: size.height / 25,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.of(context)
                          .pushNamed('/profileEditpage');
                      if (result == true) {
                        await _loadUserData();
                        if (_username != null) {
                          usernameUpdateStream.add(_username!);
                        }
                      }
                    },
                    child: Text('Edit Profile'),
                  ),
                ),
                Divider(height: 1),
              ],
            ),
          ),
          // Display grid of photos or "Share Photos" prompt
          StreamBuilder<QuerySnapshot>(
            stream: _postsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                    child: Center(child: LinearProgressIndicator()));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                //show share photos" prompt if no posts
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 30),
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Share Photos',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            'When you share photos, they will appear on your profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _pickImage(ImageSource.gallery);
                          },
                          child: Text(
                            'Share your first photo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              List<DocumentSnapshot> posts = snapshot.data!.docs;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    String imageUrl = posts[index]['imageUrl'];
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
