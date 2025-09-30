import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/voice_controller.dart';

/// Page for voice selection and management
class VoiceSelectionPage extends StatefulWidget {
  const VoiceSelectionPage({super.key});

  @override
  State<VoiceSelectionPage> createState() => _VoiceSelectionPageState();
}

class _VoiceSelectionPageState extends State<VoiceSelectionPage> {
  late VoiceController _voiceController;
  String _searchQuery = '';
  VoiceGender? _selectedGender;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _voiceController = VoiceController();
    _voiceController.loadVoices();
  }

  @override
  void dispose() {
    _voiceController.dispose();
    super.dispose();
  }

  List<VoiceModel> get _filteredVoices {
    return _voiceController.voices.where((voice) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!voice.displayName.toLowerCase().contains(query) &&
            !voice.id.toLowerCase().contains(query) &&
            !voice.languageCode.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Gender filter
      if (_selectedGender != null && voice.gender != _selectedGender) {
        return false;
      }

      // Language filter
      if (_selectedLanguage != null &&
          _selectedLanguage!.isNotEmpty &&
          !voice.languageCode.startsWith(_selectedLanguage!)) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> get _availableLanguages {
    final languages = _voiceController.voices
        .map((voice) => voice.languageCode.split('-').first)
        .toSet()
        .toList();
    languages.sort();
    return languages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Voice Selection',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _voiceController,
        builder: (context, child) {
          if (_voiceController.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading voices...'),
                ],
              ),
            );
          }

          if (_voiceController.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading voices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_voiceController.error!),
                  const SizedBox(height: 16),
                  ModernButton(
                    onPressed: _voiceController.loadVoices,
                    text: 'Retry',
                    type: ModernButtonType.primary,
                    size: ModernButtonSize.medium,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search voices...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filter row
                    Row(
                      children: [
                        // Gender filter
                        Expanded(
                          child: ModernDropdown<VoiceGender?>(
                            value: _selectedGender,
                            items: [
                              const DropdownMenuItem<VoiceGender?>(
                                value: null,
                                child: Text('All Genders'),
                              ),
                              ...VoiceGender.values.map(
                                (gender) => DropdownMenuItem<VoiceGender?>(
                                  value: gender,
                                  child: Text(gender.name.toUpperCase()),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            hint: 'Gender',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Language filter
                        Expanded(
                          child: ModernDropdown<String?>(
                            value: _selectedLanguage,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Languages'),
                              ),
                              ..._availableLanguages.map(
                                (lang) => DropdownMenuItem<String?>(
                                  value: lang,
                                  child: Text(lang.toUpperCase()),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                            },
                            hint: 'Language',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Voice list
              Expanded(
                child: _filteredVoices.isEmpty
                    ? const Center(
                        child: Text('No voices found matching the filters'),
                      )
                    : ListView.builder(
                        itemCount: _filteredVoices.length,
                        itemBuilder: (context, index) {
                          final voice = _filteredVoices[index];
                          final isSelected =
                              voice.id == _voiceController.selectedVoiceId;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4.0,
                            ),
                            child: ModernCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300],
                                  child: Icon(
                                    voice.gender == VoiceGender.male
                                        ? Icons.person
                                        : voice.gender == VoiceGender.female
                                        ? Icons.person_outline
                                        : Icons.record_voice_over,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                title: Text(
                                  voice.displayName.isNotEmpty
                                      ? voice.displayName
                                      : voice.id,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Language: ${voice.languageCode}'),
                                    Text('Gender: ${voice.gender.name}'),
                                    if (voice.isNeural)
                                      const Text(
                                        'Neural Voice',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Test voice button
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () =>
                                          _voiceController.testVoice(voice.id),
                                      tooltip: 'Test Voice',
                                    ),
                                    // Select button
                                    ModernButton(
                                      onPressed: () {
                                        _voiceController.selectVoice(voice.id);
                                        Navigator.of(context).pop(voice.id);
                                      },
                                      text: isSelected ? 'Selected' : 'Select',
                                      type: isSelected
                                          ? ModernButtonType.primary
                                          : ModernButtonType.secondary,
                                      size: ModernButtonSize.small,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _voiceController.selectVoice(voice.id);
                                  Navigator.of(context).pop(voice.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
