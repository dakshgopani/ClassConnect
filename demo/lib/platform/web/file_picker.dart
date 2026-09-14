// Web implementation of file picking using file_picker package (which already supports web)
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class PlatformFilePicker {
  /// Picks a single image file and returns its bytes.
  static Future<Uint8List?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      return result.files.first.bytes;
    }
    return null;
  }

  /// Picks a single file of any type and returns its bytes.
  static Future<Uint8List?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      return result.files.first.bytes;
    }
    return null;
  }
}
