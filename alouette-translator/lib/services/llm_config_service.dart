import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/translation_models.dart';

/// LLM 配置服务，处理与 Ollama 和 LM Studio 的连接
class LLMConfigService {
  List<String> _availableModels = [];
  ConnectionStatus? _connectionStatus;
  bool _isTestingConnection = false;

  List<String> get availableModels => _availableModels;
  ConnectionStatus? get connectionStatus => _connectionStatus;
  bool get isTestingConnection => _isTestingConnection;

  /// 测试与 LLM 提供者的连接
  Future<Map<String, dynamic>> testConnection(LLMConfig config) async {
    if (_isTestingConnection) {
      return {
        'success': false,
        'message': 'Connection test is already in progress',
      };
    }

    _isTestingConnection = true;
    
    try {
      print('Testing connection to ${config.provider}...');
      
      List<String> models;
      
      switch (config.provider) {
        case 'ollama':
          models = await _connectOllama(config.serverUrl);
          break;
        case 'lmstudio':
          models = await _connectLMStudio(config.serverUrl, config.apiKey);
          break;
        default:
          throw Exception('Unsupported provider: ${config.provider}');
      }

      _availableModels = models;
      _connectionStatus = ConnectionStatus(
        success: true,
        message: 'Successfully connected to ${config.provider}',
        modelCount: models.length,
        timestamp: DateTime.now(),
      );

      print('✅ LLM connection successful: ${_connectionStatus!.message}');
      print('Available models: $_availableModels');

      return {
        'success': true,
        'models': _availableModels,
        'message': _connectionStatus!.message,
      };
    } catch (error) {
      print('❌ LLM connection failed: $error');
      
      final errorMsg = error.toString();
      _connectionStatus = ConnectionStatus(
        success: false,
        message: _formatConnectionError(errorMsg, config),
        timestamp: DateTime.now(),
      );

      return {
        'success': false,
        'message': _connectionStatus!.message,
      };
    } finally {
      _isTestingConnection = false;
    }
  }

  /// 连接到 Ollama 服务器
  Future<List<String>> _connectOllama(String serverUrl) async {
    final url = '${serverUrl.trimRight()}/api/tags';
    
    print('Sending request to Ollama: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = (data['models'] as List?)
          ?.map((model) => model['name'] as String)
          .toList() ?? [];
      
      print('Successfully retrieved ${models.length} models from Ollama server');
      return models;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 连接到 LM Studio 服务器
  Future<List<String>> _connectLMStudio(String serverUrl, String? apiKey) async {
    final url = '${serverUrl.trimRight()}/v1/models';
    
    print('Sending request to LM Studio: $url');
    
    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = (data['data'] as List?)
          ?.map((model) => model['id'] as String)
          .toList() ?? [];
      
      print('Successfully retrieved ${models.length} models from LM Studio server');
      return models;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 格式化连接错误信息
  String _formatConnectionError(String errorMsg, LLMConfig config) {
    if (errorMsg.contains('Connection refused') || errorMsg.contains('Connection timeout')) {
      return 'Cannot connect to ${config.provider} server at ${config.serverUrl}. Please check if the server is running and accessible.';
    } else if (errorMsg.contains('Unauthorized') || errorMsg.contains('401')) {
      return 'Authentication failed. Please check your API key for ${config.provider}.';
    } else if (errorMsg.contains('network') || errorMsg.contains('DNS')) {
      return 'Network error connecting to ${config.provider}. Please check your internet connection and server URL.';
    } else {
      return 'Connection failed: $errorMsg';
    }
  }

  /// 验证 LLM 配置
  Map<String, dynamic> validateConfig(LLMConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // 必填字段验证
    if (config.provider.isEmpty) {
      errors.add('Provider is required');
    }

    if (config.serverUrl.isEmpty) {
      errors.add('Server URL is required');
    }

    if (config.selectedModel.isEmpty) {
      errors.add('Model selection is required');
    }

    // URL 格式验证
    if (config.serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(config.serverUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          errors.add('Invalid server URL format');
        }
      } catch (e) {
        errors.add('Invalid server URL format');
      }
    }

    // 特定提供商的警告
    if (config.provider == 'lmstudio' && (config.apiKey == null || config.apiKey!.isEmpty)) {
      warnings.add('API key is recommended for LM Studio');
    }

    // URL 相关警告
    if (config.serverUrl.isNotEmpty) {
      if (config.serverUrl.contains('localhost') || config.serverUrl.contains('127.0.0.1')) {
        warnings.add('Using localhost - ensure the server is running on this machine');
      }

      if (config.serverUrl.startsWith('http:') && !config.serverUrl.contains('localhost')) {
        warnings.add('Using HTTP (not HTTPS) for remote server - consider using HTTPS for security');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// 获取推荐设置
  Map<String, dynamic> getRecommendedSettings(String provider, {bool isAndroid = false}) {
    final baseUrl = isAndroid ? 'http://192.168.1.100' : 'http://localhost';

    switch (provider) {
      case 'ollama':
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Ollama typically runs on port 11434',
          'setupInstructions': [
            'Install Ollama from https://ollama.ai',
            'Run "ollama serve" to start the server',
            'Pull a model with "ollama pull llama3.2" or similar'
          ]
        };

      case 'lmstudio':
        return {
          'serverUrl': '$baseUrl:1234',
          'apiKey': '',
          'description': 'LM Studio typically runs on port 1234',
          'setupInstructions': [
            'Install LM Studio from https://lmstudio.ai',
            'Load a model in LM Studio',
            'Start the local server from the server tab'
          ]
        };

      default:
        return {
          'serverUrl': '$baseUrl:11434',
          'apiKey': '',
          'description': 'Default configuration',
          'setupInstructions': []
        };
    }
  }

  /// 清除连接状态和模型
  void clearConnection() {
    _availableModels.clear();
    _connectionStatus = null;
  }
}
