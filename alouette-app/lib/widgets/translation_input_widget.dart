import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

import '../services/translation_service.dart';

class TranslationInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final VoidCallback onTranslate;
  final TranslationService translationService;
  final void Function(String language, bool selected) onLanguageToggle;
  final VoidCallback onReset;
  final VoidCallback onSelectAll;

  const TranslationInputWidget({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    required this.onTranslate,
    required this.translationService,
    required this.onLanguageToggle,
    required this.onReset,
    required this.onSelectAll,
  });

  @override
  State<TranslationInputWidget> createState() => _TranslationInputWidgetState();
}

class _TranslationInputWidgetState extends State<TranslationInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Text Input',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 文本输入框 - 减小高度
            Container(
              height: 60, // 进一步减小高度
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: widget.textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 6),

            // 语言选择 - 在正常布局下限制最大高度，但在空间受限时可收缩以避免溢出
            Flexible(
              fit: FlexFit.loose,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 110),
                child: _buildLanguageSelection(),
              ),
            ),

            const SizedBox(height: 6),

            // 翻译按钮
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable:
                    widget.translationService.isTranslatingNotifier,
                builder: (context, isTranslating, child) {
                  return ElevatedButton.icon(
                    onPressed: isTranslating ? null : widget.onTranslate,
                    icon: isTranslating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate, size: 16),
                    label: Text(
                      isTranslating ? 'Translating...' : 'Translate',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建语言选择区域
  Widget _buildLanguageSelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, size: 16),
              const SizedBox(width: 4),
              Text(
                'Target Languages',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                'Selected: ${widget.selectedLanguages.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 语言选择按钮 - 使用固定高度滚动，避免随chip行数改变导致整体高度波动
          SizedBox(
            height: 72,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: LanguageConstants.supportedLanguages.map((language) {
                  final isSelected =
                      widget.selectedLanguages.contains(language.code);
                  return FilterChip(
                    label: Text(
                      '${language.flag} ${language.name}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      // Delegate state change to parent via callback
                      widget.onLanguageToggle(language.code, selected);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // 快速选择按钮 - 更紧凑
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh, size: 12),
                label: const Text('Reset', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: widget.onSelectAll,
                icon: const Icon(Icons.select_all, size: 12),
                label: const Text('All', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
