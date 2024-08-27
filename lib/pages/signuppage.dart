import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snap_pulse/services/storageservice.dart';
import 'package:snap_pulse/widgets/signuptextfield.dart';
import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // ImagePicker instance for handling photo selection
  final ImagePicker picker = ImagePicker();
  File? _selectedImage;

  final StorageService _storageService = StorageService();

  // Method to pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // Upload image to Firebase Storage
          String fileName = 'profile_${currentUser.uid}.jpg';
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child(fileName);

          UploadTask uploadTask = ref.putFile(_selectedImage!);
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          // Save the download URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({'profileImageUrl': downloadUrl}, SetOptions(merge: true));

          print('Image uploaded successfully. URL: $downloadUrl');
        } else {
          print('No user is currently signed in.');
          // You might want to show an error message to the user here
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    } else {
      print('No image selected.');
    }
  }

  // Show bottom sheet for image selection options
  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Upload Photo'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take Photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to handle app exit confirmation
  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(),
        title: Text('Exit App'),
        content: Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('Yes'),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: Text('No'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build method for the SignUpPage widget
    return PopScope(
      // This prevents the default back button behavior
      canPop: false,
      // Handles the back button press or swipe
      onPopInvoked: (didPop) async {
        if (didPop) {
          // If a pop was already handled then just do nothing
          return;
        }
        // Show exit confirmation
        final shouldPop = await _onWillPop(context);
        if (shouldPop) {
          // If user confirms exit, close the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SnapPulse',
                    style: TextStyle(fontSize: 25),
                  ),
                  SizedBox(height: 45),

                  // Profile photo
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : CachedNetworkImageProvider(
                                'https://qph.cf2.quoracdn.net/main-qimg-6d72b77c81c9841bd98fc806d702e859-lq',
                              ) as ImageProvider,
                      ),
                      Positioned(
                        bottom: 1,
                        right: 2,
                        child: InkWell(
                          onTap: () => _showImagePicker(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.purple,
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 25),

                  // Textfields
                  SignUpWidget(
                    selectedImage: _selectedImage,
                  ),

                  SizedBox(height: 25),

                  // Text below textfield
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?'),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/loginpage', (Route<dynamic> route) => false);
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(fontSize: 15),
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
