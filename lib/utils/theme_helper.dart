import 'package:flutter/material.dart';

/// ThemeHelper provides centralized color and styling methods for light theme.
class ThemeHelper {
  // ==================== Background Colors ====================
  
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getElevatedSurfaceColor(BuildContext context) {
    return Colors.white;
  }

  // ==================== Primary Colors ====================
  
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getSuccessColor(BuildContext context) {
    return const Color(0xff059669);
  }

  static Color getWarningColor(BuildContext context) {
    return const Color(0xfff59e0b);
  }

  static Color getInfoColor(BuildContext context) {
    return getPrimaryColor(context);
  }

  // ==================== Text Colors ====================
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getTextSecondary(BuildContext context) {
    return const Color(0xff6b7280);
  }

  static Color getTextTertiary(BuildContext context) {
    return const Color(0xff9ca3af);
  }

  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getOnPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  // ==================== Border Colors ====================
  
  static Color getBorderColor(BuildContext context) {
    return const Color(0xffe5e7eb);
  }

  static Color getDividerColor(BuildContext context) {
    return const Color(0xfff3f4f6);
  }

  static Color getFocusedBorderColor(BuildContext context) {
    return getPrimaryColor(context);
  }

  // ==================== Icon Colors ====================
  
  static Color getIconPrimary(BuildContext context) {
    return getTextPrimary(context);
  }

  static Color getIconSecondary(BuildContext context) {
    return getTextSecondary(context);
  }

  static Color getIconOnPrimary(BuildContext context) {
    return Colors.white;
  }

  // ==================== Gradients ====================
  
  static LinearGradient getPrimaryGradient(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff2563eb), Color(0xff3b82f6)],
    );
  }

  static LinearGradient getSecondaryGradient(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff059669), Color(0xff10b981)],
    );
  }

  static LinearGradient getSuccessGradient(BuildContext context) {
    return getSecondaryGradient(context);
  }

  static LinearGradient getAccentGradient(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xff9333ea), Color(0xffe91e63)],
    );
  }

  static LinearGradient getSubtleGradient(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xfff8f9fa)],
    );
  }

  // ==================== Shadows ====================
  
  static List<BoxShadow> getSmallShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> getMediumShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> getLargeShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> getPrimaryShadow(BuildContext context) {
    return [
      BoxShadow(
        color: getPrimaryColor(context).withValues(alpha: 0.3),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static Color getShadowColor(BuildContext context) {
    return Colors.black.withValues(alpha: 0.06);
  }

  // ==================== Overlay Colors ====================
  
  static Color getLightOverlay(BuildContext context, {double opacity = 0.1}) {
    return Colors.white.withValues(alpha: opacity);
  }

  static Color getDarkOverlay(BuildContext context, {double opacity = 0.1}) {
    return Colors.black.withValues(alpha: opacity);
  }

  static Color getAdaptiveOverlay(BuildContext context, {double opacity = 0.1}) {
    return Colors.black.withValues(alpha: opacity);
  }

  // ==================== Chip/Tag Colors ====================
  
  static Color getChipBackground(BuildContext context) {
    return const Color(0xfff3f4f6);
  }

  static Color getPrimaryChipBackground(BuildContext context) {
    return getPrimaryColor(context).withValues(alpha: 0.15);
  }

  static Color getSuccessChipBackground(BuildContext context) {
    return getSuccessColor(context).withValues(alpha: 0.15);
  }

  static Color getWarningChipBackground(BuildContext context) {
    return getWarningColor(context).withValues(alpha: 0.15);
  }

  static Color getErrorChipBackground(BuildContext context) {
    return getErrorColor(context).withValues(alpha: 0.15);
  }

  // ==================== Status Colors ====================
  
  static Color getCompletedColor(BuildContext context) {
    return getSuccessColor(context);
  }
  
  static Color getInProgressColor(BuildContext context) {
    return getWarningColor(context);
  }
  
  static Color getPendingColor(BuildContext context) {
    return const Color(0xff9ca3af);
  }

  static Color getActiveStatusColor(BuildContext context) {
    return getSuccessColor(context);
  }

  static Color getInactiveStatusColor(BuildContext context) {
    return getTextTertiary(context);
  }

  // ==================== Container Colors ====================
  
  static Color getContainerColor(BuildContext context, {double opacity = 0.05}) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: opacity);
  }

  // ==================== Component-Specific Helpers ====================
  
  static Color getAppBarBackground(BuildContext context) {
    return Theme.of(context).appBarTheme.backgroundColor ?? getBackgroundColor(context);
  }

  static Color getBottomNavBackground(BuildContext context) {
    return Colors.white;
  }

  static Color getBottomNavSelected(BuildContext context) {
    return getPrimaryColor(context);
  }

  static Color getBottomNavUnselected(BuildContext context) {
    return getTextSecondary(context);
  }

  static Color getInputBackground(BuildContext context) {
    return Colors.white;
  }

  static Color getDisabledColor(BuildContext context) {
    return getTextTertiary(context);
  }

  static Color getShimmerBaseColor(BuildContext context) {
    return const Color(0xffe5e7eb);
  }

  static Color getShimmerHighlightColor(BuildContext context) {
    return const Color(0xfff3f4f6);
  }

  // ==================== Utility Methods ====================
  
  static bool isDarkMode(BuildContext context) {
    return false; // Always light mode
  }

  static Color getInverseSurfaceColor(BuildContext context) {
    return const Color(0xff1f2937);
  }

  static Color adaptiveColor(BuildContext context, Color lightColor, Color darkColor) {
    return lightColor; // Always return light color
  }
}
