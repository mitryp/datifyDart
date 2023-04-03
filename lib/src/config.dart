import 'util.dart';

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
  static const dayFormat = r'\b((0?[1-9])|([12]\d)|(3[01]))(\b|(?=\D))';

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
      throw IndexError.withLength(ordinal, months.length,
          message:
              'Invalid month ordinal. Months ordinal must be between 1 and 12 inclusive');
    }

    // normalize the month name
    final normalizedName = normalize(monthName);

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
    var normalizedMonths = monthNames.map(normalize);

    // add the months to the configuration in the storage order
    for (var ordinal = 0; ordinal < normalizedMonths.length; ordinal++) {
      DatifyConfig.addNewMonthName(
          ordinal + 1, normalizedMonths.elementAt(ordinal));
    }
  }
}
