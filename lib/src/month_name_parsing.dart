import 'dart:math';

import 'config.dart';
import 'util.dart';

/// The function that is used to make a deduction if the two given string are different forms of
/// the same word or not.
///
/// Don't ask me to explain why this function works, but it does.
/// See the tests.
///
bool _isSameWord(String s1, String s2) {
  final st1 = Set.of(s1.codeUnits);
  final st2 = Set.of(s2.codeUnits);

  return st1.difference(st2).length < s1.length / 2 &&
      st2.difference(st1).length < s2.length / 2 &&
      (min(s1.length, s2.length) < 4
          ? s1.substring(0, 2) == s2.substring(0, 2)
          : s1.substring(0, 3) == s2.substring(0, 3));
}

/// Parses a string to get a month ordinal number in range [1,12] inclusive.
///
/// Firstly checks if the [DatifyConfig.months] field contains the input string itself.
///
/// If the months list does not contain the input string, then tries to find the month name that
/// looks similar to the input string.
///
/// If no corresponding month name is found, then returns null.
///
int? tryParseMonth(String input) {
  for (var month = 0; month < DatifyConfig.months.length; month++) {
    if (DatifyConfig.months.elementAt(month).contains(normalize(input))) {
      return month + 1;
    }
  }

  for (var monthIndex = 0;
      monthIndex < DatifyConfig.months.length;
      monthIndex++) {
    final currentMonthNames = DatifyConfig.months[monthIndex];
    for (final name in currentMonthNames) {
      if (input == name || _isSameWord(input, name)) {
        return monthIndex + 1;
      }
    }
  }
  return null;
}
