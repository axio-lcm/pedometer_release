import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/common/config/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 已导入运动音乐的持久化记录（path 为文档目录内副本的绝对路径）。
class WorkoutMusicTrackRecord {
  final String path;
  final String name;

  const WorkoutMusicTrackRecord({required this.path, required this.name});
}

/// 运动音乐持久化：file_picker 返回的是缓存目录副本（系统随时可清理），
/// 导入时拷贝到文档目录 `workout_music/` 下长期保存；曲目列表存
/// SharedPreferences，冷启动恢复。列表只存文件名不存绝对路径，
/// 兼容 iOS 更新后应用容器路径变化。
class WorkoutMusicStore {
  WorkoutMusicStore._();

  static const _dirName = 'workout_music';

  static Future<Directory> _musicDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 把选中的临时文件拷贝到持久目录，返回副本路径；失败返回 null。
  /// 同名文件视为同一曲目，直接复用已有副本。
  static Future<String?> persistPickedFile({
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      final dir = await _musicDir();
      final target = File(p.join(dir.path, fileName));
      if (!await target.exists()) {
        await File(sourcePath).copy(target.path);
      }
      return target.path;
    } catch (_) {
      return null;
    }
  }

  /// 恢复曲目列表；副本文件已不存在的条目被剔除并回写列表。
  static Future<List<WorkoutMusicTrackRecord>> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(PrefsKeys.workoutMusicTracks);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final dir = await _musicDir();
      final tracks = <WorkoutMusicTrackRecord>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final file = item['file'];
        final name = item['name'];
        if (file is! String || file.isEmpty || name is! String) continue;
        final path = p.join(dir.path, file);
        if (!File(path).existsSync()) continue;
        tracks.add(WorkoutMusicTrackRecord(path: path, name: name));
      }
      if (tracks.length != decoded.length) await saveTracks(tracks);
      return tracks;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveTracks(List<WorkoutMusicTrackRecord> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode([
        for (final track in tracks)
          {'file': p.basename(track.path), 'name': track.name},
      ]);
      await prefs.setString(PrefsKeys.workoutMusicTracks, payload);
    } catch (_) {
      // 持久化失败不影响本次会话播放。
    }
  }

  /// 记录当前播放到的曲目下标，冷启动恢复后从该曲目继续。
  static Future<void> saveCurrentIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefsKeys.workoutMusicCurrentIndex, index);
    } catch (_) {
      // 持久化失败不影响本次会话播放。
    }
  }

  /// 恢复上次播放到的曲目下标；未存过或异常时返回 0。
  /// 曲目列表可能因文件丢失被剔除过条目，调用方需自行 clamp。
  static Future<int> restoreCurrentIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(PrefsKeys.workoutMusicCurrentIndex) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 删除曲目的持久副本文件（列表另由 [saveTracks] 回写）。
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 文件删除失败时残留副本无害，重导入同名文件会复用。
    }
  }
}
