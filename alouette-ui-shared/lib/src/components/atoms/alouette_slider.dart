import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import 'atomic_elements.dart';

/// Alouette Slider Component
///
/// Provides consistent slider styling and behavior across all Alouette applications.
/// Consolidates functionality from CompactSlider and VolumeSlider components.
class AlouetteSlider extends AtomicWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final AlouetteSliderSize size;
  final bool showValue;
  final String Function(double)? valueFormatter;
  final bool isEnabled;

  const AlouetteSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.size = AlouetteSliderSize.medium,
    this.showValue = false,
    this.valueFormatter,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          _buildLabel(context),
          const AtomicSpacer(AtomicSpacing.xs),
        ],
        _buildSliderRow(context, colorScheme),
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AtomicText(
          labelText!,
          variant: AtomicTextVariant.labelMedium,
          color: getColorScheme(context).onSurface,
        ),
        if (showValue)
          AtomicText(
            valueFormatter?.call(value) ?? value.toStringAsFixed(2),
            variant: AtomicTextVariant.labelMedium,
            color: getColorScheme(context).onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildSliderRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        if (prefixIcon != null) ...[
          AtomicIcon(
            prefixIcon!,
            size: size.iconSize,
            color: isEnabled
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          ),
          const AtomicSpacer(
            AtomicSpacing.small,
            direction: AtomicSpacerDirection.horizontal,
          ),
        ],
        Expanded(
          child: SizedBox(
            height: size.height,
            child: SliderTheme(
              data: _buildSliderTheme(context, colorScheme),
              child: Slider(
                value: value.clamp(min, max),
                onChanged: isEnabled ? onChanged : null,
                onChangeStart: onChangeStart,
                onChangeEnd: onChangeEnd,
                min: min,
                max: max,
                divisions: divisions,
                label: label,
              ),
            ),
          ),
        ),
        if (suffixIcon != null) ...[
          const AtomicSpacer(
            AtomicSpacing.small,
            direction: AtomicSpacerDirection.horizontal,
          ),
          AtomicIcon(
            suffixIcon!,
            size: size.iconSize,
            color: isEnabled
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          ),
        ],
      ],
    );
  }

  SliderThemeData _buildSliderTheme(BuildContext context, ColorScheme colorScheme) {
    return SliderTheme.of(context).copyWith(
      trackHeight: size.trackHeight,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: size.thumbRadius,
        disabledThumbRadius: size.thumbRadius * 0.8,
      ),
      overlayShape: RoundSliderOverlayShape(
        overlayRadius: size.thumbRadius * 1.5,
      ),
      activeTrackColor: isEnabled
          ? colorScheme.primary
          : colorScheme.primary.withValues(alpha: 0.38),
      inactiveTrackColor: isEnabled
          ? colorScheme.outline.withValues(alpha: 0.24)
          : colorScheme.outline.withValues(alpha: 0.12),
      thumbColor: isEnabled
          ? colorScheme.primary
          : colorScheme.onSurface.withValues(alpha: 0.38),
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: TypographyTokens.labelSmallStyle.copyWith(
        color: colorScheme.onPrimary,
      ),
    );
  }
}

/// Slider size enumeration
enum AlouetteSliderSize {
  small(
    32.0,
    2.0,
    8.0,
    AtomicIconSize.small,
  ),
  medium(
    40.0,
    4.0,
    10.0,
    AtomicIconSize.medium,
  ),
  large(
    48.0,
    6.0,
    12.0,
    AtomicIconSize.medium,
  );

  const AlouetteSliderSize(
    this.height,
    this.trackHeight,
    this.thumbRadius,
    this.iconSize,
  );

  final double height;
  final double trackHeight;
  final double thumbRadius;
  final AtomicIconSize iconSize;
}