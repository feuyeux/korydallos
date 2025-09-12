import 'dart:typed_data';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// 自定义TTS服务类，包装TTSService并添加speak方法
class CustomTTSService {
  final TTSService _service;
  String? _currentVoice;
  Function? _onComplete;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  CustomTTSService(this._service);
  
  /// 设置完成回调
  set onComplete(Function callback) {
    _onComplete = callback;
  }
  
  /// 设置当前语音
  Future<void> setVoice(String voice) async {
    _currentVoice = voice;
  }
  
  /// 设置语速
  Future<void> setSpeechRate(double rate) async {
    await _service.setRate(rate);
  }
  
  /// 设置音调
  Future<void> setPitch(double pitch) async {
    await _service.setPitch(pitch);
  }
  
  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
  }
  
  /// 获取语音列表
  Future<List<Voice>> getVoices() async {
    return await _service.getVoices();
  }
  
  /// 播放文本
  Future<void> speak(String text) async {
    if (_currentVoice == null) {
      throw Exception('Voice not set. Call setVoice() first.');
    }
    
    // 合成文本
    final Uint8List audioData = await _service.synthesizeText(text, _currentVoice!);
    
    // 播放音频
    await _audioPlayer.playBytes(audioData);
    
    // 模拟播放完成事件
    if (_onComplete != null) {
      Future.delayed(Duration(milliseconds: text.length * 50), () {
        _onComplete?.call();
      });
    }
  }
  
  /// 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  /// 获取当前引擎
  TTSEngineType? get currentEngine => _service.currentEngine;
  
  /// 获取当前后端
  String? get currentBackend => _service.currentBackend;
  
  /// 释放资源
  void dispose() {
    _service.dispose();
  }
}