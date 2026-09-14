// Web audio recorder implementation using MediaRecorder.
// Provides the same API surface as the mobile version.
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class AudioRecorder {
  html.MediaRecorder? _recorder;
  final List<html.Blob?> _chunks = [];
  bool _hasPermission = false;
  String? _audioUrl;
  Uint8List? _recordedBytes;

  /// Checks and requests microphone permission.
  Future<bool> hasPermission() async {
    try {
      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'audio': true});
      // We just needed the permission, stop tracks immediately.
      stream.getTracks().forEach((t) => t.stop());
      _hasPermission = true;
    } catch (e) {
      _hasPermission = false;
    }
    return _hasPermission;
  }

  Future<void> init() async {
    // No additional initialisation needed for web.
  }

  /// Starts recording. The optional [RecordConfig] from the mobile API is ignored.
  Future<void> start([dynamic _]) async {
    if (!_hasPermission) await hasPermission();
    final stream = await html.window.navigator.mediaDevices!
        .getUserMedia({'audio': true});
    _recorder = html.MediaRecorder(stream);
    _chunks.clear();
    _recorder!.addEventListener('dataavailable', (html.Event e) {
      final blobEvent = e as html.BlobEvent;
      _chunks.add(blobEvent.data);
    });
    _recorder!.start();
  }

  /// Stops recording and returns a URL that can be used by the audio player.
  /// The URL is an object URL pointing to the recorded Blob.
  Future<String?> stop() async {
    if (_recorder == null) return null;
    final completer = Completer<String?>();
    _recorder!.addEventListener('stop', (html.Event event) async {
      final blob = html.Blob(_chunks.whereType<html.Blob>().toList(), 'audio/webm');
      _audioUrl = html.Url.createObjectUrlFromBlob(blob);
      // Also keep raw bytes for upload if needed.
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoadEnd.first;
      _recordedBytes = (reader.result as Uint8List);
      completer.complete(_audioUrl);
    });
    _recorder!.stop();
    return completer.future;
  }

  /// Returns the raw bytes of the last recording (for upload).
  Uint8List? get recordedBytes => _recordedBytes;

  Future<void> dispose() async {
    _recorder?.stop();
    _recorder = null;
    _chunks.clear();
    if (_audioUrl != null) {
      html.Url.revokeObjectUrl(_audioUrl!);
      _audioUrl = null;
    }
  }
}
