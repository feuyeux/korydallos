import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class TranslationInputWidget extends StatelessWidget {
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final ValueChanged<List<String>> onLanguagesChanged;
  final VoidCallback onTranslate;
  final bool isTranslating;
  final bool isConfigured;

  const TranslationInputWidget({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    required this.onLanguagesChanged,
    required this.onTranslate,
    required this.isTranslating,
    required this.isConfigured,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input
            Expanded(
              flex: 3,
              child: TextField(
                controller: textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Language Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Languages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 70, // 增加宽度确保等宽
                      height: 32, // 固定高度
                      child: TextButton(
                        onPressed: () {
                          // 全选所有语言
                          final allLanguages = supportedLanguages.map((lang) => lang['name']!).toList();
                          onLanguagesChanged(allLanguages);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          minimumSize: const Size(70, 32), // 固定最小尺寸
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Select All', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 70, // 确保与全选按钮等宽
                      height: 32, // 固定高度
                      child: TextButton(
                        onPressed: () {
                          // 取消所有选择
                          onLanguagesChanged([]);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          minimumSize: const Size(70, 32), // 固定最小尺寸
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            
            Expanded(
              flex: 3,
              child: Scrollbar(
                thumbVisibility: true, // 始终显示滚动条
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: supportedLanguages.map((lang) {
                      final isSelected = selectedLanguages.contains(lang['name']);
                      return FilterChip(
                        label: Text(
                          lang['nativeName']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (selected) {
                          final newLanguages = List<String>.from(selectedLanguages);
                          if (selected) {
                            newLanguages.add(lang['name']!);
                          } else {
                            newLanguages.remove(lang['name']);
                          }
                          onLanguagesChanged(newLanguages);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Translate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isTranslating || !isConfigured) ? null : onTranslate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isTranslating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Translating...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Text('Translate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
