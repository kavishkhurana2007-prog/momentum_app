import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  late bool _syncEnabled;

  @override
  void initState() {
    super.initState();
    _syncEnabled = SyncService.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          _SettingsSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: app.darkMode,
                onChanged: (v) => app.setTheme(dark: v, accentColor: app.accent),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Accent Color', style: theme.textTheme.bodyLarge),
              ),
              const SizedBox(height: 12),
              
              _AccentColorPicker(
                selectedColor: app.accent,
                onColorSelected: (color) => app.setTheme(dark: app.darkMode, accentColor: color),
              ),
            ],
          ),
          
         
          _SettingsSection(
            title: 'Data & Sync',
            children: [
              SwitchListTile(
                title: const Text("Enable Cloud Sync"),
                subtitle: const Text("Back up and sync across devices using Firebase."),
                value: _syncEnabled,
                
                onChanged: (v) {
                  setState(() => _syncEnabled = v);
                  SyncService.enabled = v;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(v ? 'Cloud Sync Enabled' : 'Cloud Sync Disabled'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}


class _AccentColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  
  
  static final List<Color> _colors = [
    Colors.deepPurple, Colors.blue, Colors.teal, Colors.green, 
    Colors.orange, Colors.redAccent, Colors.pink,
  ];

  const _AccentColorPicker({required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _colors.map((color) {
          final isSelected = color.value == selectedColor.value;
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2) : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}