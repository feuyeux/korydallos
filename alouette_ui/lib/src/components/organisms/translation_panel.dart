import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../../constants/language_constants.dart';

// Debug logging helper
void _debugLog(String message) {
  print('[TranslationPanel] ${DateTime.now().millisecondsSinceEpoch % 100000}: $message');
}

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
    this.errorMessage,
    this.translationResults,
  });

  @override
  State<TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<TranslationPanel> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.textController;
    _debugLog('TranslationPanel initialized');
    _debugLog('Initial selected languages: ${widget.selectedLanguages.map((l) => l.name).toList()}');
    _debugLog('Initial text: "${_textController.text}"');
  }

  @override
  Widget build(BuildContext context) {
    _debugLog('=== BUILD called ===');
    _debugLog('Selected languages: ${widget.selectedLanguages.map((l) => '${l.name}(${l.code})').toList()}');
    _debugLog('Text controller text: "${_textController.text}"');
    _debugLog('Is translating: ${widget.isTranslating}');
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text input - smaller
            _buildTextInput(),
            const SizedBox(height: 1), // Minimal spacing

            const SizedBox(height: 1), // Minimal spacing
            // Language chips - 6 per row with equal width
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 140, // Increased height for 2 rows
                minHeight: 70, // Increased minimum height for 1 row
              ),
              child: SingleChildScrollView(child: _buildLanguageGrid()),
            ),
            const SizedBox(height: 1), // Minimal spacing
            // Action buttons
            _buildActionBar(),
            const SizedBox(height: 1), // Minimal spacing
            // Error display
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorDisplay(),
            ],

            // Results
            if (widget.translationResults != null &&
                widget.translationResults!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return SizedBox(
      height: 90, // Increased height
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          labelText: 'Text to translate',
          hintText: 'Enter text to translate...',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8), // Further reduced padding
          labelStyle: TextStyle(fontSize: 16), // Larger label
        ),
        style: const TextStyle(fontSize: 14), // Smaller text
        enabled: !widget.isTranslating,
      ),
    );
  }

  Widget _buildActionBar() {
    final hasText = _textController.text.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    final canTranslate = hasText && hasLanguages && !widget.isTranslating;
    
    _debugLog('=== ActionBar Build ===');
    _debugLog('Text controller text: "${_textController.text}"');
    _debugLog('Text controller text length: ${_textController.text.length}');
    _debugLog('hasText: $hasText');
    _debugLog('Selected languages: ${widget.selectedLanguages.map((l) => l.name).toList()}');
    _debugLog('hasLanguages: $hasLanguages');
    _debugLog('isTranslating: ${widget.isTranslating}');
    _debugLog('canTranslate: $canTranslate');

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              _debugLog('Clear button pressed');
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
              _debugLog('Select All button pressed');
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
            onPressed: canTranslate ? () {
              _debugLog('Translate button pressed');
              _debugLog('Calling widget.onTranslate callback');
              widget.onTranslate?.call();
            } : null,
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
        const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
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
              Text(language.flag, style: TextStyle(fontSize: PlatformDetector().flagFontSize * 1.125)), // 18.0 equivalent
              const SizedBox(width: 8),
              Text(
                language.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  _debugLog('Copy button pressed for ${language.name}');
                  _copyToClipboard(entry.value);
                },
                tooltip: 'Copy translation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _handleLanguageTap(LanguageOption language) {
    _debugLog('Language chip tapped: ${language.name} (${language.code})');
    
    final currentSelection = List<LanguageOption>.from(widget.selectedLanguages);
    
    // 通过语言代码比较来确定是否已选中
    final wasSelected = currentSelection.any((selected) => selected.code == language.code);
    _debugLog('Was selected: $wasSelected');
    
    if (wasSelected) {
      // 移除所有匹配的语言代码
      currentSelection.removeWhere((selected) => selected.code == language.code);
      _debugLog('Removed ${language.name} from selection');
    } else {
      // 添加语言（确保不重复）
      if (!currentSelection.any((selected) => selected.code == language.code)) {
        currentSelection.add(language);
        _debugLog('Added ${language.name} to selection');
      }
    }

    _debugLog('New selection codes: ${currentSelection.map((l) => l.code).toList()}');
    _debugLog('New selection names: ${currentSelection.map((l) => l.name).toList()}');
    _debugLog('Calling onLanguagesChanged callback');
    widget.onLanguagesChanged?.call(currentSelection);
  }

  void _selectAllLanguages() {
    _debugLog('_selectAllLanguages called');
    _debugLog('Current selection count: ${widget.selectedLanguages.length}');
    _debugLog('Total languages count: ${LanguageConstants.supportedLanguages.length}');
    
    // 检查是否所有语言都已选中（通过比较语言代码）
    final selectedCodes = widget.selectedLanguages.map((l) => l.code).toSet();
    final allCodes = LanguageConstants.supportedLanguages.map((l) => l.code).toSet();
    final isAllSelected = selectedCodes.containsAll(allCodes) && allCodes.containsAll(selectedCodes);
    
    _debugLog('Selected codes: $selectedCodes');
    _debugLog('All codes: $allCodes');
    _debugLog('Is all selected: $isAllSelected');
    
    if (isAllSelected) {
      _debugLog('All languages selected, clearing selection');
      widget.onLanguagesChanged?.call([]);
    } else {
      // 否则全选
      _debugLog('Not all languages selected, selecting all');
      final allLanguages = List<LanguageOption>.from(LanguageConstants.supportedLanguages);
      _debugLog('Selecting languages: ${allLanguages.map((l) => l.name).toList()}');
      widget.onLanguagesChanged?.call(allLanguages);
    }
  }

  void _clearLanguages() {
    _debugLog('_clearLanguages called');
    _debugLog('Text before clear: "${_textController.text}"');
    
    _debugLog('Clearing language selection');
    widget.onLanguagesChanged?.call([]);
    
    _debugLog('Clearing text input');
    _textController.clear();
    
    _debugLog('Text after clear: "${_textController.text}"');
    _debugLog('Triggering setState to update UI');
    
    // 强制触发 UI 更新
    setState(() {});
    
    _debugLog('Clear operation completed');
  }

  Widget _buildLanguageGrid() {
    final languages = LanguageConstants.supportedLanguages;
    final rows = <Widget>[];

    // Split languages into rows of 6
    for (int i = 0; i < languages.length; i += 6) {
      final rowLanguages = languages.skip(i).take(6).toList();
      rows.add(_buildLanguageRow(rowLanguages));
      if (i + 6 < languages.length) {
        rows.add(const SizedBox(height: 6)); // Spacing between rows
      }
    }

    return Column(children: rows);
  }

  Widget _buildLanguageRow(List<LanguageOption> languages) {
    return Row(
      children: languages.map((language) {
        // 通过语言代码比较来确定是否选中，而不是对象引用
        final isSelected = widget.selectedLanguages.any((selected) => selected.code == language.code);
        _debugLog('Language ${language.name} (${language.code}) isSelected: $isSelected');
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 1,
            ), // Minimal horizontal padding
            child: SizedBox(
              height: 38, // 增加高度以容纳更大的字体
              width: double.infinity, // Ensure full width usage
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  _debugLog('FilterChip onSelected called for ${language.name}, selected: $selected, current isSelected: $isSelected');
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
    _debugLog('_copyToClipboard called with text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
    
    try {
      Clipboard.setData(ClipboardData(text: text));
      _debugLog('Text copied to clipboard successfully');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard')),
      );
      _debugLog('Snackbar shown');
    } catch (e) {
      _debugLog('Error copying to clipboard: $e');
    }
  }
}
