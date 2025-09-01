import 'dart:typed_data';
import '../models/voice.dart';

/// 统一的 TTS 处理器接口
/// 参照 hello-tts-dart 的 TTSProcessor 设计模式
abstract class TTSProcessor {
  /// 获取后端名称
  String get backend;

  /// 获取所有可用的语音列表
  Future<List<Voice>> getVoices();

  /// 文本转语音合成
  /// 
  /// [text] 要合成的文本
  /// [voiceName] 语音名称
  /// [format] 音频格式，默认为 'mp3'
  /// 
  /// 返回音频数据的字节数组
  Future<Uint8List> synthesizeText(
    String text, 
    String voiceName, {
    String format = 'mp3'
  });

  /// 停止当前的TTS播放
  /// 
  /// 尝试停止当前正在进行的语音合成或播放
  /// 不是所有的TTS引擎都支持停止功能
  Future<void> stop();

  /// 释放资源
  void dispose();
}