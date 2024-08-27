import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_pulse/services/storageservice.dart';
import 'package:snap_pulse/services/firestoreservices.dart';

class ProfileEditpage extends StatefulWidget {
  const ProfileEditpage({super.key});
  @override
  State<ProfileEditpage> createState() => _ProfileEditpageState();
}

class _ProfileEditpageState extends State<ProfileEditpage> {
  bool _isUpdating = false;

  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _usernamecontroller = TextEditingController();
  final TextEditingController _biocontroller = TextEditingController();

  String? _name;
  String? _username;
  String? _bio;

  final ImagePicker picker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentuser = FirebaseAuth.instance.currentUser;
      if (currentuser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentuser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _profileImageUrl = userData['profileImageUrl'];
            _name = userData['name'];
            _username = userData['username'];
            _bio = userData['bio'];

            _namecontroller.text = _name ?? '';
            _usernamecontroller.text = _username ?? '';
            _biocontroller.text = _bio ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      User? currentuser = FirebaseAuth.instance.currentUser;
      if (currentuser != null) {
        String? newProfileImage = _profileImageUrl;

        if (_selectedImage != null) {
          newProfileImage = await StorageService().uploadImage(_selectedImage!);
        }

        Map<String, dynamic> updateData = {};

        if (_namecontroller.text.isNotEmpty)
          updateData['name'] = _namecontroller.text;
        if (_usernamecontroller.text.isNotEmpty &&
            _usernamecontroller.text != _username) {
          updateData['username'] = _usernamecontroller.text;
          await FirestoreServices()
              .updateUsernameInPosts(currentuser.uid, _usernamecontroller.text);
          await FirestoreServices().updateUsernameInComments(
              currentuser.uid, _usernamecontroller.text);
        }
        if (_biocontroller.text.isNotEmpty)
          updateData['bio'] = _biocontroller.text;
        if (newProfileImage != null)
          updateData['profileImageUrl'] = newProfileImage;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentuser.uid)
            .update(updateData);

        setState(() {
          _name = _namecontroller.text;
          _username = _usernamecontroller.text;
          _bio = _biocontroller.text;
          _profileImageUrl = newProfileImage;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print('Error updating user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _handleDoneButton() async {
    setState(() {
      _isUpdating = true;
    });
    await _updateUserProfile();
    setState(() {
      _isUpdating = false;
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                )),
            const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            TextButton(
                onPressed: _isUpdating ? null : _handleDoneButton,
                child: Text('Done',
                    style: TextStyle(
                        fontSize: 18, color: _isUpdating ? Colors.grey : null)))
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              if (_isUpdating) LinearProgressIndicator(),
              SizedBox(height: 15),
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : CachedNetworkImageProvider(_profileImageUrl ?? '')
                        as ImageProvider,
              ),
              SizedBox(height: 5),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(color: Colors.purple[900], fontSize: 16),
                ),
              ),
              _buildTextField('Name', _name ?? '', _namecontroller,
                  maxLength: 20),
              _buildTextField('Username', 'Luvyduvy', _usernamecontroller,
                  maxLength: 12, isUsername: true),
              _buildBioTextField('Bio', _biocontroller)
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField(
    String label, String value, TextEditingController _controller,
    {int? maxLength, bool isUsername = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(width: 50),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(2),
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
              counterText: '',
              border: InputBorder.none,
            ),
            maxLength: maxLength,
            inputFormatters: isUsername ? [UsernameInputFormatter()] : null,
          ),
        )
      ],
    ),
  );
}

Widget _buildBioTextField(
  String label,
  TextEditingController controller,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(5),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
            maxLines: 4,
            maxLength: 100,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ],
    ),
  );
}

class UsernameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String formatted = newValue.text.toLowerCase().replaceAll(' ', '_');
    formatted = formatted.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
