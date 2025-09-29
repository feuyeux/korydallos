import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import 'atomic_elements.dart';

/// Atomic Button Component
///
/// Provides consistent button styling and behavior across the application.
/// Follows Material Design 3 principles with custom design tokens.
class AtomicButton extends AtomicWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AtomicButtonVariant variant;
  final AtomicButtonSize size;
  final IconData? icon;
  final AtomicButtonIconPosition iconPosition;
  final bool isLoading;
  final bool fullWidth;

  const AtomicButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = AtomicButtonVariant.primary,
    this.size = AtomicButtonSize.medium,
    this.icon,
    this.iconPosition = AtomicButtonIconPosition.leading,
    this.isLoading = false,
    this.fullWidth = false,
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
      children: iconPosition == AtomicButtonIconPosition.leading
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
          variant.getContentColor(getColorScheme(context)),
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
      case AtomicButtonVariant.primary:
        return FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AtomicButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AtomicButtonVariant.tertiary:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AtomicButtonVariant.destructive:
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
              .getBackgroundColor(colorScheme)
              .withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return variant
              .getBackgroundColor(colorScheme)
              .withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return variant
              .getBackgroundColor(colorScheme)
              .withValues(alpha: 0.12);
        }
        return variant.getBackgroundColor(colorScheme);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant.getContentColor(colorScheme).withValues(alpha: 0.38);
        }
        return variant.getContentColor(colorScheme);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return variant.getContentColor(colorScheme).withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.pressed)) {
          return variant.getContentColor(colorScheme).withValues(alpha: 0.12);
        }
        return null;
      }),
      animationDuration: MotionTokens.fast,
    );
  }
}

/// Button variant enumeration
enum AtomicButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive;

  Color getBackgroundColor(ColorScheme colorScheme) {
    switch (this) {
      case AtomicButtonVariant.primary:
        return colorScheme.primary;
      case AtomicButtonVariant.secondary:
        return Colors.transparent;
      case AtomicButtonVariant.tertiary:
        return Colors.transparent;
      case AtomicButtonVariant.destructive:
        return colorScheme.error;
    }
  }

  Color getContentColor(ColorScheme colorScheme) {
    switch (this) {
      case AtomicButtonVariant.primary:
        return colorScheme.onPrimary;
      case AtomicButtonVariant.secondary:
        return colorScheme.primary;
      case AtomicButtonVariant.tertiary:
        return colorScheme.primary;
      case AtomicButtonVariant.destructive:
        return colorScheme.onError;
    }
  }
}

/// Button size enumeration
enum AtomicButtonSize {
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

  const AtomicButtonSize(
      this.height, this.padding, this.iconSize, this.textVariant);

  final double height;
  final EdgeInsets padding;
  final AtomicIconSize iconSize;
  final AtomicTextVariant textVariant;
}

/// Button icon position enumeration
enum AtomicButtonIconPosition { leading, trailing }
