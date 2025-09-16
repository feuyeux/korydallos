/// Shared UI components for Alouette applications
///
/// This library provides reusable UI components that can be used across
/// all Alouette applications including translation widgets, TTS controls,
/// configuration dialogs, and common styling.
library alouette_ui_shared;

// Widgets
export 'src/widgets/translation_input_widget.dart';
export 'src/widgets/translation_result_widget.dart';
export 'src/widgets/language_selector.dart';
export 'src/widgets/tts_control_buttons.dart';
export 'src/widgets/tts_status_indicator.dart';
export 'src/widgets/tts_status_card.dart';
export 'src/widgets/tts_input_widget.dart';
export 'src/widgets/tts_control_widget.dart';
export 'src/widgets/alouette_app_bar.dart';
export 'src/widgets/alouette_logo.dart';
export 'src/widgets/volume_slider.dart';
export 'src/widgets/compact_slider.dart';

// Modern UI Components
export 'src/widgets/modern_app_bar.dart';
export 'src/widgets/modern_card.dart';
export 'src/widgets/modern_button.dart';
export 'src/widgets/modern_text_field.dart';
export 'src/widgets/modern_dropdown.dart';
export 'src/widgets/config_status_widget.dart';

// Dialogs
export 'src/dialogs/llm_config_dialog.dart';
export 'src/dialogs/tts_config_dialog.dart';

// Themes
export 'src/themes/app_theme.dart';

// Constants
export 'src/constants/ui_constants.dart';
export 'src/constants/language_constants.dart';

// Services
export 'src/services/shared_tts_manager.dart';
