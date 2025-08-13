import 'package:flutter/material.dart';

class EnableTheme {
  static ThemeData defaultTheme(BuildContext context) {
    final colorScheme = ColorScheme.dark(
      surface: Color(0xFF181616),
      onSurface: Color(0xFF999999),
      primary: Colors.white,
      secondary: Color(0xFF999999),
      error: Colors.red.shade500,
    );

    final textTheme = const TextTheme(
      labelSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: Color(0xFFE2DDD3),
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 13,
        color: Color(0xFFE2DDD3),
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Color(0xFFE2DDD3),
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Color(0xFFE2DDD3),
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ).apply(fontFamily: 'LibreFranklin');

    return ThemeData(
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.white,
      colorScheme: colorScheme,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Color(0xFF383232),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hoverColor: Colors.transparent,
        focusColor: Colors.white,
        hintStyle: textTheme.bodyLarge!.copyWith(
          color: colorScheme.secondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 12.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFE8DDC4),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(6),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF292525),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(6),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 1.5,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(6),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: Color(0xFF292525),
              width: 1.0,
            ),
          ),
          backgroundColor: Color(0xFF383232),
          shadowColor: Colors.transparent,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateColor.resolveWith(
                (states) {
              final selected = states.contains(WidgetState.selected);
              return selected ? Color(0xFF1A1818) : Colors.transparent;
            },
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          fixedSize: WidgetStatePropertyAll(Size(40.0, 40.0)),
          iconSize: WidgetStatePropertyAll(20.0),
          iconColor: WidgetStateColor.resolveWith(
                (states) {
              if (states.contains(WidgetState.hovered)) {
                return Color(0xFFE2DDD3);
              }
              if (states.contains(WidgetState.selected)) {
                return Color(0xFFE2DDD3);
              }
              return Color(0xFF999999);
            },
          ),
          side: WidgetStateBorderSide.resolveWith(
                (states) {
              final selected = states.contains(WidgetState.selected);
              return BorderSide(
                width: 1,
                color: selected ? Color(0xFF292525) : Colors.transparent,
              );
            },
          ),
        ),
      ),
    );
  }
}
