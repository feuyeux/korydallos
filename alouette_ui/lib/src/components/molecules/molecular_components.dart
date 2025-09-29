import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/atomic_button.dart';
import '../atoms/atomic_input.dart';

/// Molecular Search Box Component
///
/// Combines an input field with a search button for search functionality.
class MolecularSearchBox extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool isLoading;
  final AtomicInputSize size;

  const MolecularSearchBox({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onSearch,
    this.onChanged,
    this.onClear,
    this.isLoading = false,
    this.size = AtomicInputSize.medium,
  });

  @override
  State<MolecularSearchBox> createState() => _MolecularSearchBoxState();
}

class _MolecularSearchBoxState extends State<MolecularSearchBox> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onSearch() {
    widget.onSearch?.call(_controller.text);
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AtomicInput(
      controller: _controller,
      hintText: widget.hintText,
      type: AtomicInputType.search,
      size: widget.size,
      prefixIcon: Icons.search,
      suffixIcon: widget.isLoading
          ? null
          : _hasText
              ? Icons.clear
              : null,
      onSuffixIconPressed: _hasText ? _onClear : null,
      onSubmitted: (_) => _onSearch(),
    );
  }
}

/// Molecular Language Chip Component
///
/// Displays a language option with flag, name, and selection state.
class MolecularLanguageChip extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String languageFlag;
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const MolecularLanguageChip({
    super.key,
    required this.languageCode,
    required this.languageName,
    required this.languageFlag,
    this.isSelected = false,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged?.call(!isSelected),
      borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageFlag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              languageName,
              style: TextStyle(
                fontSize: 14,
                color: isSelected 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Molecular Action Bar Component
///
/// Contains a set of action buttons for common operations.
class MolecularActionBar extends StatelessWidget {
  final List<MolecularActionBarItem> actions;
  final CrossAxisAlignment alignment;
  final double spacing;

  const MolecularActionBar({
    super.key,
    required this.actions,
    this.alignment = CrossAxisAlignment.end,
    this.spacing = SpacingTokens.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions
              .map((action) => action.toWidget())
              .expand((widget) => [
                    widget,
                    if (widget != actions.last.toWidget())
                      SizedBox(width: spacing),
                  ])
              .toList(),
        ),
      ],
    );
  }
}

/// Action bar item model
class MolecularActionBarItem {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AtomicButtonVariant variant;
  final AtomicButtonSize size;
  final bool isLoading;

  const MolecularActionBarItem({
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = AtomicButtonVariant.primary,
    this.size = AtomicButtonSize.medium,
    this.isLoading = false,
  });

  Widget toWidget() {
    return AtomicButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
    );
  }
}

/// Molecular Status Indicator Component
///
/// Shows status with icon, text, and optional action.
class MolecularStatusIndicator extends StatelessWidget {
  final MolecularStatusType status;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const MolecularStatusIndicator({
    super.key,
    required this.status,
    required this.message,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: status.getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        border: Border.all(
          color: status.getBorderColor(colorScheme),
        ),
      ),
      child: Row(
        children: [
          AtomicIcon(
            status.icon,
            size: AtomicIconSize.medium,
            color: status.getIconColor(colorScheme),
          ),
          const AtomicSpacer(
            AtomicSpacing.small,
            direction: AtomicSpacerDirection.horizontal,
          ),
          Expanded(
            child: AtomicText(
              message,
              variant: AtomicTextVariant.body,
              color: status.getTextColor(colorScheme),
            ),
          ),
          if (actionText != null && onActionPressed != null) ...[
            const AtomicSpacer(
              AtomicSpacing.small,
              direction: AtomicSpacerDirection.horizontal,
            ),
            AtomicButton(
              text: actionText!,
              onPressed: onActionPressed,
              variant: AtomicButtonVariant.tertiary,
              size: AtomicButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}

/// Status type enumeration
enum MolecularStatusType {
  info(Icons.info_outline),
  success(Icons.check_circle_outline),
  warning(Icons.warning_outlined),
  error(Icons.error_outline),
  loading(Icons.hourglass_empty);

  const MolecularStatusType(this.icon);

  final IconData icon;

  Color getBackgroundColor(ColorScheme colorScheme) {
    switch (this) {
      case MolecularStatusType.info:
        return ColorTokens.infoContainer;
      case MolecularStatusType.success:
        return ColorTokens.successContainer;
      case MolecularStatusType.warning:
        return ColorTokens.warningContainer;
      case MolecularStatusType.error:
        return colorScheme.errorContainer;
      case MolecularStatusType.loading:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color getBorderColor(ColorScheme colorScheme) {
    switch (this) {
      case MolecularStatusType.info:
        return ColorTokens.info;
      case MolecularStatusType.success:
        return ColorTokens.success;
      case MolecularStatusType.warning:
        return ColorTokens.warning;
      case MolecularStatusType.error:
        return colorScheme.error;
      case MolecularStatusType.loading:
        return colorScheme.outline;
    }
  }

  Color getIconColor(ColorScheme colorScheme) {
    return getBorderColor(colorScheme);
  }

  Color getTextColor(ColorScheme colorScheme) {
    switch (this) {
      case MolecularStatusType.info:
        return ColorTokens.onInfoContainer;
      case MolecularStatusType.success:
        return ColorTokens.onSuccessContainer;
      case MolecularStatusType.warning:
        return ColorTokens.onWarningContainer;
      case MolecularStatusType.error:
        return colorScheme.onErrorContainer;
      case MolecularStatusType.loading:
        return colorScheme.onSurfaceVariant;
    }
  }
}

/// Molecular List Tile Component
///
/// Enhanced list tile with consistent styling and optional actions.
class MolecularListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  const MolecularListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.m),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                AtomicIcon(
                  leadingIcon!,
                  size: AtomicIconSize.medium,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const AtomicSpacer(
                  AtomicSpacing.medium,
                  direction: AtomicSpacerDirection.horizontal,
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtomicText(
                      title,
                      variant: AtomicTextVariant.titleMedium,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    if (subtitle != null) ...[
                      const AtomicSpacer(AtomicSpacing.xs),
                      AtomicText(
                        subtitle!,
                        variant: AtomicTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const AtomicSpacer(
                  AtomicSpacing.small,
                  direction: AtomicSpacerDirection.horizontal,
                ),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
