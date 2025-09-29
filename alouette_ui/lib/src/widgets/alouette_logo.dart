import 'package:flutter/material.dart';

/// Alouette应用程序的logo资源和组件
class AlouetteLogo {
  /// logo图片路径
  static const String logoPath =
      'packages/alouette_ui/assets/icons/alouette_rounded.png';

  /// 获取logo的Image widget
  /// [size] logo的大小，默认为24
  /// [fit] 图片适配方式，默认为BoxFit.contain
  static Widget image({
    double? size = 24,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return Image.asset(
      logoPath,
      width: size,
      height: size,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // 如果图片加载失败，显示一个默认图标
        return Icon(
          Icons.apps,
          size: size,
          color: color ?? Theme.of(context).primaryColor,
        );
      },
    );
  }

  /// 获取圆形头像样式的logo
  /// [radius] 圆形半径，默认为16
  static Widget circleAvatar({
    double radius = 16,
    Color? backgroundColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: const AssetImage(logoPath),
      onBackgroundImageError: (exception, stackTrace) {
        // 图片加载失败时的处理
      },
      child: null,
    );
  }

  /// 获取应用栏使用的logo
  /// [height] 高度，默认为32，适合AppBar
  static Widget appBarLogo({double height = 32}) {
    return image(
      size: height,
      fit: BoxFit.contain,
    );
  }

  /// 获取启动页或大尺寸展示用的logo
  /// [size] 大小，默认为120
  static Widget largeLogo({double size = 120}) {
    return image(
      size: size,
      fit: BoxFit.contain,
    );
  }
}
