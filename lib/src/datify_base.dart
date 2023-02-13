import 'dart:core';
import 'dart:math';

/// Splits the given string with the first found separator from the DatifyConfig.
/// If the string does not contain any known separators, returns null.
///
List<String> _splitWord(String str) => str.split(DatifyConfig.splitterPattern);

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
int? _tryParseMonth(String input) {
  for (var month = 0; month < DatifyConfig.months.length; month++) {
    if (DatifyConfig.months.elementAt(month).contains(input.trim())) {
      return month + 1;
    }
  }

  for (var monthIndex = 0;
      monthIndex < DatifyConfig.months.length;
      monthIndex++) {
    final currentMonthNames = DatifyConfig.months[monthIndex];
    for (var name in currentMonthNames) {
      if (input == name || _isSameWord(input, name)) {
        return monthIndex + 1;
      }
    }
  }
  return null;
}

/// The enumeration of the date parts.
///
/// Each date part has a corresponding RegExp to match the part.
///
/// The only exception is the alphabetic months, which are handled separately from other date parts.
///
enum _DatePart {
  day,
  month,
  year;

  /// Returns the parsing order of the date parts depending on the [DatifyConfig.dayFirst] setting.
  ///
  /// If the dayFirst setting is set to true, the order will be the set to [day, month, year],
  /// otherwise the order will be the [month, day, year].
  ///
  /// If any of the `yearDefined`, `monthDefined`, of `dayDefined` optional parameters are set to true,
  /// the resulting order list will not contain the respective date parts, what allows to prevent
  /// multiple of the predefined values.
  ///
  static List<_DatePart> order(bool dayFirst,
      {bool yearDefined = false,
      bool monthDefined = false,
      bool dayDefined = false}) {
    if (dayFirst) {
      return [
        if (!dayDefined) day,
        if (!monthDefined) month,
        if (!yearDefined) year
      ];
    }
    return [
      if (!monthDefined) month,
      if (!dayDefined) day,
      if (!yearDefined) year
    ];
  }

  /// Returns the respective [RegExp] pattern for the given [_DatePart].
  static RegExp patternOf(_DatePart part) {
    switch (part) {
      case _DatePart.day:
        return RegExp(DatifyConfig.dayFormat);
      case _DatePart.month:
        return RegExp(DatifyConfig.monthDigitFormat);
      case _DatePart.year:
        return RegExp(DatifyConfig.yearFormat);
    }
  }

  /// Returns the pattern corresponding to the specific date part.
  ///
  RegExp get pattern => _DatePart.patternOf(this);
}

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
  /// The year field of the Datify instance.
  /// May be null if the parsing operation couldn't parse the value.
  ///
  int? year;

  /// The month field of the Datify instance.
  /// May be null if the parsing operation couldn't parse the value.
  ///
  int? month;

  /// The day field of the Datify instance.
  /// May be null if the parsing operation couldn't parse the value.
  ///
  int? day;

  /// Creates a new Datify instance with the given year, month and day.
  /// All values are optional. The values that are not given will be set to null.
  ///
  Datify.fromValues({this.day, this.month, this.year});

  /// Creates an empty Datify instance.
  /// All the fields in this instance are null.
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
    // if no input is provided does not move further
    if (string == null) return;

    // lowercase the string
    final input = string.toLowerCase();

    // check if the string has a general date pattern
    // if it has, parse it and return the Datify object
    final dateRegex = RegExp(DatifyConfig.dateFormat);
    final dateMatch = dateRegex.stringMatch(input);
    if (dateMatch != null) {
      // remove all the splitters from the date pattern
      final cleanDateMatch =
          dateMatch.replaceAll(DatifyConfig.splitterPattern, '');

      // parse the date
      final year = int.parse(cleanDateMatch.substring(0, 4));
      final month = int.parse(cleanDateMatch.substring(4, 6));
      final day = int.parse(cleanDateMatch.substring(6, 8));

      // set the instance variables
      _setNullValues(day, month, year);

      return;
    }

    // if the string didn't have the date pattern, try to parse it

    // split the string with the first found separator
    var dateParts = _splitWord(input);

    // if the DatifyConfig.dayFirst is set to false, then
    // check all date parts for an alphabetic month to prevent loosing the month if the
    // day is defined before the alphabetic month
    // sadly, it makes the parsing MUCH slower
    if (!DatifyConfig.dayFirst) {
      for (final datePart in dateParts) {
        final month = _tryParseMonth(datePart);
        if (month == null) {
          continue;
        }

        this.month ??= month;
        break;
      }
    }

    // define the part order based on the DatifyConfig.dayFirst option and optional predefined values
    final remainingPartsOrder = _DatePart.order(DatifyConfig.dayFirst,
        dayDefined: day != null,
        monthDefined: month != null,
        yearDefined: year != null);

    // parse each date part
    for (var datePart in dateParts) {
      // in each date part test all the unknown values
      for (var part in remainingPartsOrder) {
        final regexp = part.pattern;
        final match = regexp.stringMatch(datePart);
        if (match == null) {
          // if the month was already defined, just skip the part
          if (month != null) {
            continue;
          }

          // if the match is null, maybe its an alphabetic month?
          final parsedMonth = _tryParseMonth(datePart);
          if (parsedMonth != null) {
            month ??= parsedMonth;
            remainingPartsOrder.remove(_DatePart.month);
            break;
          }

          // if no part has a match in the current
          // date part, skip that DatePart
          continue;
        }

        // if the match is not null, parse it
        final value = int.parse(match);

        // and set the value to the respective field if the field is null at the moment of parsing
        switch (part) {
          case _DatePart.day:
            day ??= value;
            break;
          case _DatePart.month:
            month ??= value;
            break;
          case _DatePart.year:
            year ??= value;
            break;
        }

        // proceed to the next part
        remainingPartsOrder.remove(part);
        break;
      }
    }
  }

  /// Sets the previously unset fields of the Datify object to the given values.
  ///
  void _setNullValues(int? day, int? month, int? year) {
    this.day ??= day;
    this.month ??= month;
    this.year ??= year;
  }

  /// Returns true if all the date parts of the date are not null. Otherwise, returns false.
  ///
  bool get isComplete => day != null && month != null && year != null;

  /// Returns a [DateTime] object of the parsed date if the date is complete.
  ///
  /// If any of the date parts are null, the method will return null instead.
  ///
  DateTime? get date => (isComplete ? DateTime(year!, month!, day!) : null);

  /// Returns a [DatifyResult] object with the values of the [Datify.parse].
  ///
  /// See the [DatifyResult] class for more information about it.
  ///
  DatifyResult get result => DatifyResult(year: year, month: month, day: day);

  @override
  String toString() {
    return 'Datify(year: $year, month: $month, day: $day)';
  }

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

/// The class used to represent the result of Datify parsing.
///
/// The result is not nullable, but any of the values in the result can be null depending on the
/// parsing context.
///
/// The result can be transformed into a [DateTime] object using the [date] getter if all the values
/// in the result are not null. Otherwise, the date getter will return null.
///
/// The result has the [year], [month], and [day] nullable final fields.
///
/// The result can be transformed into Map<String, int?> with the [toMap] method.
///
class DatifyResult {
  // TODO: decide if we need it or not
  /// The year of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? year;

  /// The month of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? month;

  /// The day of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? day;

  /// Creates a new DatifyResult with the specified values.
  ///
  const DatifyResult(
      {required this.year, required this.month, required this.day});

  /// Returns a Map of the values of the DatifyResult.
  ///
  /// The structure of the returned Map is as follows:
  /// ```json
  /// {
  ///   "year": year | null,
  ///   "month": month | null,
  ///   "day": day | null
  /// }
  /// ```
  Map<String, int?> toMap() => {'year': year, 'month': month, 'day': day};

  /// Returns true if all the values of the result are not null.
  ///
  /// If the result is complete, this means that it can be successfully transformed into a
  /// [DateTime] object with the [date] getter.
  ///
  bool get isComplete => year != null && month != null && day != null;

  /// Returns the [DateTime] object with the values of the result.
  /// This works if all the values of the result are not null.
  ///
  /// If the result is incomplete, this getter will return null instead.
  ///
  DateTime? get date => (isComplete ? DateTime(year!, month!, day!) : null);

  @override
  String toString() {
    return 'DatifyResult{year: $year, month: $month, day: $day}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatifyResult &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}

/// The class that is used to store the local Datify settings.
///
/// It stores the local settings that are used to control the Datify behavior in the desired way.
///
/// The following options are available:
/// * [dayFirst] - defines if the day is parsed before the month of after it (American format).
/// * [splitters] - defines the set of supported splitters, that are used to separate the date parts
/// during the parsing process.
/// * localization - not an option name itself.
///
/// **There are several localization methods provided:**
/// * [addNewMonthName] - adds a new month name to the month with the given ordinal number.
/// After the addition, the new month name will be parsed alongside the default ones and
/// represent the month with the given ordinal number.
/// * [addNewMonthsLocale] - adds a new locale to the config. Takes the list of month names with the
/// length of 12 in the month order.
///
/// *See the methods documentation for more detailed information.*
///
abstract class DatifyConfig {
  /// This option defines the order of the date parts parsing.
  /// false value is used to parse the American date format (MM.DD.YYYY) correctly.
  ///
  /// The default value is true, which represents the DD.MM.YYYY date format.
  ///
  /// Example:
  /// ```dart
  /// Datify.parse('01/03/2014'); // Datify{year=2014, month=3, day=1} -- the default setting which is true
  ///
  /// DatifyConfig.dayFirst = false; // switching to the American format
  /// Datify.parse('01/03/2014'); // Datify{year=2014, month=1, day=3} -- the behavior changed
  /// ```
  ///
  static var dayFirst = true;

  /// The Set of the supported date splitters.
  /// The external splitters may be added to extend the supported date formats.
  ///
  /// Example:
  /// ```dart
  /// Datify.parse('10@12@2012); // Datify{year=null, month=null, day=null} -- the splitter is not supported yet.
  ///
  /// DatifyConfig.splitters.add('@'); // added to extend the supported date splitters
  /// Datify.parse('10@12@2012); // Datify{year=2012, month=12, day=10}
  ///                            // -- the splitters list was extended and now includes the desired one
  /// ```
  ///
  static final splitters = {' ', '/', '.', '-'};

  /// The day format which is one or two digits day that may be followed by any non-digit
  /// character(s): D?D.
  ///
  static const dayFormat = r'\b(([1-9])|([12]\d)|(3[01]))(\b|(?=\D))';

  /// The digit month format which is one or two digits month: M?M.
  ///
  static const monthDigitFormat = r'\b((0?[1-9])|(1[012]))\b';

  /// The year format which is (1|2)YYY.
  ///
  static const yearFormat = r'\b[12]\d\d\d\b';

  /// The general date pattern with a placeholder on the place where the splitter pattern should be.
  ///
  static const _dateFormat =
      r'\b[12]\d\d\d##((0[1-9])|(1[012]))##(([012]\d)|(3[01]))\b';

  /// The pattern that describes any of the supported date splitters.
  ///
  static RegExp get splitterPattern =>
      RegExp('(${splitters.map(RegExp.escape).join("|")})');

  /// The pattern of the general date format.
  /// Is used to find patterns of format YYYYMMDD. There could be any of the supported date splitters
  /// between the date parts like this: YYYY-MM.DD.
  ///
  static String get dateFormat =>
      _dateFormat.replaceAll(RegExp('##'), '${splitterPattern.pattern}?');

  /// The list of Set<String> that represents the supported names of each month of the year.
  ///
  /// The first month is represented by the months[0] element.
  ///
  /// Each set contains the lowercase and trimmed names of the months represented by the set.
  ///
  /// *It's possible to add more localizations to the Datify. See [addNewMonthName]
  /// and [addNewMonthsLocale] methods.*
  ///
  static final months = [
    {
      'january',
      'jan',
      'січень',
      'январь',
    },
    {
      'february',
      'feb',
      'лютий',
      'февраль',
    },
    {
      'march',
      'mar',
      'березень',
      'март',
    },
    {
      'april',
      'apr',
      'квітень',
      'апрель',
    },
    {
      'may',
      'травень',
      'май',
    },
    {
      'june',
      'jun',
      'червень',
      'июнь',
    },
    {
      'july',
      'jul',
      'липень',
      'июль',
    },
    {
      'august',
      'aug',
      'серпень',
      'август',
    },
    {
      'september',
      'sep',
      'вересень',
      'сентябрь',
    },
    {
      'october',
      'oct',
      'жовтень',
      'октябрь',
    },
    {
      'november',
      'nov',
      'листопад',
      'ноябрь',
    },
    {
      'december',
      'dec',
      'грудень',
      'декабрь',
    }
  ];

  /// Adds the given month name to the set of the month with the given ordinal number.
  ///
  /// The ordinal number must be in the range **[1,12]** inclusive to represent the month.
  /// Otherwise, the method will throw an IndexError exception.
  ///
  /// The given month name will be added to the set of the month names with the given ordinal number
  /// and will represent the month with the given ordinal number.
  ///
  /// Example:
  /// ```dart
  /// // DatifyConfig.addNewMonthName(20, 'January'); // throws an IndexError exception
  /// DatifyConfig.addNewMonthName(3, 'March'); // 'March' was added to the set of the month names that represent the third month
  /// ```
  /// *The preceding example is only an illustration: the English localization is already included in the configuration.*
  ///
  static void addNewMonthName(int ordinal, String monthName) {
    if (ordinal < 1 || ordinal > 12) {
      throw IndexError(ordinal, months, 'Invalid month ordinal',
          'Months ordinal must be between 1 and 12 inclusive');
    }

    // normalize the month name
    final normalizedName = _normalize(monthName);

    // add the month name to the respective month name set
    months.elementAt(ordinal - 1).add(normalizedName);
  }

  /// Adds the new month localization to the configuration.
  ///
  /// This function takes the list of month names which will be added to the respective month name
  /// set of the configuration.
  ///
  /// The list must have the length of **12** to represent each month.
  ///
  /// The list items must be ordered **in the natural months order**.
  ///
  /// The list items must be **unique**.
  ///
  /// Example:
  /// ```dart
  /// // DatifyConfig.addNewMonthsLocale(['january', 'february']); // throws an ArgumentError exception
  /// DatifyConfig.addNewMonthsLocale('january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december');
  /// // The list of items was added to the config as follows:
  /// // 'january' to represent the first month,
  /// // 'february' to represent the second month,
  /// // ...
  /// ```
  /// *The preceding example is only an illustration: the English localization is already included in the configuration.*
  ///
  static void addNewMonthsLocale(List<String> monthNames) {
    // check the collection length - it must be 12 to represent the months
    if (monthNames.length != 12) {
      throw ArgumentError.value(
          monthNames.length,
          'monthNames',
          'The length of months localization '
              'should be 12; it was ${monthNames.length} instead');
    }

    // check the collection elements to be unique
    if (Set.of(monthNames).length != monthNames.length) {
      throw ArgumentError.value(
          monthNames, 'monthNames', 'Month names should be unique');
    }

    // normalize the month name
    var normalizedMonths = monthNames.map(_normalize);

    // add the months to the configuration in the storage order
    for (var ordinal = 0; ordinal < normalizedMonths.length; ordinal++) {
      DatifyConfig.addNewMonthName(
          ordinal + 1, normalizedMonths.elementAt(ordinal));
    }
  }
}

/// Trims and lowercase the given string.
///
String _normalize(String str) => str.trim().toLowerCase();
