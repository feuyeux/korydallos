# Alouette Design Token System

A comprehensive design token system for consistent styling across all Alouette applications.

## Overview

The design token system provides a centralized way to manage design decisions like colors, typography, spacing, animations, and visual effects. This ensures consistency across all applications and makes it easy to update the design system.

## Features

- 🎨 **Comprehensive Color System** - Semantic colors with light/dark theme support
- 📝 **Typography Scale** - Consistent text styles following Material Design 3
- 📏 **Spacing & Dimensions** - Systematic sizing for consistent layouts
- 🎬 **Motion Tokens** - Standardized animation durations and curves
- 🌟 **Visual Effects** - Gradients, shadows, and decorative elements
- 🎛️ **Theme Management** - Advanced theme switching and customization
- 🔧 **Easy Migration** - Clear migration path from hardcoded values

## Quick Start

### 1. Import Design Tokens

```dart
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
```

### 2. Use Color Tokens

```dart
Container(
  color: ColorTokens.primary,
  child: Text(
    'Hello World',
    style: TextStyle(color: ColorTokens.onPrimary),
  ),
)
```

### 3. Apply Typography

```dart
Text(
  'Page Title',
  style: TypographyTokens.headlineLargeStyle,
)
```

### 4. Add Consistent Spacing

```dart
Padding(
  padding: EdgeInsets.all(SpacingTokens.l),
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: SpacingTokens.m),
      Widget2(),
    ],
  ),
)
```

## Design Token Categories

### Colors (`ColorTokens`)

Semantic color system with light and dark theme variants:

```dart
// Primary colors
ColorTokens.primary
ColorTokens.onPrimary
ColorTokens.primaryContainer
ColorTokens.onPrimaryContainer

// Surface colors
ColorTokens.surface
ColorTokens.onSurface
ColorTokens.surfaceVariant
ColorTokens.onSurfaceVariant

// Functional colors
ColorTokens.success
ColorTokens.warning
ColorTokens.error
ColorTokens.info
```

### Typography (`TypographyTokens`)

Material Design 3 typography scale:

```dart
// Display styles (large headings)
TypographyTokens.displayLargeStyle
TypographyTokens.displayMediumStyle
TypographyTokens.displaySmallStyle

// Headline styles (section headings)
TypographyTokens.headlineLargeStyle
TypographyTokens.headlineMediumStyle
TypographyTokens.headlineSmallStyle

// Body styles (main content)
TypographyTokens.bodyLargeStyle
TypographyTokens.bodyMediumStyle
TypographyTokens.bodySmallStyle
```

### Spacing (`SpacingTokens`)

4px-based spacing scale:

```dart
SpacingTokens.xxs  // 2px
SpacingTokens.xs   // 4px
SpacingTokens.s    // 8px
SpacingTokens.m    // 12px
SpacingTokens.l    // 16px
SpacingTokens.xl   // 20px
SpacingTokens.xxl  // 24px
SpacingTokens.xxxl // 32px
```

### Dimensions (`DimensionTokens`)

Component sizing tokens:

```dart
// Icons
DimensionTokens.iconS   // 16px
DimensionTokens.iconM   // 20px
DimensionTokens.iconL   // 24px

// Buttons
DimensionTokens.buttonS // 28px height
DimensionTokens.buttonM // 32px height
DimensionTokens.buttonL // 36px height

// Border radius
DimensionTokens.radiusS  // 4px
DimensionTokens.radiusM  // 6px
DimensionTokens.radiusL  // 8px
DimensionTokens.radiusXl // 12px
```

### Motion (`MotionTokens`)

Animation timing and curves:

```dart
// Durations
MotionTokens.fast     // 150ms
MotionTokens.normal   // 200ms
MotionTokens.moderate // 300ms
MotionTokens.slow     // 500ms

// Curves
MotionTokens.standard    // easeInOut
MotionTokens.emphasized  // easeInOutCubic
MotionTokens.decelerated // easeOut
MotionTokens.accelerated // easeIn
```

### Elevation (`ElevationTokens`)

Consistent shadow system:

```dart
ElevationTokens.shadowNone     // No shadow
ElevationTokens.shadowSubtle   // Level 1
ElevationTokens.shadowLow      // Level 2
ElevationTokens.shadowMedium   // Level 3
ElevationTokens.shadowHigh     // Level 4
ElevationTokens.shadowVeryHigh // Level 5
```

### Effects (`EffectTokens`)

Visual effects and decorations:

```dart
// Gradients
EffectTokens.primaryGradient
EffectTokens.secondaryGradient
EffectTokens.successGradient

// Border radius
EffectTokens.radiusSmall
EffectTokens.radiusMedium
EffectTokens.radiusLarge

// Borders
EffectTokens.borderDefault
EffectTokens.borderPrimary
EffectTokens.borderThick
```

## Theme Management

### ThemeService

Advanced theme management with customization:

```dart
final themeService = ThemeService();

// Set theme mode
themeService.setThemeMode(AlouetteThemeMode.dark);

// Enable custom colors
themeService.setUseCustomColors(true);
themeService.setCustomPrimaryColor(Colors.purple);

// Use in MaterialApp
MaterialApp(
  theme: themeService.getLightTheme(),
  darkTheme: themeService.getDarkTheme(),
  themeMode: _getThemeMode(themeService.themeMode),
)
```

### Theme Widgets

Ready-to-use theme switching components:

```dart
// Simple theme switcher
ThemeSwitcher(
  onThemeChanged: () {
    // Handle theme change
  },
)

// Full configuration panel
ThemeConfigurationWidget(
  onThemeChanged: () {
    // Handle theme change
  },
)

// Theme provider wrapper
AlouetteThemeProvider(
  child: MyApp(),
)
```

### Custom Theme Colors

Access additional colors through theme extensions:

```dart
final customColors = Theme.of(context).alouetteColors;

Container(
  color: customColors.success,
  child: Text(
    'Success message',
    style: TextStyle(color: customColors.onSuccess),
  ),
)
```

## Common Patterns

### Card Component

```dart
Card(
  elevation: ElevationTokens.level1,
  shape: RoundedRectangleBorder(
    borderRadius: EffectTokens.radiusLarge,
  ),
  child: Padding(
    padding: EdgeInsets.all(SpacingTokens.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Title',
          style: TypographyTokens.titleMediumStyle,
        ),
        SizedBox(height: SpacingTokens.s),
        Text(
          'Card content...',
          style: TypographyTokens.bodyMediumStyle,
        ),
      ],
    ),
  ),
)
```

### Custom Button

```dart
Container(
  decoration: BoxDecoration(
    gradient: EffectTokens.primaryGradient,
    borderRadius: EffectTokens.radiusMedium,
    boxShadow: ElevationTokens.shadowSubtle,
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: EffectTokens.radiusMedium,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.xl,
          vertical: SpacingTokens.m,
        ),
        child: Text(
          'Custom Button',
          style: TypographyTokens.labelLargeStyle.copyWith(
            color: ColorTokens.onPrimary,
          ),
        ),
      ),
    ),
  ),
)
```

### Animated Container

```dart
AnimatedContainer(
  duration: MotionTokens.normal,
  curve: MotionTokens.emphasized,
  width: isExpanded ? 200 : 100,
  height: DimensionTokens.buttonL,
  decoration: BoxDecoration(
    color: ColorTokens.primary,
    borderRadius: EffectTokens.radiusMedium,
    boxShadow: isHovered 
        ? ElevationTokens.shadowMedium 
        : ElevationTokens.shadowSubtle,
  ),
  child: Center(
    child: Text(
      'Animated',
      style: TypographyTokens.labelLargeStyle.copyWith(
        color: ColorTokens.onPrimary,
      ),
    ),
  ),
)
```

## Migration Guide

See [DESIGN_TOKEN_MIGRATION_GUIDE.md](./DESIGN_TOKEN_MIGRATION_GUIDE.md) for detailed migration instructions.

## Development Tools

### Design Token Showcase

Interactive demo of all design tokens:

```dart
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

// Show design token showcase
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DesignTokenShowcase(),
  ),
);
```

### Theme Testing

Test your widgets with different themes:

```dart
// Test light theme
ThemeService().setThemeMode(AlouetteThemeMode.light);

// Test dark theme
ThemeService().setThemeMode(AlouetteThemeMode.dark);

// Test custom colors
ThemeService().setUseCustomColors(true);
ThemeService().setCustomPrimaryColor(Colors.purple);
```

## Best Practices

### 1. Use Semantic Colors

```dart
// ✅ Good - semantic meaning
ColorTokens.error
ColorTokens.success
ColorTokens.primary

// ❌ Avoid - specific color values
ColorTokens.red500
ColorTokens.green500
ColorTokens.blue500
```

### 2. Consistent Typography Hierarchy

```dart
// ✅ Good - clear hierarchy
Text('Page Title', style: TypographyTokens.headlineLargeStyle)
Text('Section Title', style: TypographyTokens.titleMediumStyle)
Text('Body text', style: TypographyTokens.bodyMediumStyle)
```

### 3. Systematic Spacing

```dart
// ✅ Good - consistent spacing scale
Column(
  children: [
    Widget1(),
    SizedBox(height: SpacingTokens.l),
    Widget2(),
    SizedBox(height: SpacingTokens.l),
    Widget3(),
  ],
)
```

### 4. Appropriate Motion

```dart
// ✅ Good - appropriate timing for interaction
AnimatedOpacity(
  duration: MotionTokens.fast,
  curve: MotionTokens.standard,
  opacity: isVisible ? 1.0 : 0.0,
  child: widget,
)
```

## File Structure

```
lib/src/tokens/
├── app_tokens.dart          # Main export file
├── color_tokens.dart        # Color system
├── typography_tokens.dart   # Text styles
├── dimension_tokens.dart    # Spacing & sizing
├── motion_tokens.dart       # Animation timing
├── elevation_tokens.dart    # Shadow system
└── effect_tokens.dart       # Visual effects

lib/src/services/
└── theme_service.dart       # Theme management

lib/src/themes/
└── app_theme.dart          # Theme definitions

lib/src/widgets/
├── theme_configuration_widget.dart  # Theme UI
└── design_token_showcase.dart       # Development tool
```

## Contributing

When adding new design tokens:

1. Follow the existing naming conventions
2. Add both light and dark theme variants for colors
3. Include documentation and examples
4. Update the showcase widget
5. Add migration notes if needed

## Resources

- [Material Design 3 Guidelines](https://m3.material.io/)
- [Design Token Specification](https://design-tokens.github.io/community-group/)
- [Flutter Theme Documentation](https://docs.flutter.dev/cookbook/design/themes)