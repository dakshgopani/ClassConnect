// Mobile audio recorder stub – actual recording not implemented in this migration.
// Provides the same API surface as the web implementation.
class AudioRecorder {
  Future<void> init() async {}
  Future<bool> hasPermission() async => true;
  Future<void> start() async {}
  Future<String?> stop() async => null;
  Future<void> dispose() async {}
}
