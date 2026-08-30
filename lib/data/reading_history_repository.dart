import 'package:hive_flutter/hive_flutter.dart';

import '../models/reading_history_entry.dart';

/// 抽牌历史记录的本地存储 —— 用 Hive 存，不需要写 SQL、不需要 code-gen，
/// 每条记录直接存成 Map。调用前必须先 await [init]（在 main() 里做一次）。
class ReadingHistoryRepository {
  ReadingHistoryRepository._();

  /// 全局唯一实例——项目还没引入状态管理/依赖注入方案，先用单例简单直接地
  /// 让各个页面都能访问同一份历史记录。数据量小、没有并发写入的顾虑。
  static final instance = ReadingHistoryRepository._();

  static const _boxName = 'reading_history';

  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> addEntry(ReadingHistoryEntry entry) async {
    await _box!.put(entry.id, entry.toJson());
  }

  /// 按 id 取回单条记录——AI 解读生成完之后要用这条原始记录回填 [ReadingHistoryEntry.aiReading]。
  ReadingHistoryEntry? getEntry(String id) {
    final raw = _box!.get(id);
    if (raw == null) return null;
    return ReadingHistoryEntry.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> deleteEntry(String id) => _box!.delete(id);

  /// 按时间从新到旧排序返回全部历史记录。
  List<ReadingHistoryEntry> getAllEntries() {
    final entries = _box!.values
        .map(
          (raw) => ReadingHistoryEntry.fromJson(Map<String, dynamic>.from(raw)),
        )
        .toList();
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return entries;
  }
}
