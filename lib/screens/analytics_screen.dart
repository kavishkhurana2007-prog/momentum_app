import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}


enum TimePeriod { week, month, all }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();

    
    final habitEntries = app.habitCompletionsOverTime().entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    final todoRates = app.todoCompletionRates();
    final totalDone = todoRates['done'] ?? 0;
    final totalPending = todoRates['pending'] ?? 0;
    final totalTodos = totalDone + totalPending;
    final completionPercent = totalTodos == 0 ? 0 : (totalDone / totalTodos * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          SegmentedButton<TimePeriod>(
            segments: const [
              ButtonSegment(value: TimePeriod.week, label: Text('Week')),
              ButtonSegment(value: TimePeriod.month, label: Text('Month')),
              ButtonSegment(value: TimePeriod.all, label: Text('All Time')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (s) => setState(() => _selectedPeriod = s.first),
          ),
          const SizedBox(height: 24),
          
          
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Completion Rate', value: '${completionPercent.toStringAsFixed(0)}%')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Completed Todos', value: '$totalDone')),
            ],
          ),
          const SizedBox(height: 24),

          
          _AnalyticsCard(
            title: 'Habit Consistency',
            child: habitEntries.length < 2
                ? const _EmptyChartState(message: 'Complete habits for a few days to see your progress.')
                : _buildHabitConsistencyChart(habitEntries, theme),
          ),
          const SizedBox(height: 24),
          
          
          _AnalyticsCard(
            title: 'Todo Completion',
            child: totalTodos == 0
                ? const _EmptyChartState(message: 'No to-dos found.')
                : _buildTodoCompletionChart(totalDone.toDouble(), totalPending.toDouble(), theme),
          ),
        ],
      ),
    );
  }

  
  Widget _buildHabitConsistencyChart(List<MapEntry<DateTime, int>> entries, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (entries.length / 4).ceil().toDouble(), // Show ~4 labels
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < entries.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(DateFormat('d MMM').format(entries[index].key), style: theme.textTheme.bodySmall),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.left),
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (int i=0; i<entries.length; i++) FlSpot(i.toDouble(), entries[i].value.toDouble())],
              isCurved: true,
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary.withOpacity(0.3), theme.colorScheme.tertiary.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  
  Widget _buildTodoCompletionChart(double done, double pending, ThemeData theme) {
    final total = done + pending;
    final donePercent = total == 0 ? 0 : (done / total * 100);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: theme.colorScheme.primary,
                  value: done,
                  title: '${done.toInt()}',
                  radius: 60,
                  titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
                ),
                PieChartSectionData(
                  color: Colors.grey.shade300,
                  value: pending,
                  title: '${pending.toInt()}',
                  radius: 60,
                  titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
              
              centerSpaceRadius: 70,
              sectionsSpace: 2,
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${donePercent.toStringAsFixed(0)}%',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text('Done'),
            ],
          )
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _AnalyticsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}


class _EmptyChartState extends StatelessWidget {
  final String message;
  const _EmptyChartState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Not enough data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}