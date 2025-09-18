import 'package:flutter/material.dart';
import '../../tokens/app_tokens.dart';
import '../atoms/atomic_elements.dart';
import '../atoms/alouette_button.dart';
import '../atoms/alouette_text_field.dart';
import '../molecules/status_indicator.dart';

/// Configuration Dialog Organism
///
/// Complex dialog for configuring application settings including
/// LLM providers, TTS engines, and other preferences.
class ConfigDialog extends StatefulWidget {
  final String title;
  final List<ConfigSection> sections;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onReset;
  final bool isSaving;
  final String? errorMessage;

  const ConfigDialog({
    super.key,
    required this.title,
    required this.sections,
    this.onSave,
    this.onCancel,
    this.onReset,
    this.isSaving = false,
    this.errorMessage,
  });

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.sections.length,
      vsync: this,
    );
    // Tab controller listener can be added here if needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const AtomicSpacer(AtomicSpacing.medium),
            if (widget.errorMessage != null) ...[
              _buildErrorDisplay(),
              const AtomicSpacer(AtomicSpacing.medium),
            ],
            _buildTabs(),
            const AtomicSpacer(AtomicSpacing.medium),
            Expanded(child: _buildContent()),
            const AtomicSpacer(AtomicSpacing.medium),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const AtomicIcon(
          Icons.settings,
          size: AtomicIconSize.medium,
        ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AtomicText(
          widget.title,
          variant: AtomicTextVariant.titleLarge,
        ),
        const Spacer(),
        IconButton(
          icon: const AtomicIcon(Icons.close, size: AtomicIconSize.small),
          onPressed: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return StatusIndicator(
      status: StatusType.error,
      message: widget.errorMessage!,
    );
  }

  Widget _buildTabs() {
    if (widget.sections.length <= 1) {
      return const SizedBox.shrink();
    }

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: widget.sections.map((section) => Tab(
        text: section.title,
        icon: section.icon != null ? AtomicIcon(section.icon!, size: AtomicIconSize.small) : null,
      )).toList(),
    );
  }

  Widget _buildContent() {
    if (widget.sections.length <= 1) {
      return _buildSectionContent(widget.sections.first);
    }

    return TabBarView(
      controller: _tabController,
      children: widget.sections.map(_buildSectionContent).toList(),
    );
  }

  Widget _buildSectionContent(ConfigSection section) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.description != null) ...[
            AtomicText(
              section.description!,
              variant: AtomicTextVariant.bodySmall,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AtomicSpacer(AtomicSpacing.medium),
          ],
          ...section.fields.map(_buildField),
        ],
      ),
    );
  }

  Widget _buildField(ConfigField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (field.type) {
            ConfigFieldType.text => _buildTextField(field),
            ConfigFieldType.password => _buildPasswordField(field),
            ConfigFieldType.number => _buildNumberField(field),
            ConfigFieldType.url => _buildUrlField(field),
            ConfigFieldType.dropdown => _buildDropdownField(field),
            ConfigFieldType.toggle => _buildToggleField(field),
            ConfigFieldType.slider => _buildSliderField(field),
          },
        ],
      ),
    );
  }

  Widget _buildTextField(ConfigField field) {
    return AlouetteTextField(
      controller: field.controller,
      labelText: field.label,
      hintText: field.hint,
      helperText: field.description,
      errorText: field.errorText,
      isRequired: field.isRequired,
      isEnabled: !widget.isSaving,
      type: AlouetteTextFieldType.text,
    );
  }

  Widget _buildPasswordField(ConfigField field) {
    return AlouetteTextField(
      controller: field.controller,
      labelText: field.label,
      hintText: field.hint,
      helperText: field.description,
      errorText: field.errorText,
      isRequired: field.isRequired,
      isEnabled: !widget.isSaving,
      type: AlouetteTextFieldType.password,
    );
  }

  Widget _buildNumberField(ConfigField field) {
    return AlouetteTextField(
      controller: field.controller,
      labelText: field.label,
      hintText: field.hint,
      helperText: field.description,
      errorText: field.errorText,
      isRequired: field.isRequired,
      isEnabled: !widget.isSaving,
      type: AlouetteTextFieldType.number,
    );
  }

  Widget _buildUrlField(ConfigField field) {
    return AlouetteTextField(
      controller: field.controller,
      labelText: field.label,
      hintText: field.hint,
      helperText: field.description,
      errorText: field.errorText,
      isRequired: field.isRequired,
      isEnabled: !widget.isSaving,
      type: AlouetteTextFieldType.url,
    );
  }

  Widget _buildDropdownField(ConfigField field) {
    // Implementation would depend on dropdown options
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(DimensionTokens.radiusL),
      ),
      child: AtomicText(
        'Dropdown: ${field.label}',
        variant: AtomicTextVariant.body,
      ),
    );
  }

  Widget _buildToggleField(ConfigField field) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtomicText(
                field.label,
                variant: AtomicTextVariant.labelMedium,
              ),
              if (field.description != null) ...[
                const AtomicSpacer(AtomicSpacing.xs),
                AtomicText(
                  field.description!,
                  variant: AtomicTextVariant.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: field.boolValue ?? false,
          onChanged: widget.isSaving ? null : field.onBoolChanged,
        ),
      ],
    );
  }

  Widget _buildSliderField(ConfigField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtomicText(
          field.label,
          variant: AtomicTextVariant.labelMedium,
        ),
        if (field.description != null) ...[
          const AtomicSpacer(AtomicSpacing.xs),
          AtomicText(
            field.description!,
            variant: AtomicTextVariant.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
        const AtomicSpacer(AtomicSpacing.small),
        Slider(
          value: field.doubleValue ?? 0.0,
          min: field.minValue ?? 0.0,
          max: field.maxValue ?? 1.0,
          divisions: field.divisions,
          label: field.valueFormatter?.call(field.doubleValue ?? 0.0),
          onChanged: widget.isSaving ? null : field.onDoubleChanged,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onReset != null)
          AlouetteButton(
            text: 'Reset',
            onPressed: widget.isSaving ? null : widget.onReset,
            variant: AlouetteButtonVariant.tertiary,
          ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AlouetteButton(
          text: 'Cancel',
          onPressed: widget.isSaving ? null : widget.onCancel,
          variant: AlouetteButtonVariant.secondary,
        ),
        const AtomicSpacer(
          AtomicSpacing.small,
          direction: AtomicSpacerDirection.horizontal,
        ),
        AlouetteButton(
          text: 'Save',
          onPressed: widget.onSave,
          variant: AlouetteButtonVariant.primary,
          isLoading: widget.isSaving,
        ),
      ],
    );
  }
}

/// Configuration section model
class ConfigSection {
  final String title;
  final String? description;
  final IconData? icon;
  final List<ConfigField> fields;

  const ConfigSection({
    required this.title,
    this.description,
    this.icon,
    required this.fields,
  });
}

/// Configuration field model
class ConfigField {
  final String label;
  final String? hint;
  final String? description;
  final String? errorText;
  final bool isRequired;
  final ConfigFieldType type;
  final TextEditingController? controller;
  final bool? boolValue;
  final ValueChanged<bool>? onBoolChanged;
  final double? doubleValue;
  final ValueChanged<double>? onDoubleChanged;
  final double? minValue;
  final double? maxValue;
  final int? divisions;
  final String Function(double)? valueFormatter;

  const ConfigField({
    required this.label,
    this.hint,
    this.description,
    this.errorText,
    this.isRequired = false,
    required this.type,
    this.controller,
    this.boolValue,
    this.onBoolChanged,
    this.doubleValue,
    this.onDoubleChanged,
    this.minValue,
    this.maxValue,
    this.divisions,
    this.valueFormatter,
  });
}

/// Configuration field type enumeration
enum ConfigFieldType {
  text,
  password,
  number,
  url,
  dropdown,
  toggle,
  slider,
}