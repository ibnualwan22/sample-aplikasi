import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared palette for public pages, SIAKAD and every Material overlay.
abstract final class MarkazColors {
  static const gold = Color(0xFFFFCF40);
  static const surface = Color(0xFFFFFFFF);
  static const ivory = Color(0xFFFFFCF3);
  static const tint = Color(0xFFFFF8DF);
  static const ink = Color(0xFF292A26);
  static const muted = Color(0xFF676862);
  static const line = Color(0xFFE8E6DF);
  static const outline = Color(0xFF85857B);
  static const success = Color(0xFF346446);
  static const warning = Color(0xFF785218);
  static const danger = Color(0xFFA1342C);
}

ThemeData markazTheme() {
  const c = MarkazColors.gold;
  final rounded =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Amiri'],
      colorScheme: const ColorScheme.light(
          primary: c,
          onPrimary: MarkazColors.ink,
          primaryContainer: MarkazColors.tint,
          onPrimaryContainer: MarkazColors.ink,
          secondary: MarkazColors.ink,
          onSecondary: Colors.white,
          secondaryContainer: MarkazColors.tint,
          onSecondaryContainer: MarkazColors.ink,
          surface: MarkazColors.surface,
          onSurface: MarkazColors.ink,
          onSurfaceVariant: MarkazColors.muted,
          surfaceContainerHighest: MarkazColors.ivory,
          outline: MarkazColors.outline,
          outlineVariant: MarkazColors.line,
          error: MarkazColors.danger,
          onError: Colors.white,
          surfaceTint: Colors.transparent));
  return base.copyWith(
    scaffoldBackgroundColor: MarkazColors.surface,
    textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontFamily: 'STIXTwoText',
            fontSize: 36,
            height: 1.15,
            color: MarkazColors.ink),
        headlineMedium: const TextStyle(
            fontFamily: 'STIXTwoText',
            fontSize: 30,
            height: 1.2,
            color: MarkazColors.ink),
        headlineSmall: const TextStyle(
            fontFamily: 'STIXTwoText',
            fontSize: 26,
            height: 1.2,
            color: MarkazColors.ink),
        bodyMedium: const TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: ['Amiri'],
            fontSize: 14,
            height: 1.5,
            color: MarkazColors.ink),
        bodySmall: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            height: 1.4,
            color: MarkazColors.muted)),
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: MarkazColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: MarkazColors.ink),
        systemOverlayStyle: SystemUiOverlayStyle.dark),
    iconTheme: const IconThemeData(color: MarkazColors.ink, size: 24),
    dividerTheme: const DividerThemeData(
        color: MarkazColors.line, thickness: 1, space: 24),
    cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: MarkazColors.line))),
    dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: MarkazColors.line)),
        titleTextStyle: base.textTheme.titleLarge
            ?.copyWith(color: MarkazColors.ink, fontWeight: FontWeight.w600)),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: MarkazColors.outline,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MarkazColors.ivory,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: MarkazColors.muted),
        floatingLabelStyle: const TextStyle(color: MarkazColors.ink),
        prefixIconColor: MarkazColors.muted,
        suffixIconColor: MarkazColors.muted,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MarkazColors.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MarkazColors.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MarkazColors.ink, width: 2))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: c,
            foregroundColor: MarkazColors.ink,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: rounded)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: MarkazColors.ink,
            elevation: 0,
            minimumSize: const Size(48, 48),
            shape: rounded)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: MarkazColors.ink,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: MarkazColors.outline),
            shape: rounded)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: MarkazColors.ink,
            minimumSize: const Size(48, 48))),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: MarkazColors.ink,
        selectionColor: MarkazColors.gold,
        selectionHandleColor: MarkazColors.ink),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MarkazColors.ink,
        linearTrackColor: MarkazColors.tint,
        circularTrackColor: MarkazColors.tint),
    tabBarTheme: const TabBarThemeData(
        labelColor: MarkazColors.ink,
        unselectedLabelColor: MarkazColors.muted,
        indicatorColor: MarkazColors.ink),
    navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MarkazColors.ink))),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: MarkazColors.ink,
        unselectedItemColor: MarkazColors.muted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: MarkazColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: c,
        behavior: SnackBarBehavior.floating,
        shape: rounded),
    chipTheme: ChipThemeData(
        backgroundColor: MarkazColors.ivory,
        selectedColor: c,
        labelStyle:
            const TextStyle(fontFamily: 'Roboto', color: MarkazColors.ink),
        side: const BorderSide(color: MarkazColors.line),
        shape: rounded),
    checkboxTheme: CheckboxThemeData(
        checkColor: const WidgetStatePropertyAll(MarkazColors.ink),
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c : Colors.transparent),
        side: const BorderSide(color: MarkazColors.outline, width: 2)),
    radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(MarkazColors.ink)),
    switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(MarkazColors.ink),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c : MarkazColors.line)),
    sliderTheme: const SliderThemeData(
        activeTrackColor: MarkazColors.ink,
        thumbColor: MarkazColors.ink,
        inactiveTrackColor: MarkazColors.line),
    expansionTileTheme: const ExpansionTileThemeData(
        iconColor: MarkazColors.ink,
        collapsedIconColor: MarkazColors.muted,
        textColor: MarkazColors.ink,
        collapsedTextColor: MarkazColors.ink,
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 12)),
    popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: rounded),
    datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: MarkazColors.tint,
        headerForegroundColor: MarkazColors.ink,
        todayForegroundColor: WidgetStatePropertyAll(MarkazColors.ink),
        todayBorder: BorderSide(color: MarkazColors.ink),
        dayForegroundColor: WidgetStatePropertyAll(MarkazColors.ink)),
    timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteColor: MarkazColors.tint,
        hourMinuteTextColor: MarkazColors.ink,
        dialHandColor: c,
        dialBackgroundColor: MarkazColors.ivory,
        dayPeriodColor: c,
        dayPeriodTextColor: MarkazColors.ink),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: _MarkazTransition(),
      TargetPlatform.iOS: _MarkazTransition(),
      TargetPlatform.linux: _MarkazTransition(),
      TargetPlatform.windows: _MarkazTransition(),
      TargetPlatform.macOS: _MarkazTransition(),
      TargetPlatform.fuchsia: _MarkazTransition()
    }),
  );
}

class _MarkazTransition extends PageTransitionsBuilder {
  const _MarkazTransition();
  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child);
  }
}
