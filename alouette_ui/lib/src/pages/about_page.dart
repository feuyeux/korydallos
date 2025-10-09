import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  final String appName;
  final String? copyright;

  const AboutPage({super.key, required this.appName, this.copyright});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'Loading...';
  String _flutterVersion = '3.24.0';
  String _dartVersion = 'Loading...';
  String _osVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _dartVersion = _getDartVersion();
        _osVersion = _getOSVersion();
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _dartVersion = _getDartVersion();
        _osVersion = _getOSVersion();
      });
    }
  }

  String _getDartVersion() {
    try {
      final version = Platform.version;
      return version.split(' ').first;
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getOSVersion() {
    try {
      if (kIsWeb) {
        return 'Web';
      }

      if (Platform.isMacOS) {
        return 'macOS ${Platform.operatingSystemVersion}';
      } else if (Platform.isWindows) {
        return 'Windows ${Platform.operatingSystemVersion}';
      } else if (Platform.isLinux) {
        return 'Linux ${Platform.operatingSystemVersion}';
      } else if (Platform.isAndroid) {
        return 'Android ${Platform.operatingSystemVersion}';
      } else if (Platform.isIOS) {
        return 'iOS ${Platform.operatingSystemVersion}';
      }

      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/alouette_rounded.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              Text(
                widget.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Version Information
              _buildInfoCard(context, [
                _buildInfoRow('应用版本', _appVersion),
                _buildInfoRow('Flutter版本', _flutterVersion),
                _buildInfoRow('Dart版本', _dartVersion),
                _buildInfoRow('OS版本', _osVersion),
              ]),
              const SizedBox(height: 32),

              // Copyright
              if (widget.copyright != null)
                Text(
                  widget.copyright!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
