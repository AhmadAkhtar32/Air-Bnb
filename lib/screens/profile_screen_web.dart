import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<String> uploadImageFile(XFile image, String path) async {
  final storageRef = FirebaseStorage.instance.ref().child(path);
  final bytes = await image.readAsBytes();
  await storageRef.putData(bytes);
  return await storageRef.getDownloadURL();
}
