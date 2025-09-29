import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import 'atomic_elements.dart';

/// Alouette Button Component
///
/// Consolidated button component that replaces ModernButton and provides
/// consistent button styling across all Alouette applications.
/// Follows Material Design 3 principles with custom design tokens.
class AlouetteButton extends AtomicWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AlouetteButtonVariant variant;
  final AlouetteButtonSize size;
  final IconData? icon;
  final AlouetteButtonIconPosition iconPosition;
  final bool isLoading;
  final bool fullWidth;
  final Color? customColor;

  const AlouetteButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = AlouetteButtonVariant.primary,
    this.size = AlouetteButtonSize.medium,
    this.icon,
    this.iconPosition = AlouetteButtonIconPosition.leading,
    this.isLoading = false,
    this.fullWidth = false,
    this.customColor,
  }) : assert(text != null || child != null,
            'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);
    final isEnabled = onPressed != null && !isLoading;

    // Build button content
    Widget content = _buildContent(context);

    // Wrap with loading indicator if needed
    if (isLoading) {
      content = _buildLoadingContent(context);
    }

    // Build the appropriate button type
    Widget button = _buildButton(context, content, colorScheme, isEnabled);

    // Apply full width if needed
    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context) {
    if (child != null) return child!;

    final hasIcon = icon != null;
    final hasText = text != null;

    if (!hasIcon && !hasText) {
      throw ArgumentError('Button must have either icon or text');
    }

    if (hasIcon && !hasText) {
      // Icon-only button
      return AtomicIcon(
        icon!,
        size: size.iconSize,
      );
    }

    if (!hasIcon && hasText) {
      // Text-only button
      return AtomicText(
        text!,
        variant: size.textVariant,
      );
    }

    // Icon + text button
    final iconWidget = AtomicIcon(
      icon!,
      size: size.iconSize,
    );

    final textWidget = AtomicText(
      text!,
      variant: size.textVariant,
    );

    final spacing = SizedBox(width: SpacingTokens.xs);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconPosition == AlouetteButtonIconPosition.leading
          ? [iconWidget, spacing, textWidget]
          : [textWidget, spacing, iconWidget],
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return SizedBox(
      width: size.iconSize.value,
      height: size.iconSize.value,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          variant.getContentColor(getColorScheme(context), customColor),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    Widget content,
    ColorScheme colorScheme,
    bool isEnabled,
  ) {
    final style = _buildButtonStyle(colorScheme, isEnabled);

    switch (variant) {
      case AlouetteButtonVariant.primary:
        return FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AlouetteButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AlouetteButtonVariant.tertiary:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AlouetteButtonVariant.destructive:
        return FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
    }
  }

  ButtonStyle _buildButtonStyle(ColorScheme colorScheme, bool isEnabled) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(DimensionTokens.buttonMinWidth, size.height),
      ),
      padding: WidgetStateProperty.all(size.padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant
              .getBackgroundColor(colorScheme, customColor)
              .withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return variant
              .getBackgroundColor(colorScheme, customColor)
              .withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return variant
              .getBackgroundColor(colorScheme, customColor)
              .withValues(alpha: 0.12);
        }
        return variant.getBackgroundColor(colorScheme, customColor);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant.getContentColor(colorScheme, customColor).withValues(alpha: 0.38);
        }
        return variant.getContentColor(colorScheme, customColor);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return variant.getContentColor(colorScheme, customColor).withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return variant.getContentColor(colorScheme, customColor).withValues(alpha: 0.12);
        }
        return null;
      }),
      animationDuration: MotionTokens.fast,
    );
  }
}

/// Button variant enumeration
enum AlouetteButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive;

  Color getBackgroundColor(ColorScheme colorScheme, Color? customColor) {
    switch (this) {
      case AlouetteButtonVariant.primary:
        return customColor ?? colorScheme.primary;
      case AlouetteButtonVariant.secondary:
        return Colors.transparent;
      case AlouetteButtonVariant.tertiary:
        return Colors.transparent;
      case AlouetteButtonVariant.destructive:
        return colorScheme.error;
    }
  }

  Color getContentColor(ColorScheme colorScheme, Color? customColor) {
    switch (this) {
      case AlouetteButtonVariant.primary:
        return customColor != null ? Colors.white : colorScheme.onPrimary;
      case AlouetteButtonVariant.secondary:
        return customColor ?? colorScheme.primary;
      case AlouetteButtonVariant.tertiary:
        return customColor ?? colorScheme.primary;
      case AlouetteButtonVariant.destructive:
        return colorScheme.onError;
    }
  }
}

/// Button size enumeration
enum AlouetteButtonSize {
  small(
    DimensionTokens.buttonS,
    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    AtomicIconSize.small,
    AtomicTextVariant.labelSmall,
  ),
  medium(
    DimensionTokens.buttonM,
    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    AtomicIconSize.medium,
    AtomicTextVariant.labelMedium,
  ),
  large(
    DimensionTokens.buttonL,
    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    AtomicIconSize.medium,
    AtomicTextVariant.labelLarge,
  );

  const AlouetteButtonSize(
      this.height, this.padding, this.iconSize, this.textVariant);

  final double height;
  final EdgeInsets padding;
  final AtomicIconSize iconSize;
  final AtomicTextVariant textVariant;
}

/// Button icon position enumeration
enum AlouetteButtonIconPosition { leading, trailing }