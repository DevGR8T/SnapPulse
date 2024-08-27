import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

//METHOD TO COMPRESS THE IMAGE BEFORE UPLOADING
  Future<File> compressImage(File file) async {
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = path.join(
        dir.absolute.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 88,
      rotate: 0,
    );

    return File(result!.path);
  }

  //METHOD TO UPLOAD THE IMAGE TO FIREBASE STORAGE

  Future<String> uploadImage(File imageFile) async {
    try {
      //compress the image
      File compressedImage = await compressImage(imageFile);

      //generate a unique filename
      String fileName =
          'post_images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      //upload the compresed image to firebase storage
      final uploadTask =
          _storage.ref().child(fileName).putFile(compressedImage);
      final snapshot = await uploadTask.whenComplete(() {});

      //get the downlad url of the uploaded image
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Image URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }
}
