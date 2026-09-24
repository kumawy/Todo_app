import 'package:flutter/material.dart';

const appPrimary = Color(0xFF4143D1);

const appInk = Color(0xFF20243A);
const appMuted = Color(0xFF62697D);
const appSurface = Color(0xFFF5F6FB);
const appBorder = Color(0xFFE7E9F2);

Duration motionDuration(BuildContext context, [int milliseconds = 220]) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: appPrimary).copyWith(
    primary: appPrimary,
    surface: Colors.white,
    onSurface: appInk,
    onSurfaceVariant: appMuted,
    outlineVariant: appBorder,
  );
  final textTheme = ThemeData(colorScheme: scheme).textTheme;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: appBorder),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: appInk,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: appInk,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appSurface,
      labelStyle: const TextStyle(color: appMuted),
      floatingLabelStyle: const TextStyle(color: appPrimary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: appPrimary, width: 1.5),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        textStyle: textTheme.labelLarge!.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: shape,
        side: const BorderSide(color: appBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: appPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: shape,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: appInk,
      actionTextColor: const Color(0xFFCACBFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: appMuted, width: 1.5),
    ),
    dividerTheme: const DividerThemeData(
      color: appBorder,
      thickness: 1,
      space: 32,
    ),
    useMaterial3: true,
  );
}

String formatDurationMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return [
    if (hours > 0) '$hours ч',
    if (rest > 0 || hours == 0) '$rest мин',
  ].join(' ');
}

String formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String formatTaskCount(int count) {
  final lastTwo = count % 100;
  final last = count % 10;
  final word = lastTwo >= 11 && lastTwo <= 14
      ? 'задач'
      : last == 1
      ? 'задача'
      : last >= 2 && last <= 4
      ? 'задачи'
      : 'задач';
  return '$count $word';
}

String formatDayMonth(DateTime date) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
