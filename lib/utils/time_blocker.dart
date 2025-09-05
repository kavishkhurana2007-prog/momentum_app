import 'package:flutter/material.dart';
import '../models/item.dart';

class TimeBlock {
  final TimeOfDay start;
  final TimeOfDay end;
  final String title;
  TimeBlock({required this.start, required this.end, required this.title});
}

class TimeBlocker {
  /// Very simple heuristic AI time blocking:
  /// - User day: 7:00–22:00
  /// - Todos get blocks before their deadlines
  /// - Habits slot into remaining gaps
  static List<TimeBlock> suggestBlocks({required List<ItemModel> items}) {
    final start = const TimeOfDay(hour: 7, minute: 0);
    final end = const TimeOfDay(hour: 22, minute: 0);
    final blocks = <TimeBlock>[];

    // Collect relevant tasks for today
    final todos = items.where((i) => i.type == ItemType.todo && !i.completed).toList()
      ..sort((a,b) => (a.due ?? DateTime.now()).compareTo(b.due ?? DateTime.now()));
    final habits = items.where((i) => i.type == ItemType.habit).toList();

    TimeOfDay cursor = start;

    // Helper to advance cursor
    TimeOfDay addMinutes(TimeOfDay t, int m) {
      final minutes = t.hour*60 + t.minute + m;
      return TimeOfDay(hour: (minutes ~/ 60), minute: minutes % 60);
    }

    void push(String title, int minutes) {
      final s = cursor;
      final e = addMinutes(cursor, minutes);
      if (e.hour > end.hour || (e.hour==end.hour && e.minute>end.minute)) return;
      blocks.add(TimeBlock(start: s, end: e, title: title));
      cursor = addMinutes(cursor, minutes + 10); // small buffer
    }

    // Allocate todos: give 45 min per todo as a rough default
    for (final t in todos) {
      push("Todo: ${t.title}", 45);
    }

    // Fill remaining time with 20-min habit slots
    for (final h in habits) {
      push("Habit: ${h.title}", 20);
    }

    return blocks;
  }
}
