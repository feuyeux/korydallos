import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../constants/language_constants.dart';

/// Translation Panel Organism
///
/// Complex component for translation input, language selection, and results display
class TranslationPanel extends StatefulWidget {
  final TextEditingController textController;
  final List<LanguageOption> selectedLanguages;
  final ValueChanged<List<LanguageOption>>? onLanguagesChanged;
  final VoidCallback? onTranslate;
  final VoidCallback? onClear;
  final bool isTranslating;
  final bool isCompactMode;
  final bool isConfigured;
  final String? errorMessage;
  final Map<String, String>? translationResults;

  const TranslationPanel({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    this.onLanguagesChanged,
    this.onTranslate,
    this.onClear,
    this.isTranslating = false,
    this.isCompactMode = false,
    this.isConfigured = true,
    this.errorMessage,
    this.translationResults,
  });

  @override
  State<TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<TranslationPanel> {
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.textController.text;
  }

  void _onTextChanged(String text) {
    setState(() {
      _currentText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Text input - smaller
            _buildTextInput(),
            const SizedBox(height: 4), // 统一间距为4px
            // Language chips - 6 per row with equal width
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 70, // 减少最大高度
                minHeight: 35, // 减少最小高度
              ),
              child: SingleChildScrollView(child: _buildLanguageGrid()),
            ),
            const SizedBox(height: 4), // 统一间距为4px
            // Action buttons
            _buildActionBar(),
            // Error display
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 4), // 统一间距为4px
              _buildErrorDisplay(),
            ],

            // Results
            if (widget.translationResults != null &&
                widget.translationResults!.isNotEmpty) ...[
              const SizedBox(height: 4), // 统一间距为4px
              _buildResults(),
            ],
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return SizedBox(
      height: 50, // 减少从90到50，最小化高度
      child: TextField(
        controller: widget.textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          labelText: 'Text to translate',
          hintText: 'Enter text to translate...',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          labelStyle: TextStyle(fontSize: 16),
        ),
        style: const TextStyle(fontSize: 14),
        enabled: !widget.isTranslating,
        onChanged: _onTextChanged,
      ),
    );
  }

  Widget _buildActionBar() {
    final hasText = _currentText.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    final canTranslate =
        hasText && hasLanguages && !widget.isTranslating && widget.isConfigured;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              _clearLanguages();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              _selectAllLanguages();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Select All', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canTranslate
                ? () {
                    widget.onTranslate?.call();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasLanguages ? null : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            icon: widget.isTranslating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate, size: 16),
            label: Text(
              widget.isTranslating ? 'Translating...' : 'Translate',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Translation Results',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4), // Reduced from 8 to 4
        ...widget.translationResults!.entries.map(
          (entry) => _buildResultItem(entry),
        ),
      ],
    );
  }

  Widget _buildResultItem(MapEntry<String, String> entry) {
    final language = LanguageConstants.supportedLanguages.firstWhere(
      (lang) => lang.code == entry.key,
      orElse: () => LanguageOption(
        code: entry.key,
        name: entry.key,
        nativeName: entry.key,
        flag: '🌐',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced from 8 to 4
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                language.flag,
                style: TextStyle(
                  fontSize: PlatformUtils.flagFontSize * 1.125,
                ),
              ), // 18.0 equivalent
              const SizedBox(width: 8),
              Text(
                language.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  _copyToClipboard(entry.value);
                },
                tooltip: 'Copy translation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced from 8 to 6
          Text(entry.value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _handleLanguageTap(LanguageOption language) {
    final currentSelection = List<LanguageOption>.from(
      widget.selectedLanguages,
    );

    // 通过语言代码比较来确定是否已选中
    final wasSelected = currentSelection.any(
      (selected) => selected.code == language.code,
    );

    if (wasSelected) {
      // 移除所有匹配的语言代码
      currentSelection.removeWhere(
        (selected) => selected.code == language.code,
      );
    } else {
      // 添加语言（确保不重复）
      if (!currentSelection.any((selected) => selected.code == language.code)) {
        currentSelection.add(language);
      }
    }

    widget.onLanguagesChanged?.call(currentSelection);
  }

  void _selectAllLanguages() {
    // 检查是否所有语言都已选中（通过比较语言代码）
    final selectedCodes = widget.selectedLanguages.map((l) => l.code).toSet();
    final allCodes = LanguageConstants.supportedLanguages
        .map((l) => l.code)
        .toSet();
    final isAllSelected =
        selectedCodes.containsAll(allCodes) &&
        allCodes.containsAll(selectedCodes);

    if (isAllSelected) {
      widget.onLanguagesChanged?.call([]);
    } else {
      // 否则全选
      final allLanguages = List<LanguageOption>.from(
        LanguageConstants.supportedLanguages,
      );
      widget.onLanguagesChanged?.call(allLanguages);
    }
  }

  void _clearLanguages() {
    widget.onLanguagesChanged?.call([]);
    widget.textController.clear();

    setState(() {
      _currentText = '';
    });

    // 调用 onClear 回调来清理翻译结果
    widget.onClear?.call();
  }

  Widget _buildLanguageGrid() {
    final languages = LanguageConstants.supportedLanguages;
    final rows = <Widget>[];

    // Split languages into rows of 6
    for (int i = 0; i < languages.length; i += 6) {
      final rowLanguages = languages.skip(i).take(6).toList();
      rows.add(_buildLanguageRow(rowLanguages));
      if (i + 6 < languages.length) {
        rows.add(const SizedBox(height: 2)); // 减少行间距从6到2
      }
    }

    return Column(children: rows);
  }

  Widget _buildLanguageRow(List<LanguageOption> languages) {
    return Row(
      children: languages.map((language) {
        // 通过语言代码比较来确定是否选中，而不是对象引用
        final isSelected = widget.selectedLanguages.any(
          (selected) => selected.code == language.code,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 1,
            ), // Minimal horizontal padding
            child: SizedBox(
              height: 28, // 减少高度从38到28
              width: double.infinity, // Ensure full width usage
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  _handleLanguageTap(language);
                },
                avatar: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 16), // 增大国旗字号
                ),
                label: SizedBox(
                  width: double
                      .infinity, // Force label to take full available width
                  child: Text(
                    language.name,
                    style: const TextStyle(
                      fontSize: 13, // 增大语种文字字号
                      fontWeight: FontWeight.w500, // 增加字重
                    ),
                    textAlign: TextAlign.center, // Center the text
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                showCheckmark: false, // 隐藏勾选标记
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ), // 增加内边距
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _copyToClipboard(String text) {
    try {
      Clipboard.setData(ClipboardData(text: text));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard')),
      );
    } catch (e) {
      // Handle error silently
    }
  }
}
