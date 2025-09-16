import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../constants/language_constants.dart';
import '../constants/ui_constants.dart';
import 'modern_button.dart';
import 'language_selection_grid.dart';

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
  final ScrollController _scrollController = ScrollController();

  bool get _isCompactMode => widget.onLanguagesChanged != null;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDefaults.compactPadding),
        child: _isCompactMode ? _buildCompactLayout() : _buildStandardLayout(),
      ),
    );
  }

  /// Standard layout for alouette-app
  Widget _buildStandardLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.edit, size: UISizes.largeIconSize),
            const SizedBox(width: 6),
            Text(
              'Text Input',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Text input
        Container(
          height: UISizes.textInputHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: widget.textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Enter text to translate...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
            ),
            style: const TextStyle(fontSize: TextStyles.largeFontSize),
          ),
        ),

        const SizedBox(height: 6),

        // Language selection
        Flexible(
          fit: FlexFit.loose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxHeight: UISizes.languageSelectionHeight),
            child: _buildLanguageSelection(),
          ),
        ),

        const SizedBox(height: 6),

        // Translate button
        _buildTranslateButton(),
      ],
    );
  }

  /// Compact layout for alouette-app-trans
  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Input
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Enter text to translate...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Language Selection Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target Languages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                _buildCompactButton(
                  'Select All',
                  () => _selectAllLanguages(),
                ),
                const SizedBox(width: 4),
                _buildCompactButton(
                  'Clear All',
                  () => _clearAllLanguages(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Language chips
        Expanded(
          flex: 4,
          child: LanguageSelectionGrid(
            scrollController: _scrollController,
            selectedLanguages: widget.selectedLanguages,
            onLanguageToggle: (language, selected) =>
                _onLanguageToggle(language, selected),
          ),
        ),

        const SizedBox(height: 8),

        // Translate button
        _buildTranslateButton(),
      ],
    );
  }

  Widget _buildCompactButton(String text, VoidCallback onPressed) {
    return Container(
      // 使用Container替代Flexible
      constraints: const BoxConstraints(
        minWidth: 60.0, // 最小宽度
        maxWidth: 120.0, // 最大宽度避免溢出
      ),
      child: ModernButton(
        text: text,
        onPressed: onPressed,
        type: ModernButtonType.text,
        size: ModernButtonSize.small,
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, size: UISizes.iconSizeMedium),
              const SizedBox(width: 4),
              Text(
                'Target Languages',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                'Selected: ${widget.selectedLanguages.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: TextStyles.smallFontSize,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Language chips
          SizedBox(
            height: UISizes.fixedLanguageChipsHeight,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: LanguageConstants.supportedLanguages.map((language) {
                  final isSelected =
                      widget.selectedLanguages.contains(language.code);
                  return FilterChip(
                    label: Container(
                      width: 100, // 统一宽度
                      alignment: Alignment.center,
                      child: Text(
                        '${language.flag} ${language.name}',
                        style:
                            const TextStyle(fontSize: TextStyles.smallFontSize),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) =>
                        _onLanguageToggle(language.code, selected),
                    padding: EdgeInsets.zero, // 移除内边距，由label的Container控制
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Quick selection buttons
          Row(
            children: [
              ModernButton(
                text: 'Reset',
                icon: Icons.refresh,
                onPressed: widget.onReset,
                type: ModernButtonType.text,
                size: ModernButtonSize.small,
              ),
              const SizedBox(width: 4),
              ModernButton(
                text: 'All',
                icon: Icons.select_all,
                onPressed: widget.onSelectAll,
                type: ModernButtonType.text,
                size: ModernButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton() {
    return SizedBox(
      width: double.infinity,
      child: widget.translationService != null
          ? ValueListenableBuilder<bool>(
              valueListenable: widget.translationService!.isTranslatingNotifier,
              builder: (context, isTranslating, child) {
                return _buildTranslateButtonContent(isTranslating);
              },
            )
          : _buildTranslateButtonContent(widget.isTranslating),
    );
  }

  Widget _buildTranslateButtonContent(bool isTranslating) {
    return ModernButton(
      text: isTranslating ? 'Translating...' : 'Translate',
      icon: Icons.translate,
      onPressed:
          (isTranslating || !widget.isConfigured) ? null : widget.onTranslate,
      type: ModernButtonType.primary,
      size: _isCompactMode ? ModernButtonSize.large : ModernButtonSize.medium,
      loading: isTranslating,
      fullWidth: true,
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
