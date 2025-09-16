/// Alouette UI Shared Library
///
/// A comprehensive Flutter UI library providing reusable components,
/// services, and utilities for all Alouette applications.
///
/// Features:
/// - Atomic Design Component Architecture (Atoms, Molecules, Organisms)
/// - Design Token System for consistent styling
/// - Service Architecture with Dependency Injection
/// - Unified State Management Controllers
/// - TTS and Translation Service Integration
library alouette_ui_shared;

// Core Services
export 'src/services/core/service_locator.dart';
export 'src/services/core/service_manager.dart';

// Service Interfaces
export 'src/services/interfaces/tts_service_interface.dart';
export 'src/services/interfaces/translation_service_interface.dart';

// Service Implementations
export 'src/services/implementations/tts_service_impl.dart';

// Legacy Service Manager (for backward compatibility)
export 'src/services/shared_tts_manager.dart';

// Design Tokens
export 'src/tokens/color_tokens.dart';
export 'src/tokens/dimension_tokens.dart';
export 'src/tokens/typography_tokens.dart';
export 'src/tokens/motion_tokens.dart';
export 'src/tokens/app_tokens.dart';

// Component Architecture
// TODO: Implement atomic design components
// export 'src/components/atoms/atoms.dart';
// export 'src/components/molecules/molecules.dart';
// export 'src/components/organisms/organisms.dart';

// State Management
export 'src/state/state.dart';

// Constants (legacy support) - with name hiding to avoid conflicts
export 'src/constants/ui_constants.dart' hide UISizes, TextStyles;
export 'src/constants/language_constants.dart';

// Themes
export 'src/themes/app_theme.dart';

// Widgets (selected existing widgets)
export 'src/widgets/alouette_app_bar.dart';
export 'src/widgets/alouette_logo.dart';
export 'src/widgets/compact_slider.dart';
export 'src/widgets/config_status_widget.dart';
export 'src/widgets/language_selection_grid.dart';
export 'src/widgets/language_selector.dart';
export 'src/widgets/modern_app_bar.dart';
export 'src/widgets/modern_button.dart';
export 'src/widgets/modern_card.dart';
export 'src/widgets/modern_dropdown.dart';
export 'src/widgets/modern_text_field.dart';
export 'src/widgets/translation_input_widget.dart';
export 'src/widgets/translation_result_widget.dart';
export 'src/widgets/tts_control_buttons.dart';
export 'src/widgets/tts_control_widget.dart';
export 'src/widgets/tts_input_widget.dart';
export 'src/widgets/tts_status_card.dart';
export 'src/widgets/tts_status_indicator.dart';
export 'src/widgets/volume_slider.dart';

// Dialogs
export 'src/dialogs/llm_config_dialog.dart';
export 'src/dialogs/tts_config_dialog.dart';

// Translation Components (new refactored widgets)
export 'src/widgets/translation/translation_text_input.dart';
export 'src/widgets/translation/language_selection_section.dart';
export 'src/widgets/translation/translation_action_button.dart';
