/// Atomic Design - Organisms
///
/// This file exports all organism components (groups of molecules joined together)
/// following the atomic design methodology. Organisms are relatively complex UI
/// components composed of groups of molecules and/or atoms and/or other organisms.

// Organism components
export 'organism_panels.dart';
export 'translation_panel.dart';
export 'tts_control_panel.dart';
export 'config_dialog.dart';

// Re-export commonly used classes for convenience
export 'translation_panel.dart' show TranslationPanel;
export 'tts_control_panel.dart' show TTSControlPanel;
export 'config_dialog.dart' show 
    ConfigDialog,
    ConfigSection,
    ConfigField,
    ConfigFieldType;

// Legacy organism components (for backward compatibility)
export 'organism_panels.dart' show
    OrganismTranslationPanel,
    OrganismTTSControlPanel;