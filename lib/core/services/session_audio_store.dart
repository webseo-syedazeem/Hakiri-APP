import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps drill recordings on-device (API rejects audio upload).
class SessionAudioStore {
  SessionAudioStore._();
  static final SessionAudioStore instance = SessionAudioStore._();

  static const _prefPrefix = 'hakkiri_session_audio_';

  /// Prefer path_provider; fall back to [Directory.systemTemp] if the iOS
  /// FFI path_provider_foundation loader fails (DOBJC_initializeApi).
  Future<Directory> _safeTempDir() async {
    try {
      return await getTemporaryDirectory();
    } catch (e, st) {
      debugPrint('[SessionAudioStore] getTemporaryDirectory failed: $e\n$st');
      return Directory.systemTemp;
    }
  }

  Future<Directory> _dir() async {
    Directory root;
    try {
      root = await getApplicationDocumentsDirectory();
    } catch (e, st) {
      debugPrint(
        '[SessionAudioStore] getApplicationDocumentsDirectory failed: $e\n$st',
      );
      root = Directory.systemTemp;
    }
    final dir = Directory('${root.path}/session_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> startTempPath() async {
    final dir = await _safeTempDir();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/hakkiri_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  /// Copy temp recording into permanent storage keyed by session id.
  Future<String?> persist({
    required String sessionId,
    required String tempPath,
  }) async {
    if (sessionId.isEmpty || tempPath.isEmpty) return null;
    try {
      final src = File(tempPath);
      if (!await src.exists()) return null;
      final dest = File('${(await _dir()).path}/$sessionId.m4a');
      await src.copy(dest.path);
      try {
        await src.delete();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$sessionId', dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// When API replaces local UUID with Mongo id, keep the same file.
  Future<void> rekey({
    required String fromId,
    required String toId,
  }) async {
    if (fromId.isEmpty || toId.isEmpty || fromId == toId) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('$_prefPrefix$fromId');
    if (path == null || path.isEmpty) return;
    await prefs.setString('$_prefPrefix$toId', path);
    await prefs.remove('$_prefPrefix$fromId');
    try {
      final file = File(path);
      if (await file.exists()) {
        final dest = File('${(await _dir()).path}/$toId.m4a');
        if (file.path != dest.path) {
          await file.rename(dest.path);
          await prefs.setString('$_prefPrefix$toId', dest.path);
        }
      }
    } catch (_) {}
  }

  Future<String?> pathFor(String sessionId) async {
    if (sessionId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefPrefix$sessionId');
    if (stored != null && stored.isNotEmpty) {
      if (await File(stored).exists()) return stored;
    }
    final fallback = File('${(await _dir()).path}/$sessionId.m4a');
    if (await fallback.exists()) return fallback.path;
    return null;
  }

  Future<void> remove(String sessionId) async {
    if (sessionId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_prefPrefix$sessionId');
      if (stored != null && stored.isNotEmpty) {
        final f = File(stored);
        if (await f.exists()) await f.delete();
      }
      await prefs.remove('$_prefPrefix$sessionId');
      final fallback = File('${(await _dir()).path}/$sessionId.m4a');
      if (await fallback.exists()) await fallback.delete();
    } catch (_) {}
  }
}
