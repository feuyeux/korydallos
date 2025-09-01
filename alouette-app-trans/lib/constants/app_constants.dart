/// 支持的语言列表
const List<Map<String, String>> supportedLanguages = [
  {'code': 'en', 'name': 'English', 'nativeName': 'English'},
  {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
  {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語'},
  {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어'},
  {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
  {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
  {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
  {'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano'},
  {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
  {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
  {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
  {'code': 'el', 'name': 'Greek', 'nativeName': 'Ελληνικά'},
];

/// LLM 提供商列表
const List<Map<String, String>> llmProviders = [
  {'value': 'ollama', 'name': 'Ollama'},
  {'value': 'lmstudio', 'name': 'LM Studio'},
];

/// 默认端口配置
const Map<String, int> defaultPorts = {
  'ollama': 11434,
  'lmstudio': 1234,
};
