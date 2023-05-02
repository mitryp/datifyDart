// todo clean the code
import 'dart:core';

import 'package:datify/src/parse/general_date_parsing.dart';
import 'package:datify/src/util.dart';

import 'config.dart';
import 'date_part.dart';
import 'parse/month_name_parsing.dart';
import 'result.dart';

/// The object that provides the implementation of the autonomous date parsing.
/// This object may be used to parse a dates in any supported formats (see the [Datify.parse] documentation).
///
/// After parsing a date, the Datify object may be used to transform the date into the [DateTime] object
/// or into the [DatifyResult] object. The second one has the year, month and day fields,
/// and can be also used to transform the values into the DateTime object. Moreover, it can be transformed
/// into a map of the following structure:
/// ```json
/// {
/// "year": year | null,
/// "month": month | null,
/// "day": day | null
/// }
/// ```
///
/// The package includes the unit tests for every known cases of usage and thousands of random tests.
///
/// See the methods documentation for more information.
/// The most important information is in the [Datify.parse] method documentation.
///
class Datify {
  /// The parts of the parsed date.
  /// Some parts may be null if the parsing operation couldn't parse the corresponding value.
  ///
  int? year, month, day;

  /// Creates a new Datify instance with the given year, month and day.
  /// All values are optional. The values that are not given will be set to null.
  ///
  Datify.fromValues({this.day, this.month, this.year});

  /// Creates a Datify instance, all of which fields are null.
  ///
  Datify.empty();

  /// Parses the given string in attempt to extract a date from it.
  ///
  /// As a result, the Datify object will contain all the date parts that it could extract from the string.
  /// Some values may not be present in the resulting object, as the input may not contain all the date parts.
  ///
  /// The class supports the following formats:
  /// * digit only dates in the EU format (DD$MM$YYYY): 20.02.2020, 09 07 2000, 9-1-2005;
  /// * digit only dates in the US format (MM.DD.YYYY): 02/22/2020, 09.07.2000, 1 9 2005;
  /// * digit and alphanumeric dates in the general date format (YYYY$?MM$?DD) with or without separators;
  /// * alphanumeric dates in different languages: 11th$of$July,$2020; 6$липня$2021, 31$декабря$2021.
  /// Whenever the sign `$` is encountered, that means that in its place may be any of the supported
  /// separator characters. If the sign is followed by the question mark `$?`, that means that the
  /// separator is optional (may or may not be present).
  ///
  /// The support of the separators can be extended according to the production
  /// needs with the [DatifyConfig] class. See its documentation for more information.
  ///
  /// More month locales may be added in the future.
  /// Moreover, you can add missing month name localizations by yourself using the [DatifyConfig]
  /// class. See its documentation for detailed information.
  ///
  /// *Note: the input '7 2022' will be parsed as Datify{year=2022, month=null, day=7} with the*
  /// *[DatifyConfig.dayFirst] option set to true and Datify{year=2022, month=7, day=null} otherwise*
  /// *and it is considered correct, because there is no accurate way to define the exact meaning of this.*
  ///
  /// Usage:
  /// ```dart
  /// final request = getRequest();
  /// final String userDate = request.body.userDate; // the user could proved the date in any format
  ///                                                // and you may need to extract this date correctly
  ///
  /// final DateTime? parsedDate = Datify.parse(request).date; // if the date was correctly parsed,
  ///                                                          // the parsedDate variable will
  ///                                                          // contain the parsed [DateTime] object
  /// // * do something with the parsed date *
  /// ```
  ///
  /// Instead of using the DateTime getter, the DatifyResult object may be obtained after parsing
  /// the date string. In this case, the result will not be nullable:
  /// ```dart
  /// const dateStringInAnyFormat = ***;
  /// final d = Datify.parse(dateStringInAnyFormat); // parse the date string with Datify
  /// final result = d.result; // the result will never be nullable
  ///
  /// final DateTime? date = result.date; // the DatifyResult can still be transformed into a
  ///                                     // DateTime object if all the fields are present in the result object
  ///
  /// final int? day = result.day; // the DatifyResult has the final fields for the date parts
  ///
  /// final Map<String, int?> dateMap = result.toMap();
  /// ```
  /// See the [DatifyResult] documentation for the detailed information about it.
  ///
  /// *If you want help me adding new languages feel free to
  /// [create a pull request](https://github.com/mitryp/datifyDart)*
  ///
  Datify.parse(String? string, {this.year, this.month, this.day}) {
    if (string == null) return;

    final input = normalize(string);

    // try parse date in general format from the input
    final generalDateParseResult = tryParseGeneralDateFormat(input);
    if (generalDateParseResult != null) {
      _setResult(generalDateParseResult);
      return;
    }

    // if the string didn't have the date pattern, try to parse it

    // split the string with the separator pattern
    final dateParts = input.split(DatifyConfig.splitterPattern);

    // if the DatifyConfig.dayFirst is set to false, then
    // check all date parts for an alphabetic month to prevent loosing the month if the
    // day is defined before the alphabetic month
    if (!DatifyConfig.dayFirst) {
      for (final datePart in dateParts) {
        final month = tryParseMonth(datePart);
        if (month == null) {
          continue;
        }

        _setNullValues(month: month);
        break;
      }
    }

    // define the part order based on the DatifyConfig.dayFirst option and optional predefined values
    final remainingPartsOrder = DatePart.order(
      dayDefined: day != null,
      monthDefined: month != null,
      yearDefined: year != null,
    );

    // parse each date part
    for (final datePart in dateParts) {
      // test each date part on all the not-yet-defined fields
      for (final part in remainingPartsOrder) {
        final regexp = part.pattern;
        final match = regexp.stringMatch(datePart);

        if (match == null) {
          // if the month was already defined, just skip the part
          if (month != null) {
            continue;
          }

          // if the match is null, maybe its an alphabetic month?
          final parsedMonth = tryParseMonth(datePart);
          if (parsedMonth == null) {
            continue;
          }

          _setNullValues(month: parsedMonth);
          remainingPartsOrder.remove(DatePart.month);
          break;
        }

        // if the match is not null, parse it
        final value = int.parse(match);

        // and set the value to the respective field if the field is null at the
        // moment of parsing
        if (part == DatePart.day) {
          day ??= value;
        } else if (part == DatePart.month) {
          month ??= value;
        } else {
          year ??= value;
        }

        // proceed to the next part
        remainingPartsOrder.remove(part);
        break;
      }
    }
  }

  /// Sets the previously unset fields of this Datify object to the given values.
  ///
  void _setNullValues({int? day, int? month, int? year}) {
    this.day ??= day;
    this.month ??= month;
    this.year ??= year;
  }

  /// Sets the previously unset fields of this Datify object to the fields of
  /// the given [result].
  ///
  void _setResult(DatifyResult result) =>
      _setNullValues(year: result.year, month: result.month, day: result.day);

  /// Returns true if all the date parts of the date are not null. Otherwise, returns false.
  ///
  bool get isComplete => day != null && month != null && year != null;

  /// Returns a [DateTime] object of the parsed date if the date is complete.
  ///
  /// If any of the date parts are null, the method will return null instead.
  ///
  DateTime? get date => isComplete ? DateTime(year!, month!, day!) : null;

  /// Returns a [DatifyResult] object with the values of the [Datify.parse].
  ///
  /// See the [DatifyResult] class for more information about it.
  ///
  DatifyResult get result => DatifyResult(year: year, month: month, day: day);

  @override
  String toString() => 'Datify(year: $year, month: $month, day: $day)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Datify &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}
