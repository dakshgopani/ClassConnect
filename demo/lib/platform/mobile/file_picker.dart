// Mobile implementation of file picking using image_picker and file_picker
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class PlatformFilePicker {
  /// Picks an image using image_picker (allows camera/gallery).
  static Future<Uint8List?> pickImage() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      return await file.readAsBytes();
    }
    return null;
  }

  /// Picks any file using file_picker.
  static Future<Uint8List?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      return result.files.first.bytes ??
          await File(result.files.first.path!).readAsBytes();
    }
    return null;
  }
}
