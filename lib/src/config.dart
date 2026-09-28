import 'datify.dart';
import 'locale.dart';

/// The settings of a [Datify] parser.
///
/// ```dart
/// const datify = Datify(DatifyConfig(dayFirst: false, locales: [DatifyLocale.en]));
/// ```
///
/// Parsers index the month names of their locales once, so reuse a config instead of creating one
/// per parse, and don't modify the lists passed to it.
///
final class DatifyConfig {
  /// Whether the day comes before the month in ambiguous numeric dates such as `05/06/2021`.
  ///
  /// When one of the numbers is greater than 12, the order is detected regardless of this setting,
  /// so `12/31/2021` is always December 31.
  ///
  final bool dayFirst;

  /// The characters that may separate the numbers of a date, in addition to whitespace.
  ///
  /// Each separator must be a single character that is not a letter, a digit, or whitespace;
  /// otherwise, parsing throws an [ArgumentError].
  ///
  final Set<String> separators;

  /// The languages in which month names are recognized.
  ///
  final List<DatifyLocale> locales;

  /// Whether to fall back to picking date parts from anywhere in the input when it contains no date
  /// that Datify recognizes, such as in `12 2020 march`.
  ///
  /// This finds dates in more unusual orders, but may also take unrelated numbers for date parts.
  ///
  final bool lenient;

  const DatifyConfig({
    this.dayFirst = true,
    this.separators = const {'/', '.', '-'},
    this.locales = DatifyLocale.builtIn,
    this.lenient = false,
  });
}
