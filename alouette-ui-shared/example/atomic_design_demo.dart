import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

/// Atomic Design Demo
///
/// This example demonstrates how to use the new atomic design components
/// to build consistent UI across all Alouette applications.
class AtomicDesignDemo extends StatefulWidget {
  const AtomicDesignDemo({super.key});

  @override
  State<AtomicDesignDemo> createState() => _AtomicDesignDemoState();
}

class _AtomicDesignDemoState extends State<AtomicDesignDemo> {
  final TextEditingController _textController = TextEditingController();
  List<LanguageOption> _selectedLanguages = [];
  VoiceModel? _selectedVoice;
  bool _isTranslating = false;
  bool _isPlaying = false;
  double _volume = 0.8;
  double _speechRate = 1.0;
  double _pitch = 1.0;

  final List<VoiceModel> _availableVoices = [
    VoiceModel(
      id: 'en-us-female',
      displayName: 'Emma (US)',
      languageCode: 'en-US',
      gender: VoiceGender.female,
      isNeural: true,
    ),
    VoiceModel(
      id: 'en-us-male',
      displayName: 'Brian (US)',
      languageCode: 'en-US',
      gender: VoiceGender.male,
      isNeural: true,
    ),
    VoiceModel(
      id: 'fr-fr-female',
      displayName: 'Céline (France)',
      languageCode: 'fr-FR',
      gender: VoiceGender.female,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoice = _availableVoices.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AtomicText(
          'Atomic Design Demo',
          variant: AtomicTextVariant.titleLarge,
        ),
        actions: [
          AlouetteButton(
            icon: Icons.settings,
            onPressed: _showConfigDialog,
            variant: AlouetteButtonVariant.tertiary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAtomsDemo(),
            const AtomicSpacer(AtomicSpacing.xl),
            _buildMoleculesDemo(),
            const AtomicSpacer(AtomicSpacing.xl),
            _buildOrganismsDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAtomsDemo() {
    return AtomicCard(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtomicText(
            'Atoms Demo',
            variant: AtomicTextVariant.headlineSmall,
          ),
          const AtomicSpacer(AtomicSpacing.medium),
          
          // Buttons
          const AtomicText('Buttons:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          Wrap(
            spacing: SpacingTokens.s,
            children: [
              AlouetteButton(
                text: 'Primary',
                onPressed: () {},
                variant: AlouetteButtonVariant.primary,
              ),
              AlouetteButton(
                text: 'Secondary',
                onPressed: () {},
                variant: AlouetteButtonVariant.secondary,
              ),
              AlouetteButton(
                text: 'Tertiary',
                onPressed: () {},
                variant: AlouetteButtonVariant.tertiary,
              ),
              AlouetteButton(
                text: 'Destructive',
                onPressed: () {},
                variant: AlouetteButtonVariant.destructive,
              ),
            ],
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Text Field
          const AtomicText('Text Fields:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          AlouetteTextField(
            labelText: 'Sample Input',
            hintText: 'Enter some text...',
            helperText: 'This is a helper text',
            prefixIcon: Icons.search,
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Slider
          const AtomicText('Sliders:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          AlouetteSlider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
            labelText: 'Volume',
            prefixIcon: Icons.volume_down,
            suffixIcon: Icons.volume_up,
            showValue: true,
            valueFormatter: (value) => '${(value * 100).round()}%',
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Progress Indicators
          const AtomicText('Progress Indicators:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          const Row(
            children: [
              AtomicProgressIndicator(
                type: AtomicProgressType.circular,
                size: AtomicProgressSize.small,
              ),
              AtomicSpacer(AtomicSpacing.small, direction: AtomicSpacerDirection.horizontal),
              AtomicProgressIndicator(
                type: AtomicProgressType.circular,
                size: AtomicProgressSize.medium,
              ),
              AtomicSpacer(AtomicSpacing.small, direction: AtomicSpacerDirection.horizontal),
              AtomicProgressIndicator(
                type: AtomicProgressType.circular,
                size: AtomicProgressSize.large,
              ),
            ],
          ),
          const AtomicSpacer(AtomicSpacing.small),
          const AtomicProgressIndicator(
            type: AtomicProgressType.linear,
            value: 0.6,
          ),
        ],
      ),
    );
  }

  Widget _buildMoleculesDemo() {
    return AtomicCard(
      padding: const EdgeInsets.all(SpacingTokens.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtomicText(
            'Molecules Demo',
            variant: AtomicTextVariant.headlineSmall,
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Language Selector
          const AtomicText('Language Selector:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          LanguageGridSelector(
            selectedLanguages: _selectedLanguages,
            onLanguagesChanged: (languages) => setState(() => _selectedLanguages = languages),
            crossAxisCount: 4,
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Voice Selector
          const AtomicText('Voice Selector:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          VoiceSelector(
            selectedVoice: _selectedVoice,
            availableVoices: _availableVoices,
            onVoiceChanged: (voice) => setState(() => _selectedVoice = voice),
          ),
          const AtomicSpacer(AtomicSpacing.medium),

          // Status Indicators
          const AtomicText('Status Indicators:', variant: AtomicTextVariant.labelLarge),
          const AtomicSpacer(AtomicSpacing.small),
          const StatusIndicator(
            status: StatusType.success,
            message: 'Operation completed successfully',
            actionText: 'View Details',
          ),
          const AtomicSpacer(AtomicSpacing.small),
          const StatusIndicator(
            status: StatusType.warning,
            message: 'Please check your configuration',
            actionText: 'Fix Now',
          ),
        ],
      ),
    );
  }

  Widget _buildOrganismsDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AtomicText(
          'Organisms Demo',
          variant: AtomicTextVariant.headlineSmall,
        ),
        const AtomicSpacer(AtomicSpacing.medium),

        // Translation Panel
        TranslationPanel(
          textController: _textController,
          selectedLanguages: _selectedLanguages,
          onLanguagesChanged: (languages) => setState(() => _selectedLanguages = languages),
          onTranslate: _handleTranslate,
          onClear: _handleClear,
          isTranslating: _isTranslating,
          isCompactMode: false,
        ),
        const AtomicSpacer(AtomicSpacing.xl),

        // TTS Control Panel
        TTSControlPanel(
          selectedVoice: _selectedVoice,
          availableVoices: _availableVoices,
          onVoiceChanged: (voice) => setState(() => _selectedVoice = voice),
          currentText: _textController.text.isNotEmpty ? _textController.text : null,
          onPlay: _handlePlay,
          onPause: _handlePause,
          onStop: _handleStop,
          isPlaying: _isPlaying,
          isPaused: false,
          isLoading: false,
          volume: _volume,
          onVolumeChanged: (value) => setState(() => _volume = value),
          speechRate: _speechRate,
          onSpeechRateChanged: (value) => setState(() => _speechRate = value),
          pitch: _pitch,
          onPitchChanged: (value) => setState(() => _pitch = value),
          showAdvancedControls: true,
        ),
      ],
    );
  }

  void _handleTranslate() {
    setState(() => _isTranslating = true);
    
    // Simulate translation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation completed!')),
        );
      }
    });
  }

  void _handleClear() {
    _textController.clear();
    setState(() => _selectedLanguages = []);
  }

  void _handlePlay() {
    setState(() => _isPlaying = true);
    
    // Simulate TTS playback
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  void _handlePause() {
    setState(() => _isPlaying = false);
  }

  void _handleStop() {
    setState(() => _isPlaying = false);
  }

  void _showConfigDialog() {
    final sections = [
      ConfigSection(
        title: 'General',
        description: 'General application settings',
        icon: Icons.settings,
        fields: [
          ConfigField(
            label: 'API Key',
            hint: 'Enter your API key',
            type: ConfigFieldType.password,
            controller: TextEditingController(),
            isRequired: true,
          ),
          ConfigField(
            label: 'Server URL',
            hint: 'https://api.example.com',
            type: ConfigFieldType.url,
            controller: TextEditingController(),
          ),
          ConfigField(
            label: 'Enable Notifications',
            type: ConfigFieldType.toggle,
            boolValue: true,
            onBoolChanged: (value) {},
          ),
        ],
      ),
      ConfigSection(
        title: 'Advanced',
        description: 'Advanced configuration options',
        icon: Icons.tune,
        fields: [
          ConfigField(
            label: 'Timeout (seconds)',
            type: ConfigFieldType.number,
            controller: TextEditingController(text: '30'),
          ),
          ConfigField(
            label: 'Quality',
            type: ConfigFieldType.slider,
            doubleValue: 0.8,
            minValue: 0.0,
            maxValue: 1.0,
            divisions: 10,
            onDoubleChanged: (value) {},
            valueFormatter: (value) => '${(value * 100).round()}%',
          ),
        ],
      ),
    ];

    showDialog(
      context: context,
      builder: (context) => ConfigDialog(
        title: 'Settings',
        sections: sections,
        onSave: () => Navigator.of(context).pop(),
        onCancel: () => Navigator.of(context).pop(),
        onReset: () {},
      ),
    );
  }
}