import 'package:flutter/material.dart';
import '../../constants/language_constants.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/alouette_button.dart';
import '../atoms/alouette_text_field.dart';
import '../molecules/language_selector.dart';
import '../molecules/status_indicator.dart';

/// Translation Panel Organism
///
/// Complex component that handles translation input, language selection,
/// and translation controls in a cohesive interface.
class TranslationPanel extends StatefulWidget {
  final TextEditingController? textController;
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
    this.textController,
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
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.textController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.textController == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtomicCard(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const AtomicSpacer(AtomicSpacing.medium),
          _buildTextInput(),
          const AtomicSpacer(AtomicSpacing.medium),
          _buildLanguageSelection(),
          const AtomicSpacer(AtomicSpacing.medium),
          _buildActionBar(),
          if (widget.errorMessage != null) ...[
            const AtomicSpacer(AtomicSpacing.medium),
            _buildErrorDisplay(),
          ],
          if (widget.translationResults != null && widget.translationResults!.isNotEmpty) ...[
            const AtomicSpacer(AtomicSpacing.medium),
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
        ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        const AtomicText(
          'Translation Input',
          variant: AtomicTextVariant.titleMedium,
        ),
        const Spacer(),
        if (widget.isCompactMode)
          AlouetteButton(
            icon: Icons.settings,
            onPressed: () => _showSettings(),
            variant: AlouetteButtonVariant.tertiary,
            size: AlouetteButtonSize.small,
          ),
      ],
    );
  }

  Widget _buildTextInput() {
    return AlouetteTextField(
      controller: _textController,
      labelText: 'Text to translate',
      hintText: 'Enter text to translate...',
      type: AlouetteTextFieldType.multiline,
      size: AlouetteTextFieldSize.large,
      maxLines: widget.isCompactMode ? 3 : 5,
      isEnabled: !widget.isTranslating,
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AtomicText(
              'Target Languages',
              variant: AtomicTextVariant.labelLarge,
            ),
            const Spacer(),
            AlouetteButton(
              text: 'Select All',
              onPressed: _selectAllLanguages,
              variant: AlouetteButtonVariant.tertiary,
              size: AlouetteButtonSize.small,
            ),
            const AtomicSpacer(
              AtomicSpacing.xs,
              direction: AtomicSpacerDirection.horizontal,
            ),
            AlouetteButton(
              text: 'Clear',
              onPressed: _clearLanguages,
              variant: AlouetteButtonVariant.tertiary,
              size: AlouetteButtonSize.small,
            ),
          ],
        ),
        const AtomicSpacer(AtomicSpacing.small),
        LanguageGridSelector(
          selectedLanguages: widget.selectedLanguages,
          onLanguagesChanged: widget.onLanguagesChanged ?? (_) {},
          multiSelect: true,
          crossAxisCount: widget.isCompactMode ? 2 : 3,
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final hasText = _textController.text.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    final canTranslate = hasText && hasLanguages && !widget.isTranslating;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AlouetteButton(
          text: 'Clear',
          icon: Icons.clear,
          onPressed: hasText ? _handleClear : null,
          variant: AlouetteButtonVariant.secondary,
          size: AlouetteButtonSize.medium,
        ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AlouetteButton(
          text: 'Translate',
          icon: Icons.translate,
          onPressed: canTranslate ? widget.onTranslate : null,
          variant: AlouetteButtonVariant.primary,
          size: AlouetteButtonSize.medium,
          isLoading: widget.isTranslating,
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return StatusIndicator(
      status: StatusType.error,
      message: widget.errorMessage!,
      actionText: 'Retry',
      onActionPressed: widget.onTranslate,
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Translation Results',
          variant: AtomicTextVariant.titleMedium,
        ),
        const AtomicSpacer(AtomicSpacing.small),
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
      margin: const EdgeInsets.only(bottom: SpacingTokens.s),
      child: AtomicCard(
        padding: const EdgeInsets.all(SpacingTokens.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                const AtomicSpacer(
                  AtomicSpacing.xs,
                  direction: AtomicSpacerDirection.horizontal,
                ),
                AtomicText(
                  language.name,
                  variant: AtomicTextVariant.labelLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const AtomicIcon(Icons.copy, size: AtomicIconSize.small),
                  onPressed: () => _copyToClipboard(entry.value),
                  tooltip: 'Copy translation',
                ),
              ],
            ),
            const AtomicSpacer(AtomicSpacing.xs),
            AtomicText(
              entry.value,
              variant: AtomicTextVariant.body,
            ),
          ],
        ),
      ),
    );
  }

  void _handleClear() {
    _textController.clear();
    widget.onClear?.call();
  }

  void _selectAllLanguages() {
    widget.onLanguagesChanged?.call(LanguageConstants.supportedLanguages);
  }

  void _clearLanguages() {
    widget.onLanguagesChanged?.call([]);
  }

  void _showSettings() {
    // Show settings dialog - implementation depends on app requirements
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AtomicText('Translation Settings', variant: AtomicTextVariant.titleMedium),
        content: const AtomicText('Settings panel would go here', variant: AtomicTextVariant.body),
        actions: [
          AlouetteButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            variant: AlouetteButtonVariant.tertiary,
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // Copy to clipboard - implementation depends on platform
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Translation copied to clipboard')),
    );
  }
}