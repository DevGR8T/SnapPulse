import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  // IMAGE PICKER INSTANCE FOR HANDLING PHOTO SELECTION
  final ImagePicker picker = ImagePicker();

  File? _selectedImage;

  // METHOD TO PICK AN IMAGE FROM CAMERA OR GALLERY
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);

        //CLOSE DIALOGUE BEFORE NAVIGATING
        Navigator.of(context).pop;

        Navigator.of(context).pushNamed(
          '/postreadypage',
          arguments: _selectedImage,
        );
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      // SHOW DIALOG TO UPLOAD POST
                      return Dialog(
                        shape: RoundedRectangleBorder(),
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: Icon(Icons.photo_camera),
                              title: Text('Take Photo'),
                              onTap: () {
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.photo_library),
                              title: Text('Upload Photo'),
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.cancel_rounded),
                              title: Text('Cancel'),
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(
                  Icons.upload,
                  size: 80,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              'Add Post',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
