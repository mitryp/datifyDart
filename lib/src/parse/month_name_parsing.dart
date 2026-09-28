import 'dart:math';

import '../config.dart';
import '../util.dart';

final _nonLetterPattern = RegExp(r'[^\p{L}]', unicode: true);
final _digitPattern = RegExp(r'\d');

/// The minimum length of an abbreviation matched against a month name, e.g. `sept`.
const _minAbbreviationLength = 3;

/// The minimum shared prefix for two words to be considered forms of the same word.
const _minStemLength = 4;

/// The maximum number of trailing characters that may differ between two forms of the same word.
const _maxEndingLength = 2;

/// Returns true if [input] looks like an abbreviation or an inflected form of the month [name].
///
/// Short words that merely start with a month name, such as `maybe`, `junk`, or `decent`, are
/// not considered matches.
///
bool _isSameWord(String input, String name) {
  if (input.length >= _minAbbreviationLength && name.startsWith(input)) {
    return true;
  }

  final maxStem = min(input.length, name.length);
  var stem = 0;
  while (stem < maxStem && input.codeUnitAt(stem) == name.codeUnitAt(stem)) {
    stem++;
  }

  return stem >= _minStemLength &&
      input.length - stem <= _maxEndingLength &&
      name.length - stem <= _maxEndingLength;
}

/// Parses a string to get a month ordinal number in range [1,12] inclusive.
///
/// Firstly checks if the [DatifyConfig.months] field contains the input string itself.
///
/// If the months list does not contain the input string, then tries to find a month name of which
/// the input is an abbreviation (`sept`) or a different form (`januari`).
///
/// If no corresponding month name is found, then returns null.
///
int? tryParseMonth(String input) {
  // an alphabetic month cannot contain digits
  if (_digitPattern.hasMatch(input)) {
    return null;
  }

  final word = normalize(input).replaceAll(_nonLetterPattern, '');
  if (word.isEmpty) {
    return null;
  }

  final months = DatifyConfig.months;

  for (var month = 0; month < months.length; month++) {
    if (months[month].contains(word)) {
      return month + 1;
    }
  }

  for (var month = 0; month < months.length; month++) {
    for (final name in months[month]) {
      if (_isSameWord(word, name)) {
        return month + 1;
      }
    }
  }

  return null;
}
