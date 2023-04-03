import 'config.dart';

/// The enumeration of the date parts.
///
/// Each date part has a corresponding RegExp to match the part.
///
/// The only exception is the alphabetic months, which are handled separately from other date parts.
///
enum DatePart {
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
  static List<DatePart> order(
    bool dayFirst, {
    bool yearDefined = false,
    bool monthDefined = false,
    bool dayDefined = false,
  }) {
    final dayMonth = [if (!dayDefined) day, if (!monthDefined) month];

    return [
      ...(dayFirst ? dayMonth : dayMonth.reversed),
      if (!yearDefined) year
    ];
  }

  /// Returns the pattern corresponding to the specific date part.
  ///
  RegExp get pattern {
    const formats = {
      DatePart.day: DatifyConfig.dayFormat,
      DatePart.month: DatifyConfig.monthDigitFormat,
      DatePart.year: DatifyConfig.yearFormat
    };

    return RegExp(formats[this]!);
  }
}
