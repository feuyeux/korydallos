import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../constants/language_constants.dart';
import 'simple_components.dart';
import 'translation/translation_text_input.dart';
import 'translation/language_selection_section.dart';
import 'translation/translation_action_button.dart';

/// 翻译输入组件 - 重构后的精简版本
/// 支持标准和紧凑两种布局模式
class TranslationInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final VoidCallback onTranslate;
  final TranslationService? translationService;
  final void Function(String language, bool selected)? onLanguageToggle;
  final ValueChanged<List<String>>? onLanguagesChanged;
  final VoidCallback? onReset;
  final VoidCallback? onSelectAll;
  final bool isTranslating;
  final bool isConfigured;

  const TranslationInputWidget({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    required this.onTranslate,
    this.translationService,
    this.onLanguageToggle,
    this.onLanguagesChanged,
    this.onReset,
    this.onSelectAll,
    this.isTranslating = false,
    this.isConfigured = true,
  });

  @override
  State<TranslationInputWidget> createState() => _TranslationInputWidgetState();
}

class _TranslationInputWidgetState extends State<TranslationInputWidget> {
  bool get _isCompactMode => widget.onLanguagesChanged != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isCompactMode ? _buildCompactLayout() : _buildStandardLayout(),
      ),
    );
  }

  /// 标准布局 - 用于主要翻译应用
  Widget _buildStandardLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const SimpleCardHeader(
          title: 'Text Input',
          icon: Icons.edit,
        ),
        const SizedBox(height: 6),

        // 文本输入
        TranslationTextInput(
          controller: widget.textController,
          hintText: 'Enter text to translate...',
          multiLine: true,
        ),
        const SizedBox(height: 6),

        // 语言选择
        Flexible(
          fit: FlexFit.loose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 110.0, // AppSpecificSizes.languageSelectionHeight
            ),
            child: LanguageSelectionSection(
              selectedLanguages: widget.selectedLanguages,
              onLanguageToggle: _onLanguageToggle,
              onSelectAll: widget.onSelectAll,
              onClearAll: widget.onReset,
              showCompactButtons: false,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 翻译按钮
        TranslationActionButton(
          onTranslate: widget.onTranslate,
          isTranslating: widget.isTranslating,
          isConfigured: widget.isConfigured,
          hasSelectedLanguages: widget.selectedLanguages.isNotEmpty,
          hasText: widget.textController.text.isNotEmpty,
        ),
      ],
    );
  }

  /// 紧凑布局 - 用于专门的翻译应用
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文本输入
        TranslationTextInput(
          controller: widget.textController,
          hintText: 'Enter text to translate...',
          multiLine: true,
        ),
        const SizedBox(height: 8),

        // 语言选择
        Expanded(
          flex: 4,
          child: LanguageSelectionSection(
            selectedLanguages: widget.selectedLanguages,
            onLanguageToggle: _onLanguageToggle,
            onSelectAll: _selectAllLanguages,
            onClearAll: _clearAllLanguages,
            showCompactButtons: true,
          ),
        ),
        const SizedBox(height: 8),

        // 翻译按钮
        TranslationActionButton(
          onTranslate: widget.onTranslate,
          isTranslating: widget.isTranslating,
          isConfigured: widget.isConfigured,
          hasSelectedLanguages: widget.selectedLanguages.isNotEmpty,
          hasText: widget.textController.text.isNotEmpty,
        ),
      ],
    );
  }

  void _onLanguageToggle(String language, bool selected) {
    if (widget.onLanguageToggle != null) {
      widget.onLanguageToggle!(language, selected);
    } else if (widget.onLanguagesChanged != null) {
      final newLanguages = List<String>.from(widget.selectedLanguages);
      if (selected) {
        newLanguages.add(language);
      } else {
        newLanguages.remove(language);
      }
      widget.onLanguagesChanged!(newLanguages);
    }
  }

  void _selectAllLanguages() {
    if (widget.onLanguagesChanged != null) {
      final allLanguages = LanguageConstants.supportedLanguages
          .map((lang) => lang.name)
          .toList();
      widget.onLanguagesChanged!(allLanguages);
    }
  }

  void _clearAllLanguages() {
    if (widget.onLanguagesChanged != null) {
      widget.onLanguagesChanged!([]);
    }
  }
}
