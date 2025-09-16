import 'dart:math';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../constants/ui_constants.dart';
import '../widgets/modern_card.dart';

/// TTS status indicator component with modern design
class TTSStatusIndicator extends StatelessWidget {
  final bool isPlaying;

  const TTSStatusIndicator({
    super.key,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isPlaying
        ? AppTheme.primaryColor
        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600);
    final backgroundColor = isPlaying
        ? AppTheme.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1)
        : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100);
    final borderColor = isPlaying
        ? AppTheme.primaryColor.withOpacity(isDarkMode ? 0.4 : 0.3)
        : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300);

    return ModernCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UISizes.spacingM),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(UISizes.borderRadiusM),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                border: Border.all(
                  color: statusColor.withOpacity(isDarkMode ? 0.4 : 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.volume_up : Icons.volume_off,
                color: statusColor,
                size: UISizes.iconSizeMedium,
              ),
            ),

            const SizedBox(width: 8), // Reduced spacing to prevent overflow

            // Status text and animation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlaying ? 'Speaking...' : 'Ready to speak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: UISizes.spacingXs),
                  Text(
                    isPlaying
                        ? 'Tap pause to stop speaking'
                        : 'Enter text and tap play to start',
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Animation indicator
            if (isPlaying)
              SizedBox(
                width: 32,
                height: 32,
                child: _buildSpeakingAnimation(context),
              ),
          ],
        ),
      ),
    );
  }

  /// Build speaking animation with improved visuals
  Widget _buildSpeakingAnimation(BuildContext context) {
    final animationColor = AppTheme.primaryColor;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            // Create a more dynamic wave pattern
            final phase = (value + index * 0.33) % 1.0;
            final amplitude =
                sin(phase * 3.14 * 2) * 0.5 + 0.5; // Sine wave pattern
            final barHeight = 4.0 + (12.0 * amplitude);

            return Container(
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: animationColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
