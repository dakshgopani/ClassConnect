// Stub implementation of dart:io's File for web builds.
// Provides just enough API for the parts of the app that expect a File
// when running on platforms where dart:io is unavailable (e.g., Flutter Web).
// The methods return empty or dummy values – the code that uses them
// should be guarded by `kIsWeb` so they are never executed on the web.

import 'dart:typed_data';

class File {
  final String path;
  const File(this.path);

  // In a real mobile environment this reads the file contents.
  // On web we return an empty Uint8List – the caller should not rely on it.
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}
