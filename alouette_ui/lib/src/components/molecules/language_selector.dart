import 'package:flutter/material.dart';
import '../../constants/language_constants.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/atomic_input.dart';

/// Language Selector Molecule
///
/// Consolidated language selection component that replaces the existing
/// LanguageSelector widget with improved atomic design structure.
class LanguageSelector extends StatelessWidget {
  final LanguageOption selectedLanguage;
  final ValueChanged<LanguageOption?> onLanguageChanged;
  final String? labelText;
  final bool isRequired;
  final bool isEnabled;
  final String? errorText;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.labelText = 'Language',
    this.isRequired = false,
    this.isEnabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final items = LanguageConstants.supportedLanguages
        .map((language) => AtomicDropdownItem<LanguageOption>(
              value: language,
              text: language.name,
              icon: null, // We'll handle the flag separately
            ))
        .toList();

    return AtomicDropdown<LanguageOption>(
      value: selectedLanguage,
      items: items,
      onChanged: isEnabled ? onLanguageChanged : null,
      labelText: labelText,
      hintText: 'Select a language',
      errorText: errorText,
      isRequired: isRequired,
      isEnabled: isEnabled,
    );
  }
}

/// Language Grid Selector Molecule
///
/// Grid-based language selection for better visual presentation
class LanguageGridSelector extends StatelessWidget {
  final List<LanguageOption> selectedLanguages;
  final ValueChanged<List<LanguageOption>> onLanguagesChanged;
  final String? labelText;
  final bool multiSelect;
  final int crossAxisCount;

  const LanguageGridSelector({
    super.key,
    required this.selectedLanguages,
    required this.onLanguagesChanged,
    this.labelText = 'Languages',
    this.multiSelect = true,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          AtomicText(
            labelText!,
            variant: AtomicTextVariant.labelMedium,
          ),
          const AtomicSpacer(AtomicSpacing.small),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 200, // 增加最大高度
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: LanguageConstants.supportedLanguages.map((language) {
                final isSelected = selectedLanguages.contains(language);
                return LanguageChip(
                  language: language,
                  isSelected: isSelected,
                  onTap: () => _handleLanguageTap(language),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLanguageTap(LanguageOption language) {
    if (multiSelect) {
      final newSelection = List<LanguageOption>.from(selectedLanguages);
      if (newSelection.contains(language)) {
        newSelection.remove(language);
      } else {
        newSelection.add(language);
      }
      onLanguagesChanged(newSelection);
    } else {
      onLanguagesChanged([language]);
    }
  }
}

/// Language Chip Component
///
/// Individual language selection chip with flag and name
class LanguageChip extends StatelessWidget {
  final LanguageOption language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageChip({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Text(
        language.flag,
        style: const TextStyle(fontSize: 14),
      ),
      label: Text(
        language.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      showCheckmark: false, // 隐藏勾选标记
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.4),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}