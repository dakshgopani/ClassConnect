// Platform‑agnostic FilePicker abstraction
// This file re‑exports the appropriate implementation based on the runtime.

export 'web/file_picker.dart' if (dart.library.io) 'mobile/file_picker.dart';