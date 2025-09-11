import '../models/tts_config.dart';
import '../models/voice.dart';
import '../utils/tts_logger.dart';

/// 配置验证结果
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
  });

  /// 创建有效的验证结果
  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  /// 创建无效的验证结果
  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }

  /// 合并多个验证结果
  ValidationResult merge(ValidationResult other) {
    return ValidationResult(
      isValid: isValid && other.isValid,
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
      suggestions: [...suggestions, ...other.suggestions],
    );
  }

  /// 添加警告
  ValidationResult withWarnings(List<String> warnings) {
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: [...this.warnings, ...warnings],
      suggestions: suggestions,
    );
  }

  /// 添加建议
  ValidationResult withSuggestions(List<String> suggestions) {
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      suggestions: [...this.suggestions, ...suggestions],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult(isValid: $isValid)');
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    if (suggestions.isNotEmpty) {
      buffer.writeln('Suggestions:');
      for (final suggestion in suggestions) {
        buffer.writeln('  - $suggestion');
      }
    }
    
    return buffer.toString();
  }
}

/// 验证规则抽象基类
abstract class ValidationRule<T> {
  /// 规则名称
  String get name;
  
  /// 规则描述
  String get description;
  
  /// 验证值
  ValidationResult validate(T value);
}

/// 范围验证规则
class RangeValidationRule extends ValidationRule<double> {
  final double min;
  final double max;
  final String fieldName;
  
  RangeValidationRule({
    required this.min,
    required this.max,
    required this.fieldName,
  });
  
  @override
  String get name => 'Range Validation';
  
  @override
  String get description => '$fieldName must be between $min and $max';
  
  @override
  ValidationResult validate(double value) {
    if (value < min || value > max) {
      return ValidationResult.invalid([
        '$fieldName must be between $min and $max, got $value'
      ]);
    }
    
    final warnings = <String>[];
    final suggestions = <String>[];
    
    // 提供性能建议
    if (fieldName == 'defaultRate') {
      if (value < 0.5) {
        warnings.add('Very slow speech rate may affect user experience');
        suggestions.add('Consider using a rate between 0.8 and 1.2 for optimal listening');
      } else if (value > 2.0) {
        warnings.add('Very fast speech rate may be hard to understand');
        suggestions.add('Consider using a rate between 0.8 and 1.2 for optimal listening');
      }
    }
    
    return ValidationResult.valid()
        .withWarnings(warnings)
        .withSuggestions(suggestions);
  }
}

/// 字符串验证规则
class StringValidationRule extends ValidationRule<String> {
  final bool allowEmpty;
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final String fieldName;
  
  StringValidationRule({
    required this.fieldName,
    this.allowEmpty = false,
    this.minLength,
    this.maxLength,
    this.pattern,
  });
  
  @override
  String get name => 'String Validation';
  
  @override
  String get description => 'Validates string format for $fieldName';
  
  @override
  ValidationResult validate(String value) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    
    if (!allowEmpty && value.trim().isEmpty) {
      errors.add('$fieldName cannot be empty');
    }
    
    if (minLength != null && value.length < minLength!) {
      errors.add('$fieldName must be at least $minLength characters long');
    }
    
    if (maxLength != null && value.length > maxLength!) {
      errors.add('$fieldName cannot exceed $maxLength characters');
    }
    
    if (pattern != null && !pattern!.hasMatch(value)) {
      errors.add('$fieldName format is invalid');
    }
    
    // 特殊字段的建议
    if (fieldName == 'outputDirectory') {
      if (value.contains(' ')) {
        warnings.add('Output directory path contains spaces');
        suggestions.add('Consider using paths without spaces for better compatibility');
      }
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }
    
    return ValidationResult.valid()
        .withWarnings(warnings)
        .withSuggestions(suggestions);
  }
}

/// 格式验证规则
class FormatValidationRule extends ValidationRule<String> {
  static const Set<String> validFormats = {
    'mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac', 'opus'
  };
  
  @override
  String get name => 'Format Validation';
  
  @override
  String get description => 'Validates audio format';
  
  @override
  ValidationResult validate(String format) {
    final normalizedFormat = format.toLowerCase().trim();
    
    if (!validFormats.contains(normalizedFormat)) {
      return ValidationResult.invalid([
        'Unsupported audio format: $format. Supported formats: ${validFormats.join(', ')}'
      ]);
    }
    
    final warnings = <String>[];
    final suggestions = <String>[];
    
    // 格式特定建议
    switch (normalizedFormat) {
      case 'wav':
        warnings.add('WAV format produces large files');
        suggestions.add('Consider using MP3 for smaller file sizes');
        break;
      case 'flac':
        warnings.add('FLAC format may not be supported on all platforms');
        suggestions.add('Consider using MP3 or WAV for better compatibility');
        break;
      case 'opus':
        warnings.add('Opus format may have limited support');
        suggestions.add('Consider using MP3 for wider compatibility');
        break;
    }
    
    return ValidationResult.valid()
        .withWarnings(warnings)
        .withSuggestions(suggestions);
  }
}

/// 语音验证规则
class VoiceValidationRule extends ValidationRule<String> {
  final List<Voice>? availableVoices;
  
  VoiceValidationRule({this.availableVoices});
  
  @override
  String get name => 'Voice Validation';
  
  @override
  String get description => 'Validates voice availability';
  
  @override
  ValidationResult validate(String voiceName) {
    if (voiceName.trim().isEmpty) {
      return ValidationResult.invalid(['Voice name cannot be empty']);
    }
    
    // 如果没有可用语音列表，只做基本验证
    if (availableVoices == null || availableVoices!.isEmpty) {
      final warnings = ['Cannot verify voice availability - no voice list provided'];
      return ValidationResult.valid().withWarnings(warnings);
    }
    
    // 检查语音是否存在
    final voice = availableVoices!.where((v) => v.name == voiceName).firstOrNull;
    if (voice == null) {
      final availableNames = availableVoices!.take(5).map((v) => v.name).join(', ');
      return ValidationResult.invalid([
        'Voice "$voiceName" is not available. Available voices include: $availableNames${availableVoices!.length > 5 ? '...' : ''}'
      ]);
    }
    
    final suggestions = <String>[];
    
    // 语音质量建议
    if (voice.isNeural) {
      suggestions.add('Neural voice selected - high quality synthesis');
    } else if (voice.isStandard) {
      // 查找是否有同语言的神经网络语音
      final neuralAlternatives = availableVoices!
          .where((v) => v.language == voice.language && v.isNeural)
          .take(2)
          .map((v) => v.name)
          .toList();
      
      if (neuralAlternatives.isNotEmpty) {
        suggestions.add('Consider using neural voices for better quality: ${neuralAlternatives.join(', ')}');
      }
    }
    
    return ValidationResult.valid().withSuggestions(suggestions);
  }
}

/// TTS 配置验证器
class TTSConfigValidator {
  final List<Voice>? availableVoices;
  
  TTSConfigValidator({this.availableVoices});
  
  /// 验证完整配置
  ValidationResult validateConfig(TTSConfig config) {
    TTSLogger.debug('Validating TTS configuration');
    
    var result = ValidationResult.valid();
    
    // 验证各个字段
    result = result.merge(_validateVoice(config.defaultVoice));
    result = result.merge(_validateFormat(config.defaultFormat));
    result = result.merge(_validateRate(config.defaultRate));
    result = result.merge(_validatePitch(config.defaultPitch));
    result = result.merge(_validateVolume(config.defaultVolume));
    result = result.merge(_validateOutputDirectory(config.outputDirectory));
    result = result.merge(_validateFeatureFlags(config));
    
    // 配置一致性检查
    result = result.merge(_validateConsistency(config));
    
    TTSLogger.debug('Configuration validation completed - valid: ${result.isValid}, errors: ${result.errors.length}, warnings: ${result.warnings.length}');
    
    return result;
  }
  
  /// 验证语音设置
  ValidationResult _validateVoice(String voiceName) {
    final rule = VoiceValidationRule(availableVoices: availableVoices);
    return rule.validate(voiceName);
  }
  
  /// 验证音频格式
  ValidationResult _validateFormat(String format) {
    final rule = FormatValidationRule();
    return rule.validate(format);
  }
  
  /// 验证语速
  ValidationResult _validateRate(double rate) {
    final rule = RangeValidationRule(
      min: 0.1,
      max: 3.0,
      fieldName: 'defaultRate',
    );
    return rule.validate(rate);
  }
  
  /// 验证音调
  ValidationResult _validatePitch(double pitch) {
    final rule = RangeValidationRule(
      min: 0.5,
      max: 2.0,
      fieldName: 'defaultPitch',
    );
    return rule.validate(pitch);
  }
  
  /// 验证音量
  ValidationResult _validateVolume(double volume) {
    final rule = RangeValidationRule(
      min: 0.0,
      max: 1.0,
      fieldName: 'defaultVolume',
    );
    return rule.validate(volume);
  }
  
  /// 验证输出目录
  ValidationResult _validateOutputDirectory(String directory) {
    final rule = StringValidationRule(
      fieldName: 'outputDirectory',
      allowEmpty: false,
      minLength: 1,
      maxLength: 500,
    );
    return rule.validate(directory);
  }
  
  /// 验证功能标志
  ValidationResult _validateFeatureFlags(TTSConfig config) {
    final warnings = <String>[];
    final suggestions = <String>[];
    
    if (!config.enableCaching && !config.enablePlayback) {
      warnings.add('Both caching and playback are disabled');
      suggestions.add('Consider enabling at least one feature for better user experience');
    }
    
    if (config.enableCaching) {
      suggestions.add('Caching is enabled - this will improve performance for repeated text');
    }
    
    return ValidationResult.valid()
        .withWarnings(warnings)
        .withSuggestions(suggestions);
  }
  
  /// 验证配置一致性
  ValidationResult _validateConsistency(TTSConfig config) {
    final warnings = <String>[];
    final suggestions = <String>[];
    
    // 检查语音和格式的兼容性
    if (availableVoices != null) {
      final voice = availableVoices!.where((v) => v.name == config.defaultVoice).firstOrNull;
      if (voice != null) {
        // Web平台建议
        if (voice.locale.startsWith('ar-') && config.defaultFormat != 'mp3') {
          warnings.add('Arabic voices may have better compatibility with MP3 format');
        }
        
        // 移动平台建议
        if (voice.isNeural && config.defaultRate > 1.5) {
          suggestions.add('Neural voices may work better with moderate speech rates');
        }
      }
    }
    
    // 性能相关建议
    if (config.enableCaching && config.defaultFormat == 'wav') {
      warnings.add('WAV format with caching enabled may consume significant storage');
      suggestions.add('Consider using MP3 format with caching for better storage efficiency');
    }
    
    return ValidationResult.valid()
        .withWarnings(warnings)
        .withSuggestions(suggestions);
  }
  
  /// 快速验证（仅检查关键错误）
  ValidationResult quickValidate(TTSConfig config) {
    final errors = <String>[];
    
    if (config.defaultVoice.trim().isEmpty) {
      errors.add('defaultVoice cannot be empty');
    }
    
    if (config.defaultFormat.trim().isEmpty) {
      errors.add('defaultFormat cannot be empty');
    }
    
    if (config.defaultRate < 0.1 || config.defaultRate > 3.0) {
      errors.add('defaultRate must be between 0.1 and 3.0');
    }
    
    if (config.defaultPitch < 0.5 || config.defaultPitch > 2.0) {
      errors.add('defaultPitch must be between 0.5 and 2.0');
    }
    
    if (config.defaultVolume < 0.0 || config.defaultVolume > 1.0) {
      errors.add('defaultVolume must be between 0.0 and 1.0');
    }
    
    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }
    
    return ValidationResult.valid();
  }
  
  /// 生成配置建议
  List<String> generateRecommendations(TTSConfig config) {
    final recommendations = <String>[];
    
    // 基于当前配置的建议
    if (config.defaultRate == 1.0 && config.defaultPitch == 1.0) {
      recommendations.add('Default speech settings detected - consider personalizing rate and pitch');
    }
    
    if (config.outputDirectory == 'output') {
      recommendations.add('Using default output directory - consider specifying a custom path');
    }
    
    if (!config.enableCaching) {
      recommendations.add('Caching is disabled - enabling it can improve performance for repeated text');
    }
    
    // 基于语音的建议
    if (availableVoices != null) {
      final voice = availableVoices!.where((v) => v.name == config.defaultVoice).firstOrNull;
      if (voice != null) {
        if (voice.isStandard) {
          final neuralAlternatives = availableVoices!
              .where((v) => v.language == voice.language && v.isNeural)
              .length;
          if (neuralAlternatives > 0) {
            recommendations.add('$neuralAlternatives neural voice(s) available for ${voice.language} - consider upgrading for better quality');
          }
        }
      }
    }
    
    return recommendations;
  }
}