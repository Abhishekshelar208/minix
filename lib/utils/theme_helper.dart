import 'package:flutter/material.dart';

class ThemeHelper {
  // Get colors based on current theme
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
  
  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color getOnPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }
  
  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
  
  // Consistent color variants for light/dark themes
  static Color getSuccessColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xff10b981) // Brighter green for dark mode
        : const Color(0xff059669); // Standard green for light mode
  }
  
  static Color getWarningColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xfffbbf24) // Brighter yellow for dark mode
        : const Color(0xfff59e0b); // Standard yellow for light mode
  }
  
  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  // Text colors with opacity
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  }
  
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }
  
  // Border and outline colors
  static Color getBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.12)
        : const Color(0xffe5e7eb);
  }
  
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }
  
  // Shadow colors
  static Color getShadowColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.06);
  }
  
  // Card and container colors
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }
  
  static Color getContainerColor(BuildContext context, {double opacity = 0.05}) {
    return Theme.of(context).colorScheme.primary.withOpacity(opacity);
  }
  
  // Status colors
  static Color getCompletedColor(BuildContext context) {
    return getSuccessColor(context);
  }
  
  static Color getInProgressColor(BuildContext context) {
    return getWarningColor(context);
  }
  
  static Color getPendingColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xff6b7280)
        : const Color(0xff9ca3af);
  }
  
  // Utility methods
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  static Color adaptiveColor(BuildContext context, Color lightColor, Color darkColor) {
    return isDarkMode(context) ? darkColor : lightColor;
  }
  
  // Common gradient combinations
  static LinearGradient getPrimaryGradient(BuildContext context) {
    final primaryColor = getPrimaryColor(context);
    return LinearGradient(
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  static LinearGradient getSuccessGradient(BuildContext context) {
    final successColor = getSuccessColor(context);
    return LinearGradient(
      colors: [
        successColor,
        successColor.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}