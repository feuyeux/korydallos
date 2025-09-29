import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/effect_tokens.dart';
import '../tokens/elevation_tokens.dart';

/// Widget for configuring theme settings
class ThemeConfigurationWidget extends StatefulWidget {
  const ThemeConfigurationWidget({
    super.key,
    this.onThemeChanged,
  });

  final VoidCallback? onThemeChanged;

  @override
  State<ThemeConfigurationWidget> createState() => _ThemeConfigurationWidgetState();
}

class _ThemeConfigurationWidgetState extends State<ThemeConfigurationWidget> {
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Theme Settings',
                  style: TypographyTokens.titleMediumStyle,
                ),
                const SizedBox(height: SpacingTokens.l),
                _buildThemeModeSelector(),
                const SizedBox(height: SpacingTokens.l),
                _buildCustomColorToggle(),
                if (_themeService.useCustomColors) ...[
                  const SizedBox(height: SpacingTokens.l),
                  _buildColorPicker(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: TypographyTokens.labelLargeStyle,
        ),
        const SizedBox(height: SpacingTokens.s),
        SegmentedButton<AlouetteThemeMode>(
          segments: const [
            ButtonSegment(
              value: AlouetteThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: AlouetteThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: AlouetteThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_system_daydream),
            ),
          ],
          selected: {_themeService.themeMode},
          onSelectionChanged: (Set<AlouetteThemeMode> selection) {
            _themeService.setThemeMode(selection.first);
            widget.onThemeChanged?.call();
          },
        ),
      ],
    );
  }

  Widget _buildCustomColorToggle() {
    return SwitchListTile(
      title: Text(
        'Use Custom Colors',
        style: TypographyTokens.labelLargeStyle,
      ),
      subtitle: Text(
        'Enable custom primary color selection',
        style: TypographyTokens.bodySmallStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      value: _themeService.useCustomColors,
      onChanged: (bool value) {
        _themeService.setUseCustomColors(value);
        widget.onThemeChanged?.call();
      },
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Color',
          style: TypographyTokens.labelLargeStyle,
        ),
        const SizedBox(height: SpacingTokens.s),
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          children: [
            _buildColorOption(ColorTokens.blue500, 'Blue'),
            _buildColorOption(ColorTokens.green500, 'Green'),
            _buildColorOption(ColorTokens.amber500, 'Amber'),
            _buildColorOption(ColorTokens.red500, 'Red'),
            _buildColorOption(Colors.purple, 'Purple'),
            _buildColorOption(Colors.teal, 'Teal'),
            _buildColorOption(Colors.orange, 'Orange'),
            _buildColorOption(Colors.indigo, 'Indigo'),
          ],
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color, String name) {
    final isSelected = _themeService.customPrimaryColor == color;
    
    return GestureDetector(
      onTap: () {
        _themeService.setCustomPrimaryColor(color);
        widget.onThemeChanged?.call();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: EffectTokens.radiusSmall,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : null,
          boxShadow: isSelected ? ElevationTokens.shadowMedium : ElevationTokens.shadowSubtle,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: DimensionTokens.iconL,
              )
            : null,
      ),
    );
  }
}

/// Simplified theme switcher for app bars or quick access
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({
    super.key,
    this.onThemeChanged,
  });

  final VoidCallback? onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return PopupMenuButton<AlouetteThemeMode>(
          icon: Icon(_getThemeIcon(themeService.themeMode)),
          onSelected: (AlouetteThemeMode mode) {
            themeService.setThemeMode(mode);
            onThemeChanged?.call();
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: AlouetteThemeMode.light,
              child: ListTile(
                leading: Icon(Icons.light_mode),
                title: Text('Light Theme'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: AlouetteThemeMode.dark,
              child: ListTile(
                leading: Icon(Icons.dark_mode),
                title: Text('Dark Theme'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: AlouetteThemeMode.system,
              child: ListTile(
                leading: Icon(Icons.settings_system_daydream),
                title: Text('System Theme'),
                dense: true,
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getThemeIcon(AlouetteThemeMode mode) {
    switch (mode) {
      case AlouetteThemeMode.light:
        return Icons.light_mode;
      case AlouetteThemeMode.dark:
        return Icons.dark_mode;
      case AlouetteThemeMode.system:
        return Icons.settings_system_daydream;
    }
  }
}

/// Theme provider widget that wraps the app with theme management
class AlouetteThemeProvider extends StatefulWidget {
  const AlouetteThemeProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlouetteThemeProvider> createState() => _AlouetteThemeProviderState();
}

class _AlouetteThemeProviderState extends State<AlouetteThemeProvider> {
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return MaterialApp(
          theme: _themeService.getLightTheme(),
          darkTheme: _themeService.getDarkTheme(),
          themeMode: _getThemeMode(),
          home: widget.child,
        );
      },
    );
  }

  ThemeMode _getThemeMode() {
    switch (_themeService.themeMode) {
      case AlouetteThemeMode.light:
        return ThemeMode.light;
      case AlouetteThemeMode.dark:
        return ThemeMode.dark;
      case AlouetteThemeMode.system:
        return ThemeMode.system;
    }
  }
}