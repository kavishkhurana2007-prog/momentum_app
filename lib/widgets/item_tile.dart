import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

IconData iconFor(ItemType type) {
  switch (type) {
    case ItemType.habit:
      return Icons.repeat;
    case ItemType.todo:
      return Icons.check_box_outlined;
    case ItemType.daySince:
      return Icons.timelapse;
  }
}

class ItemTile extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onCompleteHabit;
  final ValueChanged<bool?>? onToggleTodo;

  const ItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onCompleteHabit,
    this.onToggleTodo,
  });

  // HELPER: Determines the base color for each item type.
  Color _getBaseColor(ItemType type) {
    switch (type) {
      case ItemType.habit:
        return Colors.orange;
      case ItemType.todo:
        return Colors.blue;
      case ItemType.daySince:
        return Colors.green;
    }
  }

  // HELPER: Determines the background opacity based on priority.
  double _getOpacityForPriority(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 0.25; // Darkest shade
      case Priority.medium:
        return 0.15; // Medium shade
      case Priority.low:
        return 0.07; // Lightest shade
      default:
        return 0.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue;
    // Get the base color and the background opacity based on item type and priority.
    final baseColor = _getBaseColor(item.type);
    final backgroundOpacity = _getOpacityForPriority(item.priority);

    return Card(
      // The card's background is now determined by the priority gradient.
      color: baseColor.withOpacity(backgroundOpacity),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          // The leading icon's background is slightly more saturated for contrast.
          backgroundColor: baseColor.withOpacity(0.2),
          child: Icon(iconFor(item.type), color: baseColor),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: overdue ? Colors.red : null,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildTrailing(context),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    switch (item.type) {
      case ItemType.todo:
        return Checkbox(
          value: item.completed,
          onChanged: onToggleTodo,
        );
      case ItemType.habit:
        return IconButton(
          icon: const Icon(Icons.fireplace_outlined),
          tooltip: "Complete today (${item.streak})",
          onPressed: onCompleteHabit,
        );
      case ItemType.daySince:
        return Text(
          "${item.daysSince}d",
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
    }
  }

  Widget? _buildSubtitle(BuildContext context) {
    if (item.type == ItemType.todo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.due != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
              child: Text("Due: ${DateFormat.yMd().add_jm().format(item.due!)}"),
            ),
          Text("Priority: ${item.priority.name}"),
        ],
      );
    }

    final bits = <String>[];
    if (item.type == ItemType.habit) {
      bits.add("Streak: ${item.streak}");
      if (item.remindAt != null) {
        bits.add("⏰ ${item.remindAt!.format(context)}");
      }
    } else if (item.type == ItemType.daySince) {
      bits.add(
        "Since: ${item.baseline?.toLocal().toString().split(' ').first}",
      );
    }

    if (bits.isEmpty) return null;
    return Text(bits.join(" • "));
  }
}

