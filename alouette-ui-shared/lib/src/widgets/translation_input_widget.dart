import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../constants/language_constants.dart';
import '../constants/ui_constants.dart';

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
            constraints: const BoxConstraints(maxHeight: UISizes.languageSelectionHeight),
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
          flex: 3,
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

        const SizedBox(height: 4),

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
        const SizedBox(height: 2),

        // Language chips
        Expanded(
          flex: 3,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: LanguageConstants.supportedLanguages.map((lang) {
                  final isSelected = widget.selectedLanguages.contains(lang.name);
                  return FilterChip(
                    label: Text(
                      lang.nativeName,
                      style: const TextStyle(fontSize: TextStyles.mediumFontSize),
                    ),
                    selected: isSelected,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (selected) => _onLanguageToggle(lang.name, selected),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Translate button
        _buildTranslateButton(),
      ],
    );
  }

  Widget _buildCompactButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: UISizes.compactButtonWidth,
      height: UISizes.buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: Size(UISizes.compactButtonWidth, UISizes.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: TextStyles.smallFontSize + 1)),
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
              const Icon(Icons.language, size: UISizes.mediumIconSize),
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
                  final isSelected = widget.selectedLanguages.contains(language.code);
                  return FilterChip(
                    label: Text(
                      '${language.flag} ${language.name}',
                      style: const TextStyle(fontSize: TextStyles.smallFontSize),
                    ),
                    selected: isSelected,
                    onSelected: (selected) => _onLanguageToggle(language.code, selected),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
              TextButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh, size: UISizes.smallIconSize),
                label: const Text('Reset', style: TextStyle(fontSize: TextStyles.smallFontSize)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: widget.onSelectAll,
                icon: const Icon(Icons.select_all, size: UISizes.smallIconSize),
                label: const Text('All', style: TextStyle(fontSize: TextStyles.smallFontSize)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
    return ElevatedButton.icon(
      onPressed: (isTranslating || !widget.isConfigured) ? null : widget.onTranslate,
      icon: isTranslating
          ? const SizedBox(
              width: UISizes.mediumIconSize,
              height: UISizes.mediumIconSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.translate, size: UISizes.mediumIconSize),
      label: Text(
        isTranslating ? 'Translating...' : 'Translate',
        style: TextStyle(
          fontSize: _isCompactMode ? UISizes.mediumIconSize : 13,
          fontWeight: _isCompactMode ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: _isCompactMode ? 12 : 6,
        ),
        backgroundColor: _isCompactMode ? Theme.of(context).primaryColor : null,
        foregroundColor: _isCompactMode ? Colors.white : null,
        elevation: _isCompactMode ? 2 : null,
        shape: _isCompactMode
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            : null,
      ),
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