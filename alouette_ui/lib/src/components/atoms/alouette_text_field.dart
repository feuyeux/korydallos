import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import 'atomic_elements.dart';

/// Alouette Text Field Component
///
/// Consolidated text field component that replaces ModernTextField and provides
/// consistent input field styling across all Alouette applications.
/// Supports various input types and validation states.
class AlouetteTextField extends AtomicWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final AlouetteTextFieldSize size;
  final AlouetteTextFieldType type;
  final bool isRequired;
  final bool isEnabled;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextAlign textAlign;

  const AlouetteTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.size = AlouetteTextFieldSize.medium,
    this.type = AlouetteTextFieldType.text,
    this.isRequired = false,
    this.isEnabled = true,
    this.maxLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getColorScheme(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) _buildLabel(context),
        if (labelText != null) const AtomicSpacer(AtomicSpacing.xs),
        _buildTextField(context, colorScheme, hasError),
        if (helperText != null || errorText != null) ...[
          const AtomicSpacer(AtomicSpacing.xs),
          _buildHelperText(context, hasError),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        AtomicText(
          labelText!,
          variant: AtomicTextVariant.labelMedium,
          color: getColorScheme(context).onSurface,
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          AtomicText(
            '*',
            variant: AtomicTextVariant.labelMedium,
            color: getColorScheme(context).error,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
      BuildContext context, ColorScheme colorScheme, bool hasError) {
    return SizedBox(
      height: maxLines == null ? size.height : null,
      child: TextField(
        controller: controller,
        enabled: isEnabled,
        keyboardType: type.keyboardType,
        textInputAction: type.textInputAction,
        obscureText: type.isObscure,
        maxLines: maxLines ?? (type.isMultiline ? null : 1),
        maxLength: maxLength,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        autofocus: autofocus,
        textAlign: textAlign,
        style: size.textStyle,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? AtomicIcon(
                  prefixIcon!,
                  size: size.iconSize,
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: AtomicIcon(
                    suffixIcon!,
                    size: size.iconSize,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          border: _buildInputBorder(colorScheme.outline),
          enabledBorder: _buildInputBorder(colorScheme.outline),
          focusedBorder: _buildInputBorder(colorScheme.primary),
          errorBorder: _buildInputBorder(colorScheme.error),
          focusedErrorBorder: _buildInputBorder(colorScheme.error),
          disabledBorder:
              _buildInputBorder(colorScheme.outline.withValues(alpha: 0.38)),
          filled: true,
          fillColor: isEnabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.05)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.02),
          contentPadding: size.padding,
          counterText: '', // Hide character counter
          errorText: null, // We handle error text separately
        ),
      ),
    );
  }

  Widget _buildHelperText(BuildContext context, bool hasError) {
    final text = hasError ? errorText! : helperText!;
    final color = hasError
        ? getColorScheme(context).error
        : getColorScheme(context).onSurfaceVariant;

    return AtomicText(
      text,
      variant: AtomicTextVariant.caption,
      color: color,
    );
  }

  InputBorder _buildInputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}

/// Text field size enumeration
enum AlouetteTextFieldSize {
  small(
    DimensionTokens.inputS,
    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    AtomicIconSize.small,
    TypographyTokens.bodySmallStyle,
  ),
  medium(
    DimensionTokens.inputM,
    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    AtomicIconSize.medium,
    TypographyTokens.bodyMediumStyle,
  ),
  large(
    DimensionTokens.inputL,
    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    AtomicIconSize.medium,
    TypographyTokens.bodyLargeStyle,
  );

  const AlouetteTextFieldSize(
      this.height, this.padding, this.iconSize, this.textStyle);

  final double height;
  final EdgeInsets padding;
  final AtomicIconSize iconSize;
  final TextStyle textStyle;
}

/// Text field type enumeration
enum AlouetteTextFieldType {
  text(TextInputType.text, TextInputAction.next, false, false),
  email(TextInputType.emailAddress, TextInputAction.next, false, false),
  password(TextInputType.visiblePassword, TextInputAction.done, true, false),
  number(TextInputType.number, TextInputAction.done, false, false),
  phone(TextInputType.phone, TextInputAction.done, false, false),
  url(TextInputType.url, TextInputAction.done, false, false),
  multiline(TextInputType.multiline, TextInputAction.newline, false, true),
  search(TextInputType.text, TextInputAction.search, false, false);

  const AlouetteTextFieldType(
    this.keyboardType,
    this.textInputAction,
    this.isObscure,
    this.isMultiline,
  );

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isObscure;
  final bool isMultiline;
}