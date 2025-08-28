import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../models/translation_models.dart';

class TranslationResultWidget extends StatelessWidget {
  final TranslationService translationService;

  const TranslationResultWidget({
    super.key,
    required this.translationService,
  });

  @override
  Widget build(BuildContext context) {
    final translation = translationService.currentTranslation;

    if (translation == null) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Translation results will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Translation Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _buildActionButtons(context, translation),
              ],
            ),
            const SizedBox(height: 8),
            
            // Metadata
            _buildMetadata(context, translation),
            const SizedBox(height: 16),
            
            // Original Text
            _buildOriginalText(context, translation),
            const SizedBox(height: 16),
            
            // Translations
            Expanded(
              child: _buildTranslations(context, translation),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TranslationResult translation) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy all translations',
          onPressed: () => _copyAllTranslations(context, translation),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear results',
          onPressed: () => translationService.clearTranslation(),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context, TranslationResult translation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Model: ${translation.config.selectedModel} • '
              'Provider: ${translation.config.provider} • '
              'Time: ${_formatTime(translation.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalText(BuildContext context, TranslationResult translation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Original Text:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            translation.original,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslations(BuildContext context, TranslationResult translation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Translations:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true, // 始终显示滚动条
            child: ListView.builder(
              itemCount: translation.translations.length,
              itemBuilder: (context, index) {
                final language = translation.languages[index];
                final translatedText = translation.translations[language] ?? '';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTranslationItem(context, language, translatedText),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationItem(BuildContext context, String language, String text) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.green.shade700),
                  tooltip: 'Copy $language translation',
                  onPressed: () => _copySingleTranslation(context, language, text),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Translation text
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }

  void _copySingleTranslation(BuildContext context, String language, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$language translation copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAllTranslations(BuildContext context, TranslationResult translation) {
    final buffer = StringBuffer();
    buffer.writeln('Translation Results');
    buffer.writeln('Generated: ${translation.timestamp}');
    buffer.writeln('Model: ${translation.config.selectedModel}');
    buffer.writeln('Provider: ${translation.config.provider}');
    buffer.writeln();
    buffer.writeln('Original Text:');
    buffer.writeln(translation.original);
    buffer.writeln();
    buffer.writeln('Translations:');
    
    for (final language in translation.languages) {
      final translatedText = translation.translations[language] ?? '';
      buffer.writeln();
      buffer.writeln('$language:');
      buffer.writeln(translatedText);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All translations copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
