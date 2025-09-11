import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

/// Enhanced volume slider component
class EnhancedVolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const EnhancedVolumeSlider({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getVolumeIcon(volume),
                  size: UISizes.largeIconSize,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Volume',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(volume * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Volume slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 18,
            ),
            activeTrackColor: _getVolumeColor(volume),
            thumbColor: _getVolumeColor(volume),
            overlayColor: _getVolumeColor(volume).withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                size: UISizes.largeIconSize,
                color: Colors.grey.shade500,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: onVolumeChanged,
                ),
              ),
              Icon(
                Icons.volume_up,
                size: UISizes.largeIconSize,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        
        // Quick setting buttons
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickVolumeButton(context, '25%', 0.25),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '50%', 0.5),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '75%', 0.75),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '100%', 1.0),
          ],
        ),
      ],
    );
  }

  /// Build quick volume setting button
  Widget _buildQuickVolumeButton(BuildContext context, String label, double value) {
    final isSelected = (volume - value).abs() < 0.01;
    
    return GestureDetector(
      onTap: () => onVolumeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: TextStyles.smallFontSize + 1,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// Get icon based on volume level
  IconData _getVolumeIcon(double volume) {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 0.3) {
      return Icons.volume_mute;
    } else if (volume < 0.7) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  /// Get color based on volume level
  Color _getVolumeColor(double volume) {
    if (volume == 0) {
      return Colors.grey;
    } else if (volume < 0.3) {
      return Colors.orange;
    } else if (volume < 0.7) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}