import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String> uploadImageFile(XFile image, String path) async {
  final storageRef = FirebaseStorage.instance.ref().child(path);
  await storageRef.putFile(File(image.path));
  return await storageRef.getDownloadURL();
}
