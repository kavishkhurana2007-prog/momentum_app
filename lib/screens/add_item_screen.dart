import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/app_state.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  ItemType _type = ItemType.habit;
  Priority _priority = Priority.medium;
  DateTime? _due;
  TimeOfDay? _remindAt;
  DateTime? _baseline;

  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(() {
      setState(() {
        _canSave = _titleCtrl.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenTitle = 'New ${_type.name.substring(0, 1).toUpperCase()}${_type.name.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(screenTitle),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FormSection(
              child: SegmentedButton<ItemType>(
                segments: const [
                  ButtonSegment(value: ItemType.habit, label: Text('Habit'), icon: Icon(Icons.repeat)),
                  ButtonSegment(value: ItemType.todo, label: Text('Todo'), icon: Icon(Icons.check_box_outlined)),
                  ButtonSegment(value: ItemType.daySince, label: Text('Day Since'), icon: Icon(Icons.timelapse)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            _FormSection(
              title: 'Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Title cannot be empty' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(labelText: "Note (optional)"),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            _buildSchedulingSection(),
            _FormSection(
              title: 'Priority',
              child: DropdownButtonFormField<Priority>(
                value: _priority,
                items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _priority = v ?? Priority.medium),
                decoration: const InputDecoration(border: UnderlineInputBorder()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    switch (_type) {
      case ItemType.habit:
        return _FormSection(title: 'Scheduling', child: _reminderPicker());
      case ItemType.todo:
        return _FormSection(title: 'Scheduling', child: Column(children: [_duePicker(), const SizedBox(height: 16), _reminderPicker()]));
      case ItemType.daySince:
        return _FormSection(title: 'Start Date', child: _baselinePicker());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _duePicker() {
    return _DateTimePickerTile(
      icon: Icons.calendar_today,
      label: 'Due Date',
      value: _due != null ? DateFormat.yMMMd().add_jm().format(_due!) : 'Not set',
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365 * 5)), initialDate: _due ?? now);
        if (date == null) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due ?? now));
        if (time == null) return;
        setState(() => _due = DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      onClear: _due != null ? () => setState(() => _due = null) : null,
    );
  }

  Widget _reminderPicker() {
    return _DateTimePickerTile(
      icon: Icons.alarm,
      label: 'Daily Reminder',
      value: _remindAt?.format(context) ?? 'Off',
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: _remindAt ?? TimeOfDay.now());
        if (t != null) setState(() => _remindAt = t);
      },
      onClear: _remindAt != null ? () => setState(() => _remindAt = null) : null,
    );
  }

  Widget _baselinePicker() {
    return _DateTimePickerTile(
      icon: Icons.event,
      label: 'Start Date',
      value: _baseline != null ? DateFormat.yMMMd().format(_baseline!) : 'Select a date',
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(context: context, firstDate: now.subtract(const Duration(days: 3650)), lastDate: now, initialDate: _baseline ?? now);
        if (d != null) setState(() => _baseline = d);
      },
    );
  }

  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final title = _titleCtrl.text.trim();
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      final app = context.read<AppState>();

      ItemModel newItem;
      switch (_type) {
        case ItemType.habit:
          newItem = ItemModel.habit(title, color: Colors.indigo).copyWith(note: note, remindAt: _remindAt, priority: _priority);
          break;
        case ItemType.todo:
          newItem = ItemModel.todo(title, due: _due).copyWith(note: note, remindAt: _remindAt, priority: _priority);
          break;
        case ItemType.daySince:
          newItem = ItemModel.daySince(title, baseline: _baseline ?? DateTime.now());
          break;
      }
      
      await app.add(newItem);
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save item.')),
      );
    } finally {
      
      if (mounted) Navigator.pop(context);
    }
  }
}


class _FormSection extends StatelessWidget {
  final String? title;
  final Widget child;
  const _FormSection({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          if (title != null) const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimePickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              if (onClear != null)
                IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: onClear, tooltip: 'Clear selection')
              else
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}