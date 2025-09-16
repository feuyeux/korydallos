/// 简化的文本输入组件 - 从 TranslationInputWidget 中提取
import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/typography_tokens.dart';

/// 简单的文本输入框组件
class SimpleTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final double? height;

  const SimpleTextInput({
    super.key,
    required this.controller,
    this.hintText = 'Enter text...',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 60.0, // Standard text input height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(8),
        ),
        style: TypographyTokens.titleLargeStyle,
      ),
    );
  }
}

/// 简单的卡片标题组件
class SimpleCardHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget>? actions;

  const SimpleCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: DimensionTokens.iconXl),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (actions != null) ...[
          const Spacer(),
          ...actions!,
        ],
      ],
    );
  }
}
