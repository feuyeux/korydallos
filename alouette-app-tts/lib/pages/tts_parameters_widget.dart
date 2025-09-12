import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

/// TTS Parameters Widget for controlling speech rate, pitch and volume
class TTSParametersWidget extends StatefulWidget {
  final double rate;
  final double pitch;
  final double volume;
  final Function(double) onRateChanged;
  final Function(double) onPitchChanged;
  final Function(double) onVolumeChanged;

  const TTSParametersWidget({
    super.key,
    required this.rate,
    required this.pitch,
    required this.volume,
    required this.onRateChanged,
    required this.onPitchChanged,
    required this.onVolumeChanged,
  });

  @override
  State<TTSParametersWidget> createState() => _TTSParametersWidgetState();
}

class _TTSParametersWidgetState extends State<TTSParametersWidget> {
  late double _rate;
  late double _pitch;
  late double _volume;

  @override
  void initState() {
    super.initState();
    _rate = widget.rate;
    _pitch = widget.pitch;
    _volume = widget.volume;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppTheme.primaryColor,
                size: UISizes.iconSizeMedium,
              ),
              const SizedBox(width: UISizes.spacingS),
              Text(
                '语音参数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: UISizes.spacingM),
          
          // Rate slider
          _buildParameterSlider(
            icon: Icons.speed,
            label: '语速',
            value: _rate,
            min: 0.1,
            max: 3.0,
            divisions: 29,
            valueDisplay: '${_rate.toStringAsFixed(1)}x',
            onChanged: (value) {
              setState(() => _rate = value);
              widget.onRateChanged(value);
            },
          ),
          
          const SizedBox(height: UISizes.spacingM),
          
          // Pitch slider
          _buildParameterSlider(
            icon: Icons.piano,
            label: '音调',
            value: _pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            valueDisplay: '${_pitch.toStringAsFixed(1)}x',
            onChanged: (value) {
              setState(() => _pitch = value);
              widget.onPitchChanged(value);
            },
          ),
          
          const SizedBox(height: UISizes.spacingM),
          
          // Volume slider
          _buildParameterSlider(
            icon: Icons.volume_up,
            label: '音量',
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            valueDisplay: '${(_volume * 100).toInt()}%',
            onChanged: (value) {
              setState(() => _volume = value);
              widget.onVolumeChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParameterSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueDisplay,
    required Function(double) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sliderColor = AppTheme.primaryColor;
    final backgroundColor = isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05);
    
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sliderColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: sliderColor, size: 18),
        ),
        const SizedBox(width: UISizes.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UISizes.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: sliderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UISizes.borderRadiusS),
                    ),
                    child: Text(
                      valueDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sliderColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UISizes.spacingXs),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: sliderColor,
                  inactiveTrackColor: backgroundColor,
                  thumbColor: sliderColor,
                  overlayColor: sliderColor.withOpacity(0.2),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}