import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/item.dart';
import '../widgets/item_tile.dart';
import 'add_item_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HabitListPage(),
    AnalyticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    
    final brightness = Theme.of(context).brightness;

    
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          
          systemOverlayStyle: SystemUiOverlayStyle(
            
            statusBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
            statusBarColor: Colors.transparent, 
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: _AppBarTitle(selectedIndex: _selectedIndex),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: "AI Time Blocking",
              onPressed: () => _showAiTimeBlocks(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: "Settings",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
          
          bottom: _selectedIndex == 0
              ? const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Habits'),
                    Tab(text: 'Todos'),
                    Tab(text: 'Day Since'),
                  ],
                )
              : null,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemScreen()),
                ),
                tooltip: 'Add Item',
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  void _showAiTimeBlocks(BuildContext context) {
    final app = context.read<AppState>();
    final blocks = app.aiTimeBlocksForToday();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Suggested Plan Today"),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final b in blocks)
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(b.title),
                  subtitle: Text("${b.start.format(context)} - ${b.end.format(context)}"),
                )
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }
}

class _AppBarTitle extends StatefulWidget {
  final int selectedIndex;
  const _AppBarTitle({required this.selectedIndex});

  @override
  State<_AppBarTitle> createState() => _AppBarTitleState();
}

class _AppBarTitleState extends State<_AppBarTitle> {
  Timer? _timer;
  late DateTime _now;

  static const List<String> _titles = ['Home', 'Analytics', 'History'];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.selectedIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM').format(_now),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('hh:mm:ss a').format(_now),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      );
    }
    return Text(_titles[widget.selectedIndex]);
  }
}


class _HabitListPage extends StatelessWidget {
  const _HabitListPage();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allItems = appState.items;

    final habits = allItems.where((i) => i.type == ItemType.habit).toList();
    final todos = allItems.where((i) => i.type == ItemType.todo).toList();
    final daySince = allItems.where((i) => i.type == ItemType.daySince).toList();

   
    return TabBarView(
      children: [
        _FilteredItemListView(items: allItems),
        _FilteredItemListView(items: habits),
        _FilteredItemListView(items: todos),
        _FilteredItemListView(items: daySince),
      ],
    );
  }
}


class _FilteredItemListView extends StatelessWidget {
  final List<ItemModel> items;

  const _FilteredItemListView({required this.items});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (items.isEmpty) {
      return const _EmptyState();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.lightImpact();
       
      },
      itemBuilder: (context, i) {
        final item = items[i];
        return Dismissible(
          key: ValueKey(item.id),
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => appState.remove(item.id),
          child: ItemTile(
            key: ValueKey(item.id),
            item: item,
            onToggleTodo: (v) => appState.toggleTodoComplete(item),
            onCompleteHabit: () => appState.completeHabitToday(item),
            onTap: () => _editItem(context, item),
          ),
        );
      },
    );
  }

  void _editItem(BuildContext context, ItemModel item) {
    final ctrl = TextEditingController(text: item.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Edit Item", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final app = context.read<AppState>();
                  final newTitle = ctrl.text.trim();
                  if (newTitle.isNotEmpty) {
                    app.update(item.copyWith(title: newTitle));
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'All clear!',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new habit or to-do to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

