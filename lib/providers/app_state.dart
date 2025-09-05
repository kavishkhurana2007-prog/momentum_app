import 'dart:math';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/local_db.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/time_blocker.dart';

class AppState extends ChangeNotifier {
  List<ItemModel> items = [];
  bool darkMode = false;
  Color accent = Colors.indigo;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await LocalDB.init();
    await NotificationService.init();
    items = LocalDB.getAll();
    items.sort(_sorter);
    notifyListeners();
  }

  int _sorter(ItemModel a, ItemModel b) {
    // Auto sort: overdue first, then due time, then habits needing completion, then priority
    int overdueA = a.isOverdue ? 1 : 0;
    int overdueB = b.isOverdue ? 1 : 0;
    if (overdueA != overdueB) return overdueB - overdueA;
    if (a.due != null && b.due != null && a.due != b.due) {
      return a.due!.compareTo(b.due!);
    }
    if (a.type != b.type) {
      if (a.type == ItemType.habit && !a.history.contains(a.dateKeyToday)) return -1;
      if (b.type == ItemType.habit && !b.history.contains(b.dateKeyToday)) return 1;
    }
    return b.priority.index.compareTo(a.priority.index);
  }

  Future<void> add(ItemModel item) async {
    items.add(item);
    items.sort(_sorter);
    await LocalDB.upsert(item);
    await _maybeScheduleReminder(item);
    await SyncService.pushAll(items);
    notifyListeners();
  }

  Future<void> update(ItemModel item) async {
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      items[idx] = item;
      items.sort(_sorter);
      await LocalDB.upsert(item);
      await _maybeScheduleReminder(item);
      await SyncService.pushAll(items);
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    items.removeWhere((e) => e.id == id);
    await LocalDB.delete(id);
    await SyncService.pushAll(items);
    notifyListeners();
  }

  Future<void> toggleTodoComplete(ItemModel item) async {
    if (item.type != ItemType.todo) return;
    item = item.copyWith(completed: !item.completed);
    await update(item);
  }

  Future<void> completeHabitToday(ItemModel item) async {
    if (item.type != ItemType.habit) return;
    final today = item.dateKeyToday;
    if (!item.history.contains(today)) {
      final didYesterday = item.history.contains(_shiftDate(today, -1));
      item.history.add(today);
      item = item.copyWith(streak: didYesterday ? item.streak + 1 : 1);
      await update(item);
    }
  }

  String _shiftDate(String yyyyMmDd, int deltaDays) {
    final parts = yyyyMmDd.split('-').map(int.parse).toList();
    final d = DateTime(parts[0], parts[1], parts[2]).add(Duration(days: deltaDays));
    return "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
    }

  List<ItemModel> get habits => items.where((e) => e.type == ItemType.habit).toList();
  List<ItemModel> get todos => items.where((e) => e.type == ItemType.todo).toList();
  List<ItemModel> get daySince => items.where((e) => e.type == ItemType.daySince).toList();

  Map<DateTime, int> habitCompletionsOverTime() {
    final map = <DateTime, int>{};
    for (final h in habits) {
      for (final key in h.history) {
        final parts = key.split('-').map(int.parse).toList();
        final date = DateTime(parts[0], parts[1], parts[2]);
        map.update(date, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return map;
  }

  Map<String, int> todoCompletionRates() {
    int done = todos.where((t) => t.completed).length;
    int pending = todos.where((t) => !t.completed).length;
    return {'done': done, 'pending': pending};
  }

  List<TimeBlock> aiTimeBlocksForToday() {
    return TimeBlocker.suggestBlocks(items: items);
  }

  Future<void> _maybeScheduleReminder(ItemModel item) async {
    if (item.remindAt == null) return;
    final id = item.id.hashCode & 0x7fffffff;
    await NotificationService.cancel(id);
    await NotificationService.scheduleDaily(
      id,
      item.title,
      item.remindMessage ?? 'Time for "${item.title}"',
      item.remindAt!.hour,
      item.remindAt!.minute,
    );
  }

  void setTheme({required bool dark, required Color accentColor}) {
    darkMode = dark;
    accent = accentColor;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    notifyListeners();
  }
}
