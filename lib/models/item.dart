import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum ItemType { habit, todo, daySince }

enum Priority { low, medium, high }

class AppCategory {
  final String id;
  final String name;
  final int color;
  AppCategory({required this.id, required this.name, required this.color});

  factory AppCategory.basic(String name, Color color) =>
      AppCategory(id: const Uuid().v4(), name: name, color: color.value);
}

class ItemModel {
  final String id;
  final ItemType type;
  String title;
  String? note;
  DateTime createdAt;
  DateTime? due; // for todos (and optional for habits)
  bool completed; // for todos
  // Habits
  bool isDaily;
  int streak; // consecutive days
  Set<String> history; // yyyy-MM-dd dates completed
  // Common
  Priority priority;
  String? categoryId;
  int color; // accent color
  // Reminders
  TimeOfDay? remindAt;
  String? remindMessage;
  // Day Since baseline
  DateTime? baseline; // the date from which to count days since

  ItemModel({
    required this.id,
    required this.type,
    required this.title,
    this.note,
    required this.createdAt,
    this.due,
    this.completed = false,
    this.isDaily = false,
    this.streak = 0,
    Set<String>? history,
    this.priority = Priority.medium,
    this.categoryId,
    required this.color,
    this.remindAt,
    this.remindMessage,
    this.baseline,
  }) : history = history ?? <String>{};

  factory ItemModel.habit(String title, {Color color = Colors.indigo}) => ItemModel(
    id: const Uuid().v4(),
    type: ItemType.habit,
    title: title,
    createdAt: DateTime.now(),
    isDaily: true,
    color: color.value,
  );

  factory ItemModel.todo(String title, {DateTime? due, Color color = Colors.teal}) => ItemModel(
    id: const Uuid().v4(),
    type: ItemType.todo,
    title: title,
    createdAt: DateTime.now(),
    due: due,
    color: color.value,
  );

  factory ItemModel.daySince(String title, {DateTime? baseline, Color color = Colors.orange}) => ItemModel(
    id: const Uuid().v4(),
    type: ItemType.daySince,
    title: title,
    createdAt: DateTime.now(),
    baseline: baseline ?? DateTime.now(),
    color: color.value,
  );

  String get dateKeyToday => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool get isOverdue =>
      type == ItemType.todo && !completed && due != null && due!.isBefore(DateTime.now());

  int get daysSince => type == ItemType.daySince && baseline != null
      ? DateTime.now().difference(DateTime(baseline!.year, baseline!.month, baseline!.day)).inDays
      : 0;

  ItemModel copyWith({
    String? title,
    String? note,
    DateTime? due,
    bool? completed,
    bool? isDaily,
    int? streak,
    Set<String>? history,
    Priority? priority,
    String? categoryId,
    int? color,
    TimeOfDay? remindAt,
    String? remindMessage,
    DateTime? baseline,
  }) => ItemModel(
    id: id,
    type: type,
    title: title ?? this.title,
    note: note ?? this.note,
    createdAt: createdAt,
    due: due ?? this.due,
    completed: completed ?? this.completed,
    isDaily: isDaily ?? this.isDaily,
    streak: streak ?? this.streak,
    history: history ?? this.history,
    priority: priority ?? this.priority,
    categoryId: categoryId ?? this.categoryId,
    color: color ?? this.color,
    remindAt: remindAt ?? this.remindAt,
    remindMessage: remindMessage ?? this.remindMessage,
    baseline: baseline ?? this.baseline,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'due': due?.toIso8601String(),
    'completed': completed,
    'isDaily': isDaily,
    'streak': streak,
    'history': history.toList(),
    'priority': priority.name,
    'categoryId': categoryId,
    'color': color,
    'remindAt': remindAt != null ? {'h': remindAt!.hour, 'm': remindAt!.minute} : null,
    'remindMessage': remindMessage,
    'baseline': baseline?.toIso8601String(),
  };

  static ItemModel fromJson(Map<String, dynamic> j) => ItemModel(
    id: j['id'],
    type: ItemType.values.firstWhere((e) => e.name == j['type']),
    title: j['title'],
    note: j['note'],
    createdAt: DateTime.parse(j['createdAt']),
    due: j['due'] != null ? DateTime.parse(j['due']) : null,
    completed: j['completed'] ?? false,
    isDaily: j['isDaily'] ?? false,
    streak: j['streak'] ?? 0,
    history: Set<String>.from(j['history'] ?? []),
    priority: Priority.values.firstWhere((e) => e.name == (j['priority'] ?? 'medium')),
    categoryId: j['categoryId'],
    color: j['color'] ?? Colors.indigo.value,
    remindAt: j['remindAt'] != null ? TimeOfDay(hour: j['remindAt']['h'], minute: j['remindAt']['m']) : null,
    remindMessage: j['remindMessage'],
    baseline: j['baseline'] != null ? DateTime.parse(j['baseline']) : null,
  );
}
