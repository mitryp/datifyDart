import 'config.dart';
import 'grammar.dart';
import 'lenient.dart';
import 'lexer.dart';
import 'result.dart';
import 'vocabulary.dart';

/// Finds dates in text.
///
/// ```dart
/// const datify = Datify();
///
/// datify.parse('Due on 20th of January, 2021')?.date; // 2021-01-20
/// datify.parse('3 січ. 2026')?.date; // 2026-01-03
/// datify.parseAll('from 1.02.2021 to 2021-03-15'); // two results
/// ```
///
/// Recognized dates:
/// * numeric dates such as `31.12.2021`, `12/31/2021`, and `15.03.22`, where the separators may
///   be whitespace or any of [DatifyConfig.separators];
/// * `2021-12-31`, `20211231`, and ISO 8601 timestamps such as `2021-12-31T10:00:00Z`;
/// * dates with month names such as `20th of January, 2021`, `Jan 20, 2021`, `2021 Jan 20`,
///   `14 лютого 2022`, and `5. Mai 2020`;
/// * partial dates with month names such as `January 2021` and `20 of January`.
///
/// Two-digit years 00–68 are read as 2000–2068, and 69–99 as 1969–1999.
///
/// See [DatifyConfig] for the settings, such as the order of the day and month in ambiguous dates.
///
final class Datify {
  final DatifyConfig config;

  const Datify([this.config = const DatifyConfig()]);

  /// Returns the first date in [text], or null if there is none.
  ///
  /// When [DatifyConfig.lenient] is true and the text has no recognized date, returns whatever
  /// date parts could be picked from the text instead.
  ///
  DatifyResult? parse(String text) {
    final vocabulary = Vocabulary.of(config.locales);
    final tokens = tokenize(text, config.separators);

    return Grammar(tokens, config, vocabulary).first() ??
        (config.lenient
            ? LenientParser(text, tokens, config, vocabulary).parse()
            : null);
  }

  /// Returns all dates in [text], in the order they appear.
  ///
  /// When [DatifyConfig.lenient] is true and the text has no recognized date, returns the date parts
  /// that could be picked from the text as a single result instead.
  ///
  List<DatifyResult> parseAll(String text) {
    final vocabulary = Vocabulary.of(config.locales);
    final tokens = tokenize(text, config.separators);

    final results = Grammar(tokens, config, vocabulary).all();
    if (results.isEmpty && config.lenient) {
      final result = LenientParser(text, tokens, config, vocabulary).parse();
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }
}
