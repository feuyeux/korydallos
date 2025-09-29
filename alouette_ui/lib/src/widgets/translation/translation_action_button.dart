import 'package:flutter/material.dart';
import '../modern_button.dart';

/// 翻译操作按钮组件
/// 提供翻译按钮及其状态管理
class TranslationActionButton extends StatelessWidget {
  final VoidCallback onTranslate;
  final bool isTranslating;
  final bool isConfigured;
  final bool hasSelectedLanguages;
  final bool hasText;

  const TranslationActionButton({
    super.key,
    required this.onTranslate,
    this.isTranslating = false,
    this.isConfigured = true,
    this.hasSelectedLanguages = true,
    this.hasText = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = isConfigured && 
                          hasSelectedLanguages && 
                          hasText && 
                          !isTranslating;

    return SizedBox(
      width: double.infinity,
      child: ModernButton(
        text: _getButtonText(),
        icon: _getButtonIcon(),
        onPressed: isEnabled ? onTranslate : null,
        type: ModernButtonType.primary,
        size: ModernButtonSize.medium,
        loading: isTranslating,
      ),
    );
  }

  String _getButtonText() {
    if (isTranslating) {
      return 'Translating...';
    }
    if (!isConfigured) {
      return 'Configure Translation Service';
    }
    if (!hasSelectedLanguages) {
      return 'Select Target Languages';
    }
    if (!hasText) {
      return 'Enter Text to Translate';
    }
    return 'Translate';
  }

  IconData _getButtonIcon() {
    if (isTranslating) {
      return Icons.sync;
    }
    if (!isConfigured) {
      return Icons.settings;
    }
    if (!hasSelectedLanguages) {
      return Icons.language;
    }
    if (!hasText) {
      return Icons.edit;
    }
    return Icons.translate;
  }
}
