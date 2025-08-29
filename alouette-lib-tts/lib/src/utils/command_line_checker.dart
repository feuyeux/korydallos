import 'dart:io';

/// 命令行工具检查器
class CommandLineChecker {
  /// 检查命令是否可用
  static Future<bool> isCommandAvailable(String command) async {
    try {
      // 首先检查环境变量中的完整路径
      final path = Platform.environment['PATH'] ?? '';
      final homeDir = Platform.environment['HOME'] ?? '';

      // 添加一些常见的二进制位置
      final commonPaths = [
        '/usr/local/bin',
        '/usr/bin',
        '/bin',
        '$homeDir/.local/bin',
        '$homeDir/miniconda3/bin',
        '$homeDir/anaconda3/bin',
      ];

      // 将这些路径添加到搜索路径中
      final searchPaths = path.split(':')..addAll(commonPaths);

      // 检查命令是否存在于任何这些路径中
      for (final dir in searchPaths) {
        final commandPath = '$dir/$command';
        if (await File(commandPath).exists()) {
          return true;
        }
      }

      // 如果没找到，尝试使用 which 命令（这会使用系统的PATH）
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
