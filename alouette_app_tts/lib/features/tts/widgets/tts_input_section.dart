import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'dart:async';

/// Widget for text input and voice selection
class TTSInputSection extends StatefulWidget {
  final ITTSController controller;
  final TextEditingController textController;
  // Page-known language code, e.g. 'zh-CN', 'en-US'
  final String? language;

  const TTSInputSection({
    super.key,
    required this.controller,
    required this.textController,
    this.language,
  });

  @override
  State<TTSInputSection> createState() => _TTSInputSectionState();
}

class _TTSInputSectionState extends State<TTSInputSection> {
  StreamSubscription<bool>? _speakingSub;
  StreamSubscription<String?>? _errorSub;
  Timer? _voiceWatchTimer;
  String _voicesSignature = '';

  String _calcVoicesSignature(List<String> voices) {
    // 简单签名：长度 + 首尾元素，有变化即可触发重建
    if (voices.isEmpty) return '0';
    final first = voices.first;
    final last = voices.last;
    return '${voices.length}::$first::$last';
  }
  @override
  void initState() {
    super.initState();
    // Sync text controller with TTS controller
    widget.textController.addListener(_onTextChanged);

    // 初始记录 voices 签名
    _voicesSignature = _calcVoicesSignature(widget.controller.availableVoices);

    // 首帧后如未选中且有可用语音，自动选中第一个
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voices = widget.controller.availableVoices;
      final selected = widget.controller.selectedVoice;
      if (selected == null && voices.isNotEmpty) {
        widget.controller.setVoice(voices.first);
        if (mounted) setState(() {});
      }
      // Align selected voice with provided language if any
      _ensureVoiceMatchesLanguage();
    });

    // 监听 speaking / error 流，驱动 UI 重建（也利于捕捉初始化后的变化）
    _speakingSub = widget.controller.speakingStream.listen((_) {
      if (mounted) setState(() {});
    });
    _errorSub = widget.controller.errorStream.listen((_) {
      if (mounted) setState(() {});
    });

    // 初始化阶段短期轮询 voices 列表变化（语音异步加载完成后刷新 UI）
    _voiceWatchTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      final sig = _calcVoicesSignature(widget.controller.availableVoices);
      if (sig != _voicesSignature) {
        _voicesSignature = sig;
        if (mounted) setState(() {});
      }
      // Ensure voice matches provided language when voices are available
      _ensureVoiceMatchesLanguage();
      // 一旦加载到语音则停止轮询，避免常驻
      if (widget.controller.availableVoices.isNotEmpty) {
        t.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(TTSInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle language change from parent
    if (oldWidget.language != widget.language) {
      _ensureVoiceMatchesLanguage();
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _speakingSub?.cancel();
    _errorSub?.cancel();
    _voiceWatchTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.text = widget.textController.text;
  }

  // Ensure selectedVoice matches page-provided language (if any)
  void _ensureVoiceMatchesLanguage() {
    final lang = widget.language;
    if (lang == null || lang.isEmpty) return;
    final voices = widget.controller.availableVoices;
    if (voices.isEmpty) return;

    final prefix = '$lang-';
    final current = widget.controller.selectedVoice;
    if (current != null && current.startsWith(prefix)) return;

    final match = voices.firstWhere(
      (v) => v.startsWith(prefix),
      orElse: () => '',
    );
    if (match.isNotEmpty && match != current) {
      widget.controller.setVoice(match);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.text_fields, color: AppTheme.primaryColor, size: 14),
                const SizedBox(width: 3),
                const Text(
                  'Text Input',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Text input field
            Expanded(
              child: ModernTextField(
                controller: widget.textController,
                hintText: 'Enter text to speak...',
                maxLines: null,
                expands: true,
                enabled: true,
              ),
            ),

            const SizedBox(height: 6),

            // Voice selection
            widget.controller.availableVoices.isNotEmpty
                ? _buildVoiceSelector()
                : _buildVoiceLoading(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.record_voice_over, color: AppTheme.primaryColor, size: 14),
            const SizedBox(width: 3),
            const Text(
              'Voice Selection',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 6),
              Text('Loading voices...', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    // Filter voices based on selected language
    final allVoices = widget.controller.availableVoices;
    final filteredVoices = _getFilteredVoices(allVoices);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with language info
        Row(
          children: [
            Icon(
              Icons.record_voice_over,
              color: AppTheme.primaryColor,
              size: 14,
            ),
            const SizedBox(width: 3),
            Text(
              'Voice Selection${widget.language != null ? ' (${widget.language})' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${filteredVoices.length}/${allVoices.length}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Voice dropdown
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // Guard against invalid value not in filtered items
              value: widget.controller.selectedVoice != null &&
                      filteredVoices.contains(widget.controller.selectedVoice)
                  ? widget.controller.selectedVoice
                  : null,
              isExpanded: true,
              isDense: true,
              hint: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  filteredVoices.isEmpty 
                    ? 'No voices for ${widget.language ?? 'language'}'
                    : 'Select Voice',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              items: [
                // Add "No Selection" option
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'No Voice Selected',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                // Add filtered voices
                ...filteredVoices.map(
                  (voice) => DropdownMenuItem<String>(
                    value: voice,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _formatVoiceName(voice),
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: filteredVoices.isEmpty ? null : (String? voice) {
                // Allow null selection (deselection)
                if (voice != null) {
                  widget.controller.setVoice(voice);
                }
                if (mounted) setState(() {});
              },
              icon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_drop_down, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Filter voices based on the selected language
  List<String> _getFilteredVoices(List<String> allVoices) {
    final lang = widget.language;
    if (lang == null || lang.isEmpty) {
      return allVoices; // Show all voices if no language specified
    }
    
    // Filter voices that start with the language code
    final prefix = '$lang-';
    return allVoices.where((voice) => voice.startsWith(prefix)).toList();
  }

  /// Format voice name for display (remove language prefix for cleaner look)
  String _formatVoiceName(String voice) {
    final lang = widget.language;
    if (lang != null && voice.startsWith('$lang-')) {
      // Remove language prefix for cleaner display
      return voice.substring(lang.length + 1);
    }
    return voice;
  }
}
