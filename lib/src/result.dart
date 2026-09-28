import 'config.dart';
import 'datify.dart';
import 'util.dart';

/// A date found by [Datify].
///
/// Any of the date parts may be null when the text contains only some of them, as in `March 2022`.
///
final class DatifyResult {
  final int? year;
  final int? month;
  final int? day;

  /// The index of the first character of the date in the parsed text.
  ///
  final int start;

  /// The index after the last character of the date in the parsed text.
  ///
  final int end;

  /// Whether the day and month could have been read in the other order, as in `05/06/2021`.
  ///
  /// The order of an ambiguous date is chosen by [DatifyConfig.dayFirst].
  ///
  final bool isAmbiguous;

  const DatifyResult({
    this.year,
    this.month,
    this.day,
    required this.start,
    required this.end,
    this.isAmbiguous = false,
  });

  /// Whether the year, month, and day were all found.
  ///
  bool get isComplete => year != null && month != null && day != null;

  /// The date as a [DateTime], or null if the result is incomplete or the date does not exist
  /// (e.g. February 31).
  ///
  DateTime? get date => dateFromParts(year, month, day);

  @override
  String toString() => 'DatifyResult(year: $year, month: $month, day: $day, '
      'start: $start, end: $end, isAmbiguous: $isAmbiguous)';

  @override
  bool operator ==(Object other) =>
      other is DatifyResult &&
      year == other.year &&
      month == other.month &&
      day == other.day &&
      start == other.start &&
      end == other.end &&
      isAmbiguous == other.isAmbiguous;

  @override
  int get hashCode => Object.hash(year, month, day, start, end, isAmbiguous);
}
