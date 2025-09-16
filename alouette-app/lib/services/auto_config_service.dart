import 'dart:convert';
import 'dart:io';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'package:logging/logging.dart';

class AutoConfigService {
  final Logger _logger = Logger('AutoConfigService');
  final LLMConfigService _llmConfigService = LLMConfigService();

  Future<LLMConfig?> attemptAutoConfiguration() async {
    _logger.info('Attempting auto-configuration...');
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        return await _configureForLinuxOrMac();
      } else if (Platform.isWindows) {
        return await _configureForWindows();
      }
    } catch (e) {
      _logger.severe('Auto-configuration failed', e);
    }
    return null;
  }

  Future<LLMConfig?> _configureForLinuxOrMac() async {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final ollamaConfig = File('$home/.ollama/config.json');
      if (await ollamaConfig.exists()) {
        _logger.info('Found ollama config at ${ollamaConfig.path}');
        final config = await _llmConfigService.loadConfig();
        if (config == null) {
          return null;
        }
        final updatedConfig = config.copyWith(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
        );
        await _llmConfigService.saveConfig(updatedConfig);
        return updatedConfig;
      }
    }
    return null;
  }

  Future<LLMConfig?> _configureForWindows() async {
    final home = Platform.environment['USERPROFILE'];
    if (home != null) {
      final ollamaConfig = File('$home\\.ollama\\config.json');
      if (await ollamaConfig.exists()) {
        _logger.info('Found ollama config at ${ollamaConfig.path}');
        final config = await _llmConfigService.loadConfig();
        if (config == null) {
          return null;
        }
        final updatedConfig = config.copyWith(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
        );
        await _llmConfigService.saveConfig(updatedConfig);
        return updatedConfig;
      }
    }
    return null;
  }

  Future<List<String>> fetchOllamaModels(String serverUrl) async {
    _logger.info('Fetching models from $serverUrl');
    try {
      final result = await Process.run('curl', ['$serverUrl/api/tags']);
      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout);
        if (data['models'] != null) {
          final models = (data['models'] as List)
              .map<String>((model) => model['name'] as String)
              .toList();
          _logger.info('Found models: $models');
          return models;
        }
      } else {
        _logger.warning(
          'Failed to fetch models: ${result.stderr} (exit code: ${result.exitCode})',
        );
      }
    } catch (e) {
      _logger.severe('Error fetching models', e);
    }
    return [];
  }
}
