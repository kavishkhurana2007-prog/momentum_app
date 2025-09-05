import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart'; 

import '../providers/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();

    
    final entries = app.habitCompletionsOverTime().entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      
      body: entries.isEmpty
          ? const _EmptyHistoryState()
          : GroupedListView<MapEntry<DateTime, int>, DateTime>(
              elements: entries,
              
              groupBy: (entry) => DateTime(entry.key.year, entry.key.month),
              
              groupHeaderBuilder: (entry) => _buildGroupHeader(entry.key, theme),
              
              itemComparator: (a, b) => a.key.compareTo(b.key), 
              order: GroupedListOrder.DESC, 
              itemBuilder: (context, entry) {
                
                return _HistoryTimelineTile(
                  date: entry.key,
                  completions: entry.value,
                  isFirst: entries.first == entry,
                  isLast: entries.last == entry,
                );
              },
            ),
    );
  }

  
  Widget _buildGroupHeader(DateTime date, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        DateFormat('MMMM yyyy').format(date),
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}


class _HistoryTimelineTile extends StatelessWidget {
  final DateTime date;
  final int completions;
  final bool isFirst;
  final bool isLast;

  const _HistoryTimelineTile({
    required this.date,
    required this.completions,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          _buildTimelineConnector(theme),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d').format(date), 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completions habit${completions > 1 ? 's' : ''} completed',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Icon(Icons.check_circle, color: theme.colorScheme.primary.withOpacity(0.7)),
            ),
          )
        ],
      ),
    );
  }

 
  Widget _buildTimelineConnector(ThemeData theme) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          
          Expanded(child: Container(width: 2, color: isFirst ? Colors.transparent : theme.dividerColor)),
          Icon(Icons.circle, size: 12, color: theme.colorScheme.primary),
          
          Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : theme.dividerColor)),
        ],
      ),
    );
  }
}


class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No History Yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some habits to see your progress here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}