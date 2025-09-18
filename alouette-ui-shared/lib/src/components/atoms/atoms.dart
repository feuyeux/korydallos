/// Atomic Design - Atoms
///
/// This file exports all atomic components (the smallest UI building blocks)
/// following the atomic design methodology. Atoms are the basic building blocks
/// of matter applied to web interfaces - they include basic HTML elements like
/// form labels, inputs, buttons, and others that can't be broken down any further.

// Base atomic elements
export 'atomic_elements.dart';

// Form components
export 'alouette_button.dart';
export 'alouette_text_field.dart';
export 'alouette_slider.dart';
export 'atomic_input.dart';

// Legacy atomic components (for backward compatibility)
export 'atomic_button.dart';

// Re-export commonly used classes for convenience
export 'atomic_elements.dart' show
    AtomicWidget,
    AtomicIcon,
    AtomicIconSize,
    AtomicText,
    AtomicTextVariant,
    AtomicSpacer,
    AtomicSpacing,
    AtomicSpacerDirection,
    AtomicDivider,
    AtomicDividerType,
    AtomicCard,
    AtomicBadge,
    AtomicBadgeSize,
    AtomicChip,
    AtomicProgressIndicator,
    AtomicProgressType,
    AtomicProgressSize;