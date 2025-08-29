import 'package:flutter/foundation.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;

/// 翻译服务，处理文本翻译逻辑 - 使用 alouette-lib-trans 库
class TranslationService {
  final trans_lib.TranslationService _translationService =
      trans_lib.TranslationService();
  final ValueNotifier<bool> _isTranslatingNotifier = ValueNotifier<bool>(false);

  trans_lib.TranslationResult? get currentTranslation =>
      _translationService.currentTranslation;
  bool get isTranslating => _isTranslatingNotifier.value;
  ValueNotifier<bool> get isTranslatingNotifier => _isTranslatingNotifier;

  /// 翻译文本到多个目标语言
  Future<trans_lib.TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    trans_lib.LLMConfig config,
  ) async {
    _isTranslatingNotifier.value = true;
    try {
      final result = await _translationService.translateText(
        inputText,
        targetLanguages,
        config,
      );
      return result;
    } finally {
      _isTranslatingNotifier.value = false;
    }
  }

  /// 获取当前翻译结果
  trans_lib.TranslationResult? getCurrentTranslation() {
    return _translationService.currentTranslation;
  }

  /// 清除当前翻译
  void clearTranslation() {
    _translationService.clearTranslation();
  }

  /// 获取翻译状态
  Map<String, dynamic> getTranslationState() {
    return _translationService.getTranslationState();
  }

  /// 格式化翻译结果用于显示
  Map<String, dynamic>? formatForDisplay(
      [trans_lib.TranslationResult? translation]) {
    return _translationService.formatForDisplay(translation);
  }
}
