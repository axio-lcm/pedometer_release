import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:pedometer/feature/home/model/health_repository.dart';
import 'package:pedometer/feature/home/model/health_sync_models.dart';

/// 健康 / 运动数据的本地结构化持久化（sqflite）。
///
/// 设计要点：
/// - `daily_summary` 以「自然日」为主键 → **天然按日去重**，每天只有一行权威记录。
/// - 写入走 [_merge] 的「按字段合并」：Apple Health 为权威源，其卡路里/活动时长不会被
///   运动传感器的估算值覆盖；步数取 max 保证单调不回退；距离 Apple Health 优先、
///   运动传感器兜底。
/// - 只持久化真实来源（Apple Health / 运动传感器）的数据，**mock 永不入库**。
class HealthDataStore {
  HealthDataStore._();

  static final HealthDataStore instance = HealthDataStore._();

  static const _dbName = 'pedometer_health.db';
  static const _dbVersion = 1;
  static const _summaryTable = 'daily_summary';
  static const _historyTable = 'sync_history';
  static const _metaTable = 'meta';
  static const _metaLastSyncKey = 'last_sync_ms';

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get _database {
    final db = _db;
    if (db != null) return Future.value(db);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_summaryTable (
            date TEXT PRIMARY KEY,
            steps INTEGER NOT NULL,
            distance_km REAL NOT NULL,
            calories_kcal REAL NOT NULL,
            active_minutes INTEGER NOT NULL,
            source TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_historyTable (
            id TEXT PRIMARY KEY,
            time INTEGER NOT NULL,
            source TEXT NOT NULL,
            mode TEXT NOT NULL,
            item_count INTEGER NOT NULL,
            snapshot TEXT NOT NULL,
            elapsed_ms INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_metaTable (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  // ---------------------------------------------------------------------------
  // 日汇总（去重 + 合并写入）
  // ---------------------------------------------------------------------------

  /// 合并写入一批日汇总。mock 数据请勿传入。
  Future<void> upsertSummaries(List<HealthDailySummary> summaries) async {
    if (summaries.isEmpty) return;
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (final incoming in summaries) {
        final existingRows = await txn.query(
          _summaryTable,
          where: 'date = ?',
          whereArgs: [incoming.dateKey],
          limit: 1,
        );
        final merged = existingRows.isEmpty
            ? incoming
            : _merge(HealthDailySummary.fromRow(existingRows.first), incoming);
        await txn.insert(
          _summaryTable,
          {...merged.toRow(), 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 同一自然日 existing(库内权威) 与 incoming(新数据) 的按字段合并。
  HealthDailySummary _merge(
    HealthDailySummary existing,
    HealthDailySummary incoming,
  ) {
    final steps = existing.steps > incoming.steps
        ? existing.steps
        : incoming.steps;

    if (incoming.source == HealthSyncSource.appleHealth) {
      // Apple Health 权威：用其真实值，但不以 0 覆盖既有值（防部分类型同步抹数据）。
      return HealthDailySummary(
        date: incoming.date,
        steps: steps,
        distanceKm: incoming.distanceKm > 0
            ? incoming.distanceKm
            : existing.distanceKm,
        caloriesKcal: incoming.caloriesKcal > 0
            ? incoming.caloriesKcal
            : existing.caloriesKcal,
        activeMinutes: incoming.activeMinutes > 0
            ? incoming.activeMinutes
            : existing.activeMinutes,
        source: HealthSyncSource.appleHealth,
      );
    }

    // 运动传感器：只刷新 步数 / 距离；卡路里 / 活动时长若已是 Apple Health 权威值则保留。
    final existingIsAuthoritative =
        existing.source == HealthSyncSource.appleHealth;
    final distanceKm = existing.distanceKm > incoming.distanceKm
        ? existing.distanceKm
        : incoming.distanceKm;
    return HealthDailySummary(
      date: incoming.date,
      steps: steps,
      distanceKm: distanceKm,
      caloriesKcal: existingIsAuthoritative
          ? existing.caloriesKcal
          : incoming.caloriesKcal,
      activeMinutes: existingIsAuthoritative
          ? existing.activeMinutes
          : incoming.activeMinutes,
      source: existingIsAuthoritative
          ? HealthSyncSource.appleHealth
          : HealthSyncSource.motionSensor,
    );
  }

  /// 读取全部日汇总，按日期升序。
  Future<List<HealthDailySummary>> loadSummaries() async {
    final db = await _database;
    final rows = await db.query(_summaryTable, orderBy: 'date ASC');
    return [for (final row in rows) HealthDailySummary.fromRow(row)];
  }

  // ---------------------------------------------------------------------------
  // 同步历史
  // ---------------------------------------------------------------------------

  Future<void> recordSyncHistory(SyncHistoryEntry entry, {int keep = 50}) async {
    final db = await _database;
    await db.insert(_historyTable, {
      'id': entry.id,
      'time': entry.time.millisecondsSinceEpoch,
      'source': entry.source.name,
      'mode': entry.mode,
      'item_count': entry.itemCount,
      'snapshot': jsonEncode(entry.snapshot.toRow()),
      'elapsed_ms': entry.elapsed.inMilliseconds,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 仅保留最近 keep 条，避免历史无限增长。
    await db.rawDelete(
      '''
      DELETE FROM $_historyTable WHERE id NOT IN (
        SELECT id FROM $_historyTable ORDER BY time DESC LIMIT ?
      )
      ''',
      [keep],
    );
  }

  /// 读取同步历史，按时间倒序（最新在前）。
  Future<List<SyncHistoryEntry>> loadSyncHistory() async {
    final db = await _database;
    final rows = await db.query(_historyTable, orderBy: 'time DESC');
    return [
      for (final row in rows)
        SyncHistoryEntry(
          id: row['id'] as String,
          time: DateTime.fromMillisecondsSinceEpoch(row['time'] as int),
          source: _sourceFromName(row['source'] as String?),
          mode: row['mode'] as String,
          itemCount: (row['item_count'] as num).toInt(),
          snapshot: HealthDailySummary.fromRow(
            (jsonDecode(row['snapshot'] as String) as Map)
                .cast<String, Object?>(),
          ),
          elapsed: Duration(milliseconds: (row['elapsed_ms'] as num).toInt()),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // 元数据（上次同步时间等）
  // ---------------------------------------------------------------------------

  Future<void> setLastSyncTime(DateTime time) async {
    final db = await _database;
    await db.insert(_metaTable, {
      'key': _metaLastSyncKey,
      'value': time.millisecondsSinceEpoch.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> lastSyncTime() async {
    final db = await _database;
    final rows = await db.query(
      _metaTable,
      where: 'key = ?',
      whereArgs: [_metaLastSyncKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = int.tryParse(rows.first['value'] as String? ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  HealthSyncSource _sourceFromName(String? name) {
    return HealthSyncSource.values.firstWhere(
      (s) => s.name == name,
      orElse: () => HealthSyncSource.appleHealth,
    );
  }
}
