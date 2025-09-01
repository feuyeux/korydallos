/// TTS Configuration class
/// 
/// Defines configuration parameters for TTS operations including
/// voice settings, output preferences, and feature toggles.
class TTSConfig {
  /// Default voice to use for synthesis
  final String defaultVoice;
  
  /// Default audio format (mp3, wav, etc.)
  final String defaultFormat;
  
  /// Default speech rate (slow, medium, fast, or numeric value)
  final String defaultRate;
  
  /// Default pitch (low, medium, high, or numeric value)
  final String defaultPitch;
  
  /// Default volume (quiet, medium, loud, or numeric value)
  final String defaultVolume;
  
  /// Directory for output files
  final String outputDirectory;
  
  /// Whether to enable audio caching
  final bool enableCaching;
  
  /// Whether to enable automatic playback after synthesis
  final bool enablePlayback;

  const TTSConfig({
    this.defaultVoice = 'en-US-AriaNeural',
    this.defaultFormat = 'mp3',
    this.defaultRate = 'medium',
    this.defaultPitch = 'medium',
    this.defaultVolume = 'medium',
    this.outputDirectory = 'output',
    this.enableCaching = true,
    this.enablePlayback = false,
  });

  /// Create TTSConfig from JSON map
  /// 
  /// Provides default values for missing keys and validates input types.
  factory TTSConfig.fromJson(Map<String, dynamic> json) {
    return TTSConfig(
      defaultVoice: _validateString(json['defaultVoice'], 'en-US-AriaNeural'),
      defaultFormat: _validateString(json['defaultFormat'], 'mp3'),
      defaultRate: _validateString(json['defaultRate'], 'medium'),
      defaultPitch: _validateString(json['defaultPitch'], 'medium'),
      defaultVolume: _validateString(json['defaultVolume'], 'medium'),
      outputDirectory: _validateString(json['outputDirectory'], 'output'),
      enableCaching: _validateBool(json['enableCaching'], true),
      enablePlayback: _validateBool(json['enablePlayback'], false),
    );
  }

  /// Convert TTSConfig to JSON map
  Map<String, dynamic> toJson() {
    return {
      'defaultVoice': defaultVoice,
      'defaultFormat': defaultFormat,
      'defaultRate': defaultRate,
      'defaultPitch': defaultPitch,
      'defaultVolume': defaultVolume,
      'outputDirectory': outputDirectory,
      'enableCaching': enableCaching,
      'enablePlayback': enablePlayback,
    };
  }

  /// Create a copy of this config with updated values
  TTSConfig copyWith({
    String? defaultVoice,
    String? defaultFormat,
    String? defaultRate,
    String? defaultPitch,
    String? defaultVolume,
    String? outputDirectory,
    bool? enableCaching,
    bool? enablePlayback,
  }) {
    return TTSConfig(
      defaultVoice: defaultVoice ?? this.defaultVoice,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultRate: defaultRate ?? this.defaultRate,
      defaultPitch: defaultPitch ?? this.defaultPitch,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      enableCaching: enableCaching ?? this.enableCaching,
      enablePlayback: enablePlayback ?? this.enablePlayback,
    );
  }

  /// Validate configuration parameters
  /// 
  /// Returns a list of validation errors, empty if valid.
  List<String> validate() {
    final errors = <String>[];
    
    if (defaultVoice.isEmpty) {
      errors.add('defaultVoice cannot be empty');
    }
    
    if (defaultFormat.isEmpty) {
      errors.add('defaultFormat cannot be empty');
    }
    
    if (!_isValidFormat(defaultFormat)) {
      errors.add('defaultFormat must be one of: mp3, wav, ogg, flac');
    }
    
    if (defaultRate.isEmpty) {
      errors.add('defaultRate cannot be empty');
    }
    
    if (!_isValidRate(defaultRate)) {
      errors.add('defaultRate must be slow, medium, fast, or a number between 0.1 and 3.0');
    }
    
    if (defaultPitch.isEmpty) {
      errors.add('defaultPitch cannot be empty');
    }
    
    if (!_isValidPitch(defaultPitch)) {
      errors.add('defaultPitch must be low, medium, high, or a number between 0.5 and 2.0');
    }
    
    if (defaultVolume.isEmpty) {
      errors.add('defaultVolume cannot be empty');
    }
    
    if (!_isValidVolume(defaultVolume)) {
      errors.add('defaultVolume must be quiet, medium, loud, or a number between 0.0 and 1.0');
    }
    
    if (outputDirectory.isEmpty) {
      errors.add('outputDirectory cannot be empty');
    }
    
    return errors;
  }

  /// Check if this config is valid
  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSConfig &&
        other.defaultVoice == defaultVoice &&
        other.defaultFormat == defaultFormat &&
        other.defaultRate == defaultRate &&
        other.defaultPitch == defaultPitch &&
        other.defaultVolume == defaultVolume &&
        other.outputDirectory == outputDirectory &&
        other.enableCaching == enableCaching &&
        other.enablePlayback == enablePlayback;
  }

  @override
  int get hashCode {
    return Object.hash(
      defaultVoice,
      defaultFormat,
      defaultRate,
      defaultPitch,
      defaultVolume,
      outputDirectory,
      enableCaching,
      enablePlayback,
    );
  }

  @override
  String toString() {
    return 'TTSConfig('
        'defaultVoice: $defaultVoice, '
        'defaultFormat: $defaultFormat, '
        'defaultRate: $defaultRate, '
        'defaultPitch: $defaultPitch, '
        'defaultVolume: $defaultVolume, '
        'outputDirectory: $outputDirectory, '
        'enableCaching: $enableCaching, '
        'enablePlayback: $enablePlayback'
        ')';
  }

  // Private validation helpers
  static String _validateString(dynamic value, String defaultValue) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return defaultValue;
  }

  static bool _validateBool(dynamic value, bool defaultValue) {
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }

  static bool _isValidFormat(String format) {
    const validFormats = {'mp3', 'wav', 'ogg', 'flac'};
    return validFormats.contains(format.toLowerCase());
  }

  static bool _isValidRate(String rate) {
    const validRates = {'slow', 'medium', 'fast'};
    if (validRates.contains(rate.toLowerCase())) {
      return true;
    }
    
    // Check if it's a valid numeric rate
    final numericRate = double.tryParse(rate);
    return numericRate != null && numericRate >= 0.1 && numericRate <= 3.0;
  }

  static bool _isValidPitch(String pitch) {
    const validPitches = {'low', 'medium', 'high'};
    if (validPitches.contains(pitch.toLowerCase())) {
      return true;
    }
    
    // Check if it's a valid numeric pitch
    final numericPitch = double.tryParse(pitch);
    return numericPitch != null && numericPitch >= 0.5 && numericPitch <= 2.0;
  }

  static bool _isValidVolume(String volume) {
    const validVolumes = {'quiet', 'medium', 'loud'};
    if (validVolumes.contains(volume.toLowerCase())) {
      return true;
    }
    
    // Check if it's a valid numeric volume
    final numericVolume = double.tryParse(volume);
    return numericVolume != null && numericVolume >= 0.0 && numericVolume <= 1.0;
  }
}