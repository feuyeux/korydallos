import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';
import '../themes/app_theme.dart';

/// 按钮类型枚举
enum ModernButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// 按钮尺寸枚举
enum ModernButtonSize {
  small,
  medium,
  large,
}

/// 现代化的按钮组件，为所有Alouette应用提供一致的交互元素
class ModernButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final ModernButtonSize size;
  final IconData? icon;
  final bool iconOnly;
  final bool loading;
  final bool fullWidth;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const ModernButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.iconOnly = false,
    this.loading = false,
    this.fullWidth = false,
    this.color,
    this.padding,
    this.borderRadius,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 确定按钮颜色
    final Color primaryColor = widget.color ?? AppTheme.primaryColor;
    final Color textColor = _getTextColor(primaryColor, isDark);
    final Color backgroundColor = _getBackgroundColor(primaryColor, isDark);
    final Color borderColor = _getBorderColor(primaryColor, isDark);
    
    // 确定按钮尺寸
    final double height = _getHeight();
    final EdgeInsetsGeometry effectivePadding = widget.padding ?? _getPadding();
    final double iconSize = _getIconSize();
    final BorderRadius effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(UISizes.buttonBorderRadius);
    
    // 构建按钮内容
    Widget content;
    if (widget.loading) {
      content = SizedBox(
        height: iconSize,
        width: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (widget.iconOnly && widget.icon != null) {
      content = Icon(widget.icon, size: iconSize, color: textColor);
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[            
            Icon(widget.icon, size: iconSize, color: textColor),
            SizedBox(width: widget.text != null ? UISizes.spacingS : 0),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: _getFontSize(),
              ),
            )
          else if (widget.child != null)
            widget.child!,
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: AppTheme.animationDuration,
        height: height,
        decoration: BoxDecoration(
          color: widget.onPressed == null 
              ? backgroundColor.withOpacity(0.6) 
              : (_isHovering ? backgroundColor.withOpacity(0.8) : backgroundColor),
          borderRadius: effectiveBorderRadius,
          border: widget.type == ModernButtonType.outline 
              ? Border.all(color: borderColor, width: 1.5) 
              : null,
          boxShadow: widget.type == ModernButtonType.primary && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                    blurRadius: _isHovering ? 8 : 4,
                    spreadRadius: _isHovering ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: widget.type == ModernButtonType.text 
                ? primaryColor.withOpacity(0.1) 
                : null,
            highlightColor: widget.type == ModernButtonType.text 
                ? primaryColor.withOpacity(0.05) 
                : null,
            borderRadius: effectiveBorderRadius,
            child: Container(
              padding: effectivePadding,
              width: widget.fullWidth ? double.infinity : null,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTextColor(Color primaryColor, bool isDark) {
    switch (widget.type) {
      case ModernButtonType.primary:
        return Colors.white;
      case ModernButtonType.secondary:
        return isDark ? Colors.white : const Color(0xFF1F2937);
      case ModernButtonType.outline:
      case ModernButtonType.text:
        return primaryColor;
    }
  }

  Color _getBackgroundColor(Color primaryColor, bool isDark) {
    switch (widget.type) {
      case ModernButtonType.primary:
        return primaryColor;
      case ModernButtonType.secondary:
        return isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100;
      case ModernButtonType.outline:
        return Colors.transparent;
      case ModernButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(Color primaryColor, bool isDark) {
    switch (widget.type) {
      case ModernButtonType.outline:
        return primaryColor;
      default:
        return Colors.transparent;
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return UISizes.buttonHeightCompact;
      case ModernButtonSize.medium:
        return UISizes.buttonHeightStandard;
      case ModernButtonSize.large:
        return UISizes.buttonHeightStandard * 1.2;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.iconOnly) {
      switch (widget.size) {
        case ModernButtonSize.small:
          return const EdgeInsets.all(UISizes.spacingXs);
        case ModernButtonSize.medium:
          return const EdgeInsets.all(UISizes.spacingS);
        case ModernButtonSize.large:
          return const EdgeInsets.all(UISizes.spacingM);
      }
    } else {
      switch (widget.size) {
        case ModernButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: UISizes.spacingM, vertical: UISizes.spacingXs);
        case ModernButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: UISizes.spacingL, vertical: UISizes.spacingS);
        case ModernButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: UISizes.spacingXl, vertical: UISizes.spacingM);
      }
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return UISizes.iconSizeSmall;
      case ModernButtonSize.medium:
        return UISizes.iconSizeMedium;
      case ModernButtonSize.large:
        return UISizes.iconSizeLarge;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 12;
      case ModernButtonSize.medium:
        return 14;
      case ModernButtonSize.large:
        return 16;
    }
  }
}