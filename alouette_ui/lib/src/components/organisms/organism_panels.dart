import 'package:flutter/material.dart';
import '../../constants/language_constants.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/atomic_button.dart';
import '../atoms/atomic_input.dart';
import '../molecules/molecular_components.dart';

/// Organism Translation Panel Component
///
/// Complex component that handles translation input, language selection,
/// and translation controls in a cohesive interface.
class OrganismTranslationPanel extends StatefulWidget {
  final TextEditingController? textController;
  final List<String> selectedLanguages;
  final ValueChanged<List<String>>? onLanguagesChanged;
  final VoidCallback? onTranslate;
  final VoidCallback? onClear;
  final bool isTranslating;
  final bool isCompactMode;

  const OrganismTranslationPanel({
    super.key,
    this.textController,
    required this.selectedLanguages,
    this.onLanguagesChanged,
    this.onTranslate,
    this.onClear,
    this.isTranslating = false,
    this.isCompactMode = false,
  });

  @override
  State<OrganismTranslationPanel> createState() =>
      _OrganismTranslationPanelState();
}

class _OrganismTranslationPanelState extends State<OrganismTranslationPanel> {
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
    return Card(
      child: Padding(
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
          ],
        ),
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
        const Spacer(),
        if (widget.isCompactMode)
          AtomicButton(
            icon: Icons.settings,
            onPressed: () {
              // Show settings dialog
            },
            variant: AtomicButtonVariant.tertiary,
            size: AtomicButtonSize.small,
          ),
      ],
    );
  }

  Widget _buildTextInput() {
    return AtomicInput(
      controller: _textController,
      labelText: 'Text to translate',
      hintText: 'Enter text to translate...',
      type: AtomicInputType.multiline,
      size: AtomicInputSize.large,
      maxLines: widget.isCompactMode ? 3 : 5,
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
            AtomicButton(
              text: 'Select All',
              onPressed: _selectAllLanguages,
              variant: AtomicButtonVariant.tertiary,
              size: AtomicButtonSize.small,
            ),
            const AtomicSpacer(
              AtomicSpacing.xs,
              direction: AtomicSpacerDirection.horizontal,
            ),
            AtomicButton(
              text: 'Clear',
              onPressed: _clearLanguages,
              variant: AtomicButtonVariant.tertiary,
              size: AtomicButtonSize.small,
            ),
          ],
        ),
        const AtomicSpacer(AtomicSpacing.small),
        _buildLanguageChips(),
      ],
    );
  }

  Widget _buildLanguageChips() {
    return Wrap(
      spacing: SpacingTokens.xs,
      runSpacing: SpacingTokens.xs,
      children: LanguageConstants.supportedLanguages.map((language) {
        final isSelected = widget.selectedLanguages.contains(language.code);

        return MolecularLanguageChip(
          languageCode: language.code,
          languageName: language.name,
          languageFlag: language.flag,
          isSelected: isSelected,
          onChanged: (selected) => _toggleLanguage(language.code, selected),
        );
      }).toList(),
    );
  }

  Widget _buildActionBar() {
    final hasText = _textController.text.isNotEmpty;
    final hasLanguages = widget.selectedLanguages.isNotEmpty;
    final canTranslate = hasText && hasLanguages && !widget.isTranslating;

    return MolecularActionBar(
      actions: [
        MolecularActionBarItem(
          text: 'Clear',
          icon: Icons.clear,
          onPressed: hasText ? widget.onClear : null,
          variant: AtomicButtonVariant.secondary,
        ),
        MolecularActionBarItem(
          text: 'Translate',
          icon: Icons.translate,
          onPressed: canTranslate ? widget.onTranslate : null,
          variant: AtomicButtonVariant.primary,
          isLoading: widget.isTranslating,
        ),
      ],
    );
  }

  void _toggleLanguage(String languageCode, bool selected) {
    if (widget.onLanguagesChanged == null) return;

    final languages = List<String>.from(widget.selectedLanguages);
    if (selected) {
      if (!languages.contains(languageCode)) {
        languages.add(languageCode);
      }
    } else {
      languages.remove(languageCode);
    }
    widget.onLanguagesChanged!(languages);
  }

  void _selectAllLanguages() {
    if (widget.onLanguagesChanged == null) return;

    final allLanguages =
        LanguageConstants.supportedLanguages.map((lang) => lang.code).toList();
    widget.onLanguagesChanged!(allLanguages);
  }

  void _clearLanguages() {
    if (widget.onLanguagesChanged == null) return;
    widget.onLanguagesChanged!([]);
  }
}

/// Organism TTS Control Panel Component
///
/// Complex component for TTS controls including voice selection,
/// playback controls, and volume adjustment.
class OrganismTTSControlPanel extends StatefulWidget {
  final String? selectedVoice;
  final List<String> availableVoices;
  final ValueChanged<String?>? onVoiceChanged;
  final String? currentText;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final bool isPlaying;
  final bool isPaused;
  final bool isLoading;
  final double volume;
  final ValueChanged<double>? onVolumeChanged;

  const OrganismTTSControlPanel({
    super.key,
    this.selectedVoice,
    required this.availableVoices,
    this.onVoiceChanged,
    this.currentText,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.isPlaying = false,
    this.isPaused = false,
    this.isLoading = false,
    this.volume = 1.0,
    this.onVolumeChanged,
  });

  @override
  State<OrganismTTSControlPanel> createState() =>
      _OrganismTTSControlPanelState();
}

class _OrganismTTSControlPanelState extends State<OrganismTTSControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const AtomicSpacer(AtomicSpacing.medium),
            _buildVoiceSelection(),
            const AtomicSpacer(AtomicSpacing.medium),
            _buildPlaybackControls(),
            const AtomicSpacer(AtomicSpacing.medium),
            _buildVolumeControl(),
            if (widget.currentText != null) ...[
              const AtomicSpacer(AtomicSpacing.medium),
              _buildTextPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const AtomicIcon(
          Icons.record_voice_over,
          size: AtomicIconSize.medium,
        ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        const AtomicText(
          'Text-to-Speech',
          variant: AtomicTextVariant.titleMedium,
        ),
        const Spacer(),
        if (widget.isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildVoiceSelection() {
    if (widget.availableVoices.isEmpty) {
      return MolecularStatusIndicator(
        status: MolecularStatusType.warning,
        message: 'No voices available',
        actionText: 'Retry',
        onActionPressed: () {
          // Trigger voice refresh
        },
      );
    }

    final voiceItems = widget.availableVoices.map((voice) {
      return AtomicDropdownItem<String>(
        value: voice,
        text: voice,
        icon: Icons.person,
      );
    }).toList();

    return AtomicDropdown<String>(
      value: widget.selectedVoice,
      items: voiceItems,
      onChanged: widget.onVoiceChanged,
      labelText: 'Voice',
      hintText: 'Select a voice',
    );
  }

  Widget _buildPlaybackControls() {
    final canPlay = widget.currentText != null &&
        widget.selectedVoice != null &&
        !widget.isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AtomicButton(
          icon: widget.isPlaying && !widget.isPaused
              ? Icons.pause
              : Icons.play_arrow,
          onPressed: canPlay
              ? (widget.isPlaying && !widget.isPaused
                  ? widget.onPause
                  : widget.onPlay)
              : null,
          variant: AtomicButtonVariant.primary,
          size: AtomicButtonSize.large,
        ),
        const AtomicSpacer(
          AtomicSpacing.medium,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AtomicButton(
          icon: Icons.stop,
          onPressed: widget.isPlaying ? widget.onStop : null,
          variant: AtomicButtonVariant.secondary,
          size: AtomicButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Volume',
          variant: AtomicTextVariant.labelMedium,
        ),
        const AtomicSpacer(AtomicSpacing.xs),
        Row(
          children: [
            const AtomicIcon(
              Icons.volume_down,
              size: AtomicIconSize.small,
            ),
            Expanded(
              child: Slider(
                value: widget.volume,
                onChanged: widget.onVolumeChanged,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(widget.volume * 100).round()}%',
              ),
            ),
            const AtomicIcon(
              Icons.volume_up,
              size: AtomicIconSize.small,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Text Preview',
          variant: AtomicTextVariant.labelMedium,
        ),
        const AtomicSpacer(AtomicSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SpacingTokens.m),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: AtomicText(
            widget.currentText!,
            variant: AtomicTextVariant.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
