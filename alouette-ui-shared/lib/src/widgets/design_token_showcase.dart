import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/dimension_tokens.dart';
import '../tokens/motion_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/effect_tokens.dart';
import '../services/theme_service.dart';

/// Widget that showcases the design token system
/// 
/// This widget demonstrates how to use design tokens consistently
/// across the application and serves as a reference for developers.
class DesignTokenShowcase extends StatelessWidget {
  const DesignTokenShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Token Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => _showThemeDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorSection(),
            const SizedBox(height: SpacingTokens.xxl),
            _buildTypographySection(),
            const SizedBox(height: SpacingTokens.xxl),
            _buildSpacingSection(),
            const SizedBox(height: SpacingTokens.xxl),
            _buildElevationSection(),
            const SizedBox(height: SpacingTokens.xxl),
            _buildEffectSection(),
            const SizedBox(height: SpacingTokens.xxl),
            _buildAnimationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colors',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        Wrap(
          spacing: SpacingTokens.s,
          runSpacing: SpacingTokens.s,
          children: [
            _buildColorSwatch('Primary', ColorTokens.primary),
            _buildColorSwatch('Secondary', ColorTokens.secondary),
            _buildColorSwatch('Tertiary', ColorTokens.tertiary),
            _buildColorSwatch('Error', ColorTokens.error),
            _buildColorSwatch('Success', ColorTokens.success),
            _buildColorSwatch('Warning', ColorTokens.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: EffectTokens.radiusSmall,
        boxShadow: ElevationTokens.shadowSubtle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.xs),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(DimensionTokens.radiusS),
                bottomRight: Radius.circular(DimensionTokens.radiusS),
              ),
            ),
            child: Text(
              name,
              style: TypographyTokens.labelSmallStyle.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typography',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display Large', style: TypographyTokens.displayLargeStyle),
            Text('Display Medium', style: TypographyTokens.displayMediumStyle),
            Text('Display Small', style: TypographyTokens.displaySmallStyle),
            const SizedBox(height: SpacingTokens.m),
            Text('Headline Large', style: TypographyTokens.headlineLargeStyle),
            Text('Headline Medium', style: TypographyTokens.headlineMediumStyle),
            Text('Headline Small', style: TypographyTokens.headlineSmallStyle),
            const SizedBox(height: SpacingTokens.m),
            Text('Title Large', style: TypographyTokens.titleLargeStyle),
            Text('Title Medium', style: TypographyTokens.titleMediumStyle),
            Text('Title Small', style: TypographyTokens.titleSmallStyle),
            const SizedBox(height: SpacingTokens.m),
            Text('Body Large', style: TypographyTokens.bodyLargeStyle),
            Text('Body Medium', style: TypographyTokens.bodyMediumStyle),
            Text('Body Small', style: TypographyTokens.bodySmallStyle),
            const SizedBox(height: SpacingTokens.m),
            Text('Label Large', style: TypographyTokens.labelLargeStyle),
            Text('Label Medium', style: TypographyTokens.labelMediumStyle),
            Text('Label Small', style: TypographyTokens.labelSmallStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spacing',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        Column(
          children: [
            _buildSpacingExample('XXS (2px)', SpacingTokens.xxs),
            _buildSpacingExample('XS (4px)', SpacingTokens.xs),
            _buildSpacingExample('S (8px)', SpacingTokens.s),
            _buildSpacingExample('M (12px)', SpacingTokens.m),
            _buildSpacingExample('L (16px)', SpacingTokens.l),
            _buildSpacingExample('XL (20px)', SpacingTokens.xl),
            _buildSpacingExample('XXL (24px)', SpacingTokens.xxl),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingExample(String name, double spacing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              name,
              style: TypographyTokens.labelMediumStyle,
            ),
          ),
          Container(
            width: spacing,
            height: 20,
            decoration: BoxDecoration(
              color: ColorTokens.primary,
              borderRadius: EffectTokens.radiusSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elevation',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        Wrap(
          spacing: SpacingTokens.l,
          runSpacing: SpacingTokens.l,
          children: [
            _buildElevationCard('Level 0', ElevationTokens.shadowNone),
            _buildElevationCard('Level 1', ElevationTokens.shadowSubtle),
            _buildElevationCard('Level 2', ElevationTokens.shadowLow),
            _buildElevationCard('Level 3', ElevationTokens.shadowMedium),
            _buildElevationCard('Level 4', ElevationTokens.shadowHigh),
            _buildElevationCard('Level 5', ElevationTokens.shadowVeryHigh),
          ],
        ),
      ],
    );
  }

  Widget _buildElevationCard(String name, List<BoxShadow> shadow) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: EffectTokens.radiusMedium,
        boxShadow: shadow,
      ),
      child: Center(
        child: Text(
          name,
          style: TypographyTokens.labelMediumStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEffectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effects',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        Wrap(
          spacing: SpacingTokens.l,
          runSpacing: SpacingTokens.l,
          children: [
            _buildGradientCard('Primary', EffectTokens.primaryGradient),
            _buildGradientCard('Secondary', EffectTokens.secondaryGradient),
            _buildGradientCard('Accent', EffectTokens.accentGradient),
            _buildGradientCard('Success', EffectTokens.successGradient),
            _buildGradientCard('Warning', EffectTokens.warningGradient),
            _buildGradientCard('Error', EffectTokens.errorGradient),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientCard(String name, LinearGradient gradient) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: EffectTokens.radiusMedium,
        boxShadow: ElevationTokens.shadowSubtle,
      ),
      child: Center(
        child: Text(
          name,
          style: TypographyTokens.labelMediumStyle.copyWith(
            color: Colors.white,
            fontWeight: TypographyTokens.weightSemiBold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Animations',
          style: TypographyTokens.headlineSmallStyle,
        ),
        const SizedBox(height: SpacingTokens.l),
        _AnimationDemo(),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Settings'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light Theme'),
                onTap: () {
                  ThemeService().setThemeMode(AlouetteThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Theme'),
                onTap: () {
                  ThemeService().setThemeMode(AlouetteThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_system_daydream),
                title: const Text('System Theme'),
                onTap: () {
                  ThemeService().setThemeMode(AlouetteThemeMode.system);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimationDemo extends StatefulWidget {
  @override
  State<_AnimationDemo> createState() => _AnimationDemoState();
}

class _AnimationDemoState extends State<_AnimationDemo>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: MotionTokens.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionTokens.emphasized,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionTokens.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: ColorTokens.primary,
                    borderRadius: EffectTokens.radiusMedium,
                    boxShadow: ElevationTokens.shadowMedium,
                  ),
                  child: const Icon(
                    Icons.animation,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: SpacingTokens.l),
        ElevatedButton(
          onPressed: () {
            if (_controller.isCompleted) {
              _controller.reverse();
            } else {
              _controller.forward();
            }
          },
          child: const Text('Animate'),
        ),
      ],
    );
  }
}