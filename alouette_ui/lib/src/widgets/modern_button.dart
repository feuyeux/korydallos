import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/motion_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/effect_tokens.dart';

/// 按钮类型枚举
enum ModernButtonType { primary, secondary, outline, text }

/// 按钮尺寸枚举
enum ModernButtonSize { small, medium, large }

/// 现代化的按钮组件，为所有Alouette应用提供一致的交互元素
/// 重构后减少了重复代码，使用设计令牌系统提供一致性
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
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 使用设计令牌系统
    final Color primaryColor = widget.color ?? ColorTokens.primary;
    final _ButtonStyle buttonStyle = _getButtonStyle(primaryColor, isDark);
    final _ButtonSize buttonSize = _getButtonSize();

    // 构建按钮内容
    Widget content = _buildContent(buttonStyle, buttonSize);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        height: buttonSize.height,
        decoration: BoxDecoration(
          color: _getEffectiveBackgroundColor(buttonStyle),
          borderRadius: widget.borderRadius ?? EffectTokens.radiusMedium,
          border: widget.type == ModernButtonType.outline
              ? Border.all(color: buttonStyle.borderColor, width: 1.0)
              : null,
          boxShadow: _getShadow(buttonStyle),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: buttonStyle.splashColor,
            highlightColor: buttonStyle.highlightColor,
            borderRadius: widget.borderRadius ?? EffectTokens.radiusMedium,
            child: Container(
              padding: widget.padding ?? buttonSize.padding,
              width: widget.fullWidth ? double.infinity : null,
              constraints: widget.fullWidth
                  ? null
                  : BoxConstraints(
                      minWidth: DimensionTokens.buttonMinWidth,
                      maxWidth: double.infinity,
                    ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonStyle style, _ButtonSize size) {
    if (widget.loading) {
      return SizedBox(
        height: size.iconSize,
        width: size.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(style.textColor),
        ),
      );
    }

    if (widget.iconOnly && widget.icon != null) {
      return Icon(widget.icon, size: size.iconSize, color: style.textColor);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: size.iconSize, color: style.textColor),
          if (widget.text != null) const SizedBox(width: 4),
        ],
        if (widget.text != null)
          Flexible(
            child: Text(
              widget.text!,
              style: TypographyTokens.labelLargeStyle.copyWith(
                color: style.textColor,
                fontSize: size.fontSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        else if (widget.child != null)
          Flexible(child: widget.child!),
      ],
    );
  }

  Color _getEffectiveBackgroundColor(_ButtonStyle style) {
    if (widget.onPressed == null) {
      return style.backgroundColor.withValues(alpha: 0.4);
    }
    return _isHovering
        ? style.backgroundColor.withValues(alpha: 0.9)
        : style.backgroundColor;
  }

  List<BoxShadow>? _getShadow(_ButtonStyle style) {
    if (widget.type == ModernButtonType.primary &&
        widget.onPressed != null &&
        !widget.loading) {
      return _isHovering
          ? ElevationTokens.shadowMedium
          : ElevationTokens.shadowSubtle;
    }
    return null;
  }
}

/// 按钮样式配置类
class _ButtonStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color splashColor;
  final Color highlightColor;

  const _ButtonStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.splashColor,
    required this.highlightColor,
  });
}

/// 按钮尺寸配置类
class _ButtonSize {
  final double height;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const _ButtonSize({
    required this.height,
    required this.iconSize,
    required this.fontSize,
    required this.padding,
  });
}

extension _ModernButtonStyleHelper on _ModernButtonState {
  /// 获取按钮样式配置
  _ButtonStyle _getButtonStyle(Color primaryColor, bool isDark) {
    switch (widget.type) {
      case ModernButtonType.primary:
        return _ButtonStyle(
          textColor: ColorTokens.onPrimary,
          backgroundColor: primaryColor,
          borderColor: Colors.transparent,
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
        );
      case ModernButtonType.secondary:
        return _ButtonStyle(
          textColor: isDark ? ColorTokens.darkOnSurface : ColorTokens.onSurface,
          backgroundColor: isDark ? ColorTokens.gray800 : ColorTokens.gray100,
          borderColor: Colors.transparent,
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
        );
      case ModernButtonType.outline:
        return _ButtonStyle(
          textColor: primaryColor,
          backgroundColor: Colors.transparent,
          borderColor: primaryColor,
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
        );
      case ModernButtonType.text:
        return _ButtonStyle(
          textColor: primaryColor,
          backgroundColor: Colors.transparent,
          borderColor: Colors.transparent,
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
        );
    }
  }

  /// 获取按钮尺寸配置
  _ButtonSize _getButtonSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return _ButtonSize(
          height: DimensionTokens.buttonS,
          iconSize: DimensionTokens.iconS,
          fontSize: TypographyTokens.labelSmall,
          padding: widget.iconOnly
              ? const EdgeInsets.all(SpacingTokens.xs)
              : const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.s,
                  vertical: SpacingTokens.xxs,
                ),
        );
      case ModernButtonSize.medium:
        return _ButtonSize(
          height: DimensionTokens.buttonM,
          iconSize: DimensionTokens.iconM,
          fontSize: TypographyTokens.labelMedium,
          padding: widget.iconOnly
              ? const EdgeInsets.all(SpacingTokens.s)
              : const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.m,
                  vertical: SpacingTokens.xs,
                ),
        );
      case ModernButtonSize.large:
        return _ButtonSize(
          height: DimensionTokens.buttonL,
          iconSize: DimensionTokens.iconL,
          fontSize: TypographyTokens.labelLarge,
          padding: widget.iconOnly
              ? const EdgeInsets.all(SpacingTokens.m)
              : const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.l,
                  vertical: SpacingTokens.s,
                ),
        );
    }
  }
}
