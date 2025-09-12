import 'package:alouette_lib_tts/alouette_tts.dart';
import 'dart:typed_data';
import 'tts_service_extension.dart';

/// 适配器类，将CustomTTSService转换为TTSService
class TTSServiceAdapter extends TTSService {
  final CustomTTSService _customService;
  
  TTSServiceAdapter(this._customService);
  
  @override
  Future<List<Voice>> getVoices() {
    return _customService.getVoices();
  }
  
  @override
  TTSEngineType? get currentEngine => _customService.currentEngine;
  
  @override
  String? get currentBackend => _customService.currentBackend;
  
  @override
  bool get isInitialized => true;
  
  @override
  Future<void> setRate(double rate) {
    return _customService.setSpeechRate(rate);
  }
  
  @override
  Future<void> setPitch(double pitch) {
    return _customService.setPitch(pitch);
  }
  
  @override
  Future<void> setVolume(double volume) {
    return _customService.setVolume(volume);
  }
  
  @override
  Future<Uint8List> synthesizeText(String text, String voiceName, {String format = 'mp3'}) {
    // 这里我们需要调用原始TTSService的synthesizeText方法
    // 但由于CustomTTSService没有直接暴露原始TTSService，我们需要在CustomTTSService中添加方法
    throw UnimplementedError('This method should not be called directly');
  }
  
  @override
  void dispose() {
    // 不要在这里调用dispose，因为CustomTTSService会负责释放资源
  }
}