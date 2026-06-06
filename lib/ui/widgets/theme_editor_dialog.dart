import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../theme.dart';

class ThemeColorItem {
  final String name;
  final Color Function() getColor;
  final void Function(Color) setColor;

  ThemeColorItem(this.name, this.getColor, this.setColor);
}

class ThemeEditorDialog extends StatefulWidget {
  const ThemeEditorDialog({super.key});

  @override
  State<ThemeEditorDialog> createState() => _ThemeEditorDialogState();
}

class _ThemeEditorDialogState extends State<ThemeEditorDialog> {
  late List<ThemeColorItem> colorItems;

  @override
  void initState() {
    super.initState();
    _initColors();
  }

  void _initColors() {
    colorItems = [
      ThemeColorItem('Primary Color', () => AppTheme.primary, (c) => AppTheme.primary = c),
      ThemeColorItem('Secondary / Light Primary', () => AppTheme.primaryLight, (c) => AppTheme.primaryLight = c),
      ThemeColorItem('Safe (Success)', () => AppTheme.success, (c) => AppTheme.success = c),
      ThemeColorItem('Warning', () => AppTheme.warning, (c) => AppTheme.warning = c),
      ThemeColorItem('Error', () => AppTheme.error, (c) => AppTheme.error = c),
      ThemeColorItem('Card Background', () => AppTheme.cardBg, (c) => AppTheme.cardBg = c),
      ThemeColorItem('Card Border (Neutral)', () => AppTheme.neutralBorder, (c) => AppTheme.neutralBorder = c),
      ThemeColorItem('Text Primary', () => AppTheme.textPrimary, (c) => AppTheme.textPrimary = c),
      ThemeColorItem('Text Secondary', () => AppTheme.textSecondary, (c) => AppTheme.textSecondary = c),
      ThemeColorItem('Background Start', () => AppTheme.backgroundStart, (c) => AppTheme.backgroundStart = c),
      ThemeColorItem('Background End', () => AppTheme.backgroundEnd, (c) => AppTheme.backgroundEnd = c),
      ThemeColorItem('Terminal Background', () => AppTheme.surfaceDark, (c) => AppTheme.surfaceDark = c),
    ];
  }

  void _pickColor(ThemeColorItem item) {
    Color pickerColor = item.getColor();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text('Pick a color for \${item.name}', style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Got it', style: TextStyle(color: AppTheme.primary)),
              onPressed: () {
                setState(() {
                  item.setColor(pickerColor);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Theme Editor',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: colorItems.length,
                separatorBuilder: (_, __) => Divider(color: AppTheme.neutralBorder),
                itemBuilder: (context, index) {
                  final item = colorItems[index];
                  return ListTile(
                    title: Text(
                      item.name,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    trailing: GestureDetector(
                      onTap: () => _pickColor(item),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.getColor(),
                          border: Border.all(color: AppTheme.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                    onTap: () => _pickColor(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    await AppTheme.resetTheme();
                    if (context.mounted) {
                      _initColors(); // Rebuild the local state to reflect defaults
                      setState(() {});
                      Provider.of<AppState>(context, listen: false).refreshTheme();
                    }
                  },
                  child: Text('Reset to Defaults', style: TextStyle(color: AppTheme.error)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await AppTheme.saveTheme();
                        if (context.mounted) {
                          Provider.of<AppState>(context, listen: false).refreshTheme();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.white,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
