import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Authservices {
  // Initialize Firebase Authentication instance
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // Sign up a new user with email, password, name, and optional profile image
  Future<UserCredential?> signup(
      String email, String password, String name, File? selectedImage) async {
    try {
      // Create new user account
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Set the user's display name
      await userCredential.user?.updateDisplayName(name);

      // Handle profile image upload and user data storage
      if (selectedImage != null) {
        await _uploadImageAndSaveUserData(
            userCredential.user!.uid, name, email, selectedImage);
      } else {
        await _saveUserData(userCredential.user!.uid, name, email, null);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific authentication errors
      throw _handleAuthException(e);
    } catch (e) {
      // Handle any other unexpected errors
      throw 'An unknown error occurred: ${e.toString()}';
    }
  }

  // Upload user's profile image to Firebase Storage and save user data
  Future<void> _uploadImageAndSaveUserData(
      String uid, String name, String email, File image) async {
    try {
      // Generate a unique filename for the image
      String fileName = 'profile_$uid.jpg';
      // Create a reference to the file location in Firebase Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);
      // Upload the file
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      // Get the download URL of the uploaded image
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save user data including the image URL
      await _saveUserData(uid, name, email, downloadUrl);
    } catch (e) {
      print('Error uploading image: $e');
      // If image upload fails, save user data without image URL
      await _saveUserData(uid, name, email, null);
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserData(
      String uid, String name, String email, String? imageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'profileImageUrl': imageUrl,
    });
  }

  // Sign in an existing user with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific authentication errors
      return Future.error(_handleAuthException(e));
    } catch (e) {
      // Handle any other unexpected errors
      throw 'An unknown error occurred: ${e.toString()}';
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // Convert Firebase authentication exceptions to user-friendly error messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'user-disabled':
        return 'Account has been disabled';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'user-not-found':
        return 'No user found for that email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'The email address is invalid';
      default:
        return 'Invalid email/password';
    }
  }
}
