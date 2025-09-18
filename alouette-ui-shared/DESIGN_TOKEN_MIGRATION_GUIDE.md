# Design Token Migration Guide

This guide explains how to migrate from hardcoded values to the new design token system in Alouette applications.

## Overview

The design token system provides a centralized way to manage colors, typography, spacing, animations, and other design properties across all Alouette applications. This ensures consistency and makes it easy to update the design system.

## Design Token Categories

### 1. Color Tokens (`ColorTokens`)

Replace hardcoded colors with semantic color tokens:

```dart
// ❌ Before (hardcoded)
Container(
  color: Color(0xFF3B82F6),
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.white),
  ),
)

// ✅ After (design tokens)
Container(
  color: ColorTokens.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: ColorTokens.onPrimary),
  ),
)
```

**Available Color Categories:**
- Primary colors: `ColorTokens.primary`, `ColorTokens.onPrimary`, `ColorTokens.primaryContainer`
- Secondary colors: `ColorTokens.secondary`, `ColorTokens.onSecondary`, `ColorTokens.secondaryContainer`
- Surface colors: `ColorTokens.surface`, `ColorTokens.onSurface`, `ColorTokens.surfaceVariant`
- Functional colors: `ColorTokens.success`, `ColorTokens.warning`, `ColorTokens.error`
- Neutral colors: `ColorTokens.gray50` through `ColorTokens.gray900`

### 2. Typography Tokens (`TypographyTokens`)

Replace custom text styles with predefined typography tokens:

```dart
// ❌ Before (hardcoded)
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  ),
)

// ✅ After (design tokens)
Text(
  'Title',
  style: TypographyTokens.headlineSmallStyle,
)
```

**Available Typography Styles:**
- Display: `displayLargeStyle`, `displayMediumStyle`, `displaySmallStyle`
- Headline: `headlineLargeStyle`, `headlineMediumStyle`, `headlineSmallStyle`
- Title: `titleLargeStyle`, `titleMediumStyle`, `titleSmallStyle`
- Body: `bodyLargeStyle`, `bodyMediumStyle`, `bodySmallStyle`
- Label: `labelLargeStyle`, `labelMediumStyle`, `labelSmallStyle`

### 3. Spacing Tokens (`SpacingTokens`)

Replace hardcoded padding and margin values:

```dart
// ❌ Before (hardcoded)
Padding(
  padding: EdgeInsets.all(16.0),
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: 8.0),
      Widget2(),
    ],
  ),
)

// ✅ After (design tokens)
Padding(
  padding: EdgeInsets.all(SpacingTokens.l),
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: SpacingTokens.s),
      Widget2(),
    ],
  ),
)
```

**Available Spacing Values:**
- `SpacingTokens.xxs` (2px)
- `SpacingTokens.xs` (4px)
- `SpacingTokens.s` (8px)
- `SpacingTokens.m` (12px)
- `SpacingTokens.l` (16px)
- `SpacingTokens.xl` (20px)
- `SpacingTokens.xxl` (24px)
- `SpacingTokens.xxxl` (32px)

### 4. Dimension Tokens (`DimensionTokens`)

Replace hardcoded sizes with dimension tokens:

```dart
// ❌ Before (hardcoded)
Container(
  width: 56.0,
  height: 40.0,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8.0),
  ),
)

// ✅ After (design tokens)
Container(
  width: DimensionTokens.buttonMinWidth,
  height: DimensionTokens.buttonL,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
  ),
)
```

### 5. Motion Tokens (`MotionTokens`)

Replace hardcoded animation durations and curves:

```dart
// ❌ Before (hardcoded)
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  // ...
)

// ✅ After (design tokens)
AnimatedContainer(
  duration: MotionTokens.fast,
  curve: MotionTokens.standard,
  // ...
)
```

### 6. Elevation Tokens (`ElevationTokens`)

Replace hardcoded shadows with elevation tokens:

```dart
// ❌ Before (hardcoded)
Container(
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        offset: Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  ),
)

// ✅ After (design tokens)
Container(
  decoration: BoxDecoration(
    boxShadow: ElevationTokens.shadowLow,
  ),
)
```

### 7. Effect Tokens (`EffectTokens`)

Replace hardcoded decorations with effect tokens:

```dart
// ❌ Before (hardcoded)
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ),
    borderRadius: BorderRadius.circular(8.0),
  ),
)

// ✅ After (design tokens)
Container(
  decoration: BoxDecoration(
    gradient: EffectTokens.primaryGradient,
    borderRadius: EffectTokens.radiusMedium,
  ),
)
```

## Theme Management

### Using ThemeService

The `ThemeService` provides advanced theme management capabilities:

```dart
// Initialize theme service
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
  // ...
)
```

### Theme Configuration Widget

Add theme switching to your app:

```dart
// Simple theme switcher in app bar
AppBar(
  actions: [
    ThemeSwitcher(
      onThemeChanged: () {
        // Handle theme change
      },
    ),
  ],
)

// Full theme configuration panel
ThemeConfigurationWidget(
  onThemeChanged: () {
    // Handle theme change
  },
)
```

### Accessing Custom Theme Colors

Access additional colors through theme extensions:

```dart
// Get custom theme colors
final customColors = Theme.of(context).alouetteColors;

Container(
  color: customColors.success,
  child: Text(
    'Success message',
    style: TextStyle(color: customColors.onSuccess),
  ),
)
```

## Migration Steps

### Step 1: Update Imports

Add design token imports to your files:

```dart
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

// Or import specific tokens
import 'package:alouette_ui_shared/src/tokens/color_tokens.dart';
import 'package:alouette_ui_shared/src/tokens/typography_tokens.dart';
import 'package:alouette_ui_shared/src/tokens/dimension_tokens.dart';
```

### Step 2: Replace Hardcoded Values

Go through your widgets and replace hardcoded values:

1. **Colors**: Replace `Color(0x...)` with `ColorTokens.*`
2. **Text Styles**: Replace custom `TextStyle` with `TypographyTokens.*Style`
3. **Spacing**: Replace hardcoded padding/margin with `SpacingTokens.*`
4. **Sizes**: Replace hardcoded dimensions with `DimensionTokens.*`
5. **Animations**: Replace durations/curves with `MotionTokens.*`

### Step 3: Update Theme Usage

Replace direct theme usage with design tokens where appropriate:

```dart
// ❌ Before
Theme.of(context).primaryColor

// ✅ After
ColorTokens.primary
// or if you need theme-aware colors:
Theme.of(context).colorScheme.primary
```

### Step 4: Test Theme Switching

Ensure your widgets work correctly with both light and dark themes:

```dart
// Test with different theme modes
ThemeService().setThemeMode(AlouetteThemeMode.light);
ThemeService().setThemeMode(AlouetteThemeMode.dark);
ThemeService().setThemeMode(AlouetteThemeMode.system);
```

## Best Practices

### 1. Use Semantic Colors

Prefer semantic color names over specific color values:

```dart
// ✅ Good - semantic meaning
ColorTokens.error
ColorTokens.success
ColorTokens.warning

// ❌ Avoid - specific color values
ColorTokens.red500
ColorTokens.green500
ColorTokens.yellow500
```

### 2. Consistent Spacing

Use the spacing scale consistently:

```dart
// ✅ Good - consistent spacing
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

### 3. Appropriate Typography

Choose typography styles based on content hierarchy:

```dart
// ✅ Good - appropriate hierarchy
Column(
  children: [
    Text('Page Title', style: TypographyTokens.headlineLargeStyle),
    Text('Section Title', style: TypographyTokens.titleMediumStyle),
    Text('Body content...', style: TypographyTokens.bodyMediumStyle),
  ],
)
```

### 4. Consistent Animations

Use motion tokens for consistent animation timing:

```dart
// ✅ Good - consistent timing
AnimatedOpacity(
  duration: MotionTokens.fast,
  curve: MotionTokens.standard,
  opacity: isVisible ? 1.0 : 0.0,
  child: widget,
)
```

## Common Patterns

### Card with Design Tokens

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
          'Card content goes here...',
          style: TypographyTokens.bodyMediumStyle,
        ),
      ],
    ),
  ),
)
```

### Button with Design Tokens

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: ColorTokens.primary,
    foregroundColor: ColorTokens.onPrimary,
    padding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.xl,
      vertical: SpacingTokens.m,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: EffectTokens.radiusMedium,
    ),
    elevation: ElevationTokens.level1,
  ),
  onPressed: onPressed,
  child: Text(
    'Button Text',
    style: TypographyTokens.labelLargeStyle,
  ),
)
```

### Input Field with Design Tokens

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    labelStyle: TypographyTokens.bodyMediumStyle.copyWith(
      color: ColorTokens.onSurfaceVariant,
    ),
    border: OutlineInputBorder(
      borderRadius: EffectTokens.radiusMedium,
      borderSide: EffectTokens.borderDefault,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: EffectTokens.radiusMedium,
      borderSide: EffectTokens.borderPrimaryThick,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.l,
      vertical: SpacingTokens.m,
    ),
    filled: true,
    fillColor: ColorTokens.surfaceVariant,
  ),
)
```

## Troubleshooting

### Theme Not Updating

If theme changes aren't reflected:

1. Ensure you're using `ListenableBuilder` with `ThemeService`
2. Check that you're using the correct theme mode
3. Verify that widgets are using design tokens, not hardcoded values

### Colors Look Wrong

If colors don't match the design:

1. Check if you're using the correct semantic color
2. Verify light/dark theme compatibility
3. Ensure you're not mixing hardcoded colors with design tokens

### Inconsistent Spacing

If spacing looks inconsistent:

1. Use the spacing scale consistently
2. Avoid mixing hardcoded values with spacing tokens
3. Check that you're using appropriate spacing for the context

## Resources

- [Design Token Showcase Widget](./lib/src/widgets/design_token_showcase.dart) - Interactive demo of all design tokens
- [Theme Configuration Widget](./lib/src/widgets/theme_configuration_widget.dart) - Theme switching UI
- [Color Tokens](./lib/src/tokens/color_tokens.dart) - All available colors
- [Typography Tokens](./lib/src/tokens/typography_tokens.dart) - Text styles
- [Spacing & Dimension Tokens](./lib/src/tokens/dimension_tokens.dart) - Sizes and spacing