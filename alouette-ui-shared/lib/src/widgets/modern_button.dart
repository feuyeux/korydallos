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
  }) : assert(text != null || child != null,
            'Either text or child must be provided');

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
    final BorderRadius effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(6.0); // 减少圆角让样式更现代

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
            if (widget.text != null) SizedBox(width: 4), // 减少图标和文本间距
          ],
          if (widget.text != null)
            Flexible(
              // 使用Flexible包装文本避免溢出
              child: Text(
                widget.text!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: _getFontSize(),
                ),
                overflow: TextOverflow.ellipsis, // 添加省略号处理
                maxLines: 1, // 限制为单行
              ),
            )
          else if (widget.child != null)
            Flexible(child: widget.child!), // 同样包装child
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
              ? backgroundColor.withOpacity(0.4) // 更明显的禁用状态
              : (_isHovering
                  ? backgroundColor.withOpacity(0.9) // 更明显的悬停效果
                  : backgroundColor),
          borderRadius: effectiveBorderRadius,
          border: widget.type == ModernButtonType.outline
              ? Border.all(
                  color: widget.onPressed == null
                      ? borderColor.withOpacity(0.4)
                      : borderColor,
                  width: 1.0) // 减少边框粗细
              : null,
          boxShadow: widget.type == ModernButtonType.primary &&
                  widget.onPressed != null &&
                  !widget.loading
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.2 : 0.15),
                    blurRadius: _isHovering ? 4 : 2,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
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
              constraints: widget.fullWidth
                  ? null
                  : BoxConstraints(
                      minWidth: UISizes.buttonMinWidth,
                      maxWidth: double.infinity, // 允许扩展但不强制
                    ),
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
        return UISizes.buttonHeightSmall;
      case ModernButtonSize.medium:
        return UISizes.buttonHeightMedium;
      case ModernButtonSize.large:
        return UISizes.buttonHeightLarge;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.iconOnly) {
      switch (widget.size) {
        case ModernButtonSize.small:
          return const EdgeInsets.all(4.0);
        case ModernButtonSize.medium:
          return const EdgeInsets.all(6.0);
        case ModernButtonSize.large:
          return const EdgeInsets.all(8.0);
      }
    } else {
      switch (widget.size) {
        case ModernButtonSize.small:
          return const EdgeInsets.symmetric(
              horizontal: 8.0, vertical: 3.0); // 减少水平内边距
        case ModernButtonSize.medium:
          return const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 5.0); // 减少内边距
        case ModernButtonSize.large:
          return const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 7.0); // 减少内边距
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
        return 11;
      case ModernButtonSize.medium:
        return 13;
      case ModernButtonSize.large:
        return 15;
    }
  }
}
