import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';

/// Base class for all atomic UI components
///
/// Provides common functionality and ensures consistent theming
/// across all atomic components in the design system.
abstract class AtomicWidget extends StatelessWidget {
  const AtomicWidget({super.key});

  /// Get the current theme colors
  ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Get the current text theme
  TextTheme getTextTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }
}

/// Atomic Icon Component
///
/// Provides consistent icon rendering with proper sizing and colors.
class AtomicIcon extends AtomicWidget {
  final IconData icon;
  final AtomicIconSize size;
  final Color? color;
  final String? semanticLabel;

  const AtomicIcon(
    this.icon, {
    super.key,
    this.size = AtomicIconSize.medium,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? getColorScheme(context).onSurface;

    return Icon(
      icon,
      size: size.value,
      color: iconColor,
      semanticLabel: semanticLabel,
    );
  }
}

/// Icon size enumeration for atomic icons
enum AtomicIconSize {
  small(DimensionTokens.iconS),
  medium(DimensionTokens.iconM),
  large(DimensionTokens.iconL),
  extraLarge(DimensionTokens.iconXl);

  const AtomicIconSize(this.value);
  final double value;
}

/// Atomic Text Component
///
/// Provides consistent text rendering with semantic styling.
class AtomicText extends AtomicWidget {
  final String text;
  final AtomicTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AtomicText(
    this.text, {
    super.key,
    this.variant = AtomicTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? getColorScheme(context).onSurface;

    return Text(
      text,
      style: variant.getStyle(context).copyWith(color: textColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Text variant enumeration for semantic text styling
enum AtomicTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  labelLarge,
  labelMedium,
  labelSmall,
  body,
  bodySmall,
  caption;

  TextStyle getStyle(BuildContext context) {
    switch (this) {
      case AtomicTextVariant.displayLarge:
        return TypographyTokens.displayLargeStyle;
      case AtomicTextVariant.displayMedium:
        return TypographyTokens.displayMediumStyle;
      case AtomicTextVariant.displaySmall:
        return TypographyTokens.displaySmallStyle;
      case AtomicTextVariant.headlineLarge:
        return TypographyTokens.headlineLargeStyle;
      case AtomicTextVariant.headlineMedium:
        return TypographyTokens.headlineMediumStyle;
      case AtomicTextVariant.headlineSmall:
        return TypographyTokens.headlineSmallStyle;
      case AtomicTextVariant.titleLarge:
        return TypographyTokens.titleLargeStyle;
      case AtomicTextVariant.titleMedium:
        return TypographyTokens.titleMediumStyle;
      case AtomicTextVariant.titleSmall:
        return TypographyTokens.titleSmallStyle;
      case AtomicTextVariant.labelLarge:
        return TypographyTokens.labelLargeStyle;
      case AtomicTextVariant.labelMedium:
        return TypographyTokens.labelMediumStyle;
      case AtomicTextVariant.labelSmall:
        return TypographyTokens.labelSmallStyle;
      case AtomicTextVariant.body:
        return TypographyTokens.bodyLargeStyle;
      case AtomicTextVariant.bodySmall:
        return TypographyTokens.bodySmallStyle;
      case AtomicTextVariant.caption:
        return TypographyTokens.captionStyle;
    }
  }
}

/// Atomic Spacer Component
///
/// Provides consistent spacing using design tokens.
class AtomicSpacer extends AtomicWidget {
  final AtomicSpacing spacing;
  final AtomicSpacerDirection direction;

  const AtomicSpacer(
    this.spacing, {
    super.key,
    this.direction = AtomicSpacerDirection.vertical,
  });

  @override
  Widget build(BuildContext context) {
    switch (direction) {
      case AtomicSpacerDirection.vertical:
        return SizedBox(height: spacing.value);
      case AtomicSpacerDirection.horizontal:
        return SizedBox(width: spacing.value);
    }
  }
}

/// Spacing enumeration using design tokens
enum AtomicSpacing {
  xs(SpacingTokens.xs),
  small(SpacingTokens.s),
  medium(SpacingTokens.m),
  large(SpacingTokens.l),
  xl(SpacingTokens.xl),
  xxl(SpacingTokens.xxl),
  xxxl(SpacingTokens.xxxl);

  const AtomicSpacing(this.value);
  final double value;
}

/// Spacer direction enumeration
enum AtomicSpacerDirection { vertical, horizontal }

/// Atomic Divider Component
///
/// Provides consistent visual separation between elements.
class AtomicDivider extends AtomicWidget {
  final AtomicDividerType type;
  final Color? color;
  final double? thickness;

  const AtomicDivider({
    super.key,
    this.type = AtomicDividerType.horizontal,
    this.color,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? getColorScheme(context).outline;
    final dividerThickness = thickness ?? 1.0;

    switch (type) {
      case AtomicDividerType.horizontal:
        return Divider(
          color: dividerColor,
          thickness: dividerThickness,
          height: dividerThickness,
        );
      case AtomicDividerType.vertical:
        return VerticalDivider(
          color: dividerColor,
          thickness: dividerThickness,
          width: dividerThickness,
        );
    }
  }
}

/// Divider type enumeration
enum AtomicDividerType { horizontal, vertical }
