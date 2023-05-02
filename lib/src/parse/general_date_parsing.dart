import '../../datify.dart';

/// Tries to parse date in general date format (YYYY$MM$DD) from the given [input].
///
DatifyResult? tryParseGeneralDateFormat(String input) {
  final dateRegex = RegExp(DatifyConfig.dateFormat);
  final dateMatch = dateRegex.stringMatch(input);

  if (dateMatch == null) {
    return null;
  }

  // remove all the splitters from the date pattern
  final cleanDateMatch = dateMatch.replaceAll(DatifyConfig.splitterPattern, '');

  // parse the date
  final year = _intFromSubstring(cleanDateMatch, 0, 4);
  final month = _intFromSubstring(cleanDateMatch, 4, 6);
  final day = _intFromSubstring(cleanDateMatch, 6, 8);

  return DatifyResult(year: year, month: month, day: day);
}

/// Parses int from the substring from [start] to [end] of the given [input].
///
int _intFromSubstring(String input, int start, int end) =>
    int.parse(input.substring(start, end));
