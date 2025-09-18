import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/language_constants.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/alouette_button.dart';
import '../atoms/alouette_text_field.dart';
import '../molecules/language_selector.dart';
import '../molecules/status_indicator.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return AtomicCard(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),
          
          // Text input
          _buildTextInput(),
          const SizedBox(height: 16),
          
          // Language selection
          const Text(
            'Target Languages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          // Language buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _selectAllLanguages,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Select All', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _clearLanguages,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Language chips - scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LanguageConstants.supportedLanguages.map((language) {
                  final isSelected = widget.selectedLanguages.contains(language);
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (_) => _handleLanguageTap(language),
                    avatar: Text(
                      language.flag,
                      style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(
                      language.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          _buildActionBar(),
          
          // Error display
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildErrorDisplay(),
          ],
          
          // Results
          if (widget.translationResults != null && widget.translationResults!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const AtomicIcon(
          Icons.translate,
          size: AtomicIconSize.medium,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        const Text(
          'Translation Input',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTextInput() {
    return SizedBox(
      height: 120,
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          labelText: 'Text to translate',
          hintText: 'Enter text to translate...',
          border: OutlineInputBorder(),
        ),
        enabled: !widget.isTranslating,
      ),
    );
  }

  Widget _buildActionBar() {
    final hasText = _textController.text.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    final canTranslate = hasText && hasLanguages && !widget.isTranslating;

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onClear,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canTranslate ? widget.onTranslate : null,
            icon: widget.isTranslating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate, size: 18),
            label: Text(widget.isTranslating ? 'Translating...' : 'Translate'),
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
        ...widget.translationResults!.entries.map((entry) => _buildResultItem(entry)),
      ],
    );
  }

  Widget _buildResultItem(MapEntry<String, String> entry) {
    final language = LanguageConstants.supportedLanguages
        .firstWhere((lang) => lang.code == entry.key, orElse: () => LanguageOption(
          code: entry.key,
          name: entry.key,
          nativeName: entry.key,
          flag: '🌐',
        ));

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
              Text(
                language.flag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                language.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(entry.value),
                tooltip: 'Copy translation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _handleLanguageTap(LanguageOption language) {
    final currentSelection = List<LanguageOption>.from(widget.selectedLanguages);
    
    if (currentSelection.contains(language)) {
      currentSelection.remove(language);
    } else {
      currentSelection.add(language);
    }
    
    widget.onLanguagesChanged?.call(currentSelection);
  }

  void _selectAllLanguages() {
    widget.onLanguagesChanged?.call(List.from(LanguageConstants.supportedLanguages));
  }

  void _clearLanguages() {
    widget.onLanguagesChanged?.call([]);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Translation copied to clipboard')),
    );
  }
}