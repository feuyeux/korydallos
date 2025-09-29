import 'package:flutter/material.dart';
import '../constants/language_constants.dart';
import '../tokens/typography_tokens.dart';

class LanguageSelectionGrid extends StatelessWidget {
  final List<String> selectedLanguages;
  final Function(String, bool) onLanguageToggle;
  final ScrollController scrollController;

  const LanguageSelectionGrid({
    super.key,
    required this.selectedLanguages,
    required this.onLanguageToggle,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: GridView.builder(
        controller: scrollController,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          childAspectRatio: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 4,
        ),
        itemCount: LanguageConstants.supportedLanguages.length,
        itemBuilder: (context, index) {
          final lang = LanguageConstants.supportedLanguages[index];
          final isSelected = selectedLanguages.contains(lang.name);
          return FilterChip(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lang.nativeName,
                    style: TextStyle(
                        fontSize: TypographyTokens.bodySmallStyle.fontSize!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) => onLanguageToggle(lang.name, selected),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundColor: Colors.grey.shade100,
            showCheckmark: false, // 隐藏勾选标记
          );
        },
      ),
    );
  }
}
