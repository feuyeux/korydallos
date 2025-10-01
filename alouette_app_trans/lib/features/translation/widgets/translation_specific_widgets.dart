import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// Translation-specific widgets that are unique to the translation application
/// These widgets extend or customize the shared UI components for translation-specific use cases

class TranslationAppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSettingsPressed;

  const TranslationAppHeader({
    super.key,
    required this.title,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.translate, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onSettingsPressed != null)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: onSettingsPressed,
            ),
        ],
      ),
    );
  }
}

class TranslationQuickActions extends StatelessWidget {
  final VoidCallback? onClearText;
  final VoidCallback? onPasteText;
  final VoidCallback? onCopyResult;
  final bool hasText;
  final bool hasResult;

  const TranslationQuickActions({
    super.key,
    this.onClearText,
    this.onPasteText,
    this.onCopyResult,
    this.hasText = false,
    this.hasResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.content_paste,
          label: 'Paste',
          onPressed: onPasteText,
        ),
        _buildActionButton(
          context,
          icon: Icons.clear,
          label: 'Clear',
          onPressed: hasText ? onClearText : null,
        ),
        _buildActionButton(
          context,
          icon: Icons.content_copy,
          label: 'Copy',
          onPressed: hasResult ? onCopyResult : null,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: onPressed != null
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class TranslationProgressIndicator extends StatelessWidget {
  final bool isTranslating;
  final String? statusMessage;

  const TranslationProgressIndicator({
    super.key,
    required this.isTranslating,
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTranslating) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage ?? 'Translating...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationStatsCard extends StatelessWidget {
  final int totalTranslations;
  final int successfulTranslations;
  final Duration? averageTime;

  const TranslationStatsCard({
    super.key,
    required this.totalTranslations,
    required this.successfulTranslations,
    this.averageTime,
  });

  @override
  Widget build(BuildContext context) {
    final successRate = totalTranslations > 0 
        ? (successfulTranslations / totalTranslations * 100).toStringAsFixed(1)
        : '0.0';

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translation Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(context, 'Total', totalTranslations.toString()),
                _buildStatItem(context, 'Success Rate', '$successRate%'),
                if (averageTime != null)
                  _buildStatItem(
                    context, 
                    'Avg Time', 
                    '${averageTime!.inMilliseconds}ms',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}