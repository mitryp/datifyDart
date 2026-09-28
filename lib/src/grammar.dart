import 'config.dart';
import 'lexer.dart';
import 'result.dart';
import 'util.dart';
import 'vocabulary.dart';

/// The maximum number of punctuation marks between a month name and a number, as in `Dec., 2021`.
const _maxNamedGapLength = 2;

/// Finds dates in a list of tokens by matching them against the supported date shapes:
///
/// * `YYYY-MM-DD` and `YYYYMMDD`, optionally followed by a time as in ISO 8601;
/// * `DD.MM.YYYY` and `MM.DD.YYYY`, with a four- or two-digit year;
/// * `20th of January, 2021`, `January 20, 2021`, and `2021 January 20`, where the year or the day
///   may be missing.
///
/// Numbers may be separated by whitespace or any of [DatifyConfig.separators], and month names
/// additionally by commas.
///
class Grammar {
  final List<Token> _tokens;
  final DatifyConfig _config;
  final Vocabulary _vocabulary;

  Grammar(this._tokens, this._config, this._vocabulary);

  /// Returns the first date in the tokens, or null if there is none.
  ///
  DatifyResult? first() {
    for (var i = 0; i < _tokens.length; i++) {
      final match = _matchAt(i);
      if (match != null) {
        return match.result;
      }
    }

    return null;
  }

  /// Returns all dates in the tokens, in order and without overlaps.
  ///
  List<DatifyResult> all() {
    final results = <DatifyResult>[];
    for (var i = 0; i < _tokens.length; i++) {
      final match = _matchAt(i);
      if (match != null) {
        results.add(match.result);
        i = match.endIndex - 1;
      }
    }

    return results;
  }

  /// Returns the longest date that starts at the token [i].
  ///
  _Match? _matchAt(int i) {
    if (!_canStartAt(i)) {
      return null;
    }

    final candidates = <_Match>[];
    void add(int endIndex,
        {int? year, int? month, int? day, bool isAmbiguous = false}) {
      candidates.add(_Match(
        DatifyResult(
          year: year,
          month: month,
          day: day,
          start: _tokens[i].start,
          end: _tokens[endIndex - 1].end,
          isAmbiguous: isAmbiguous,
        ),
        endIndex,
      ));
    }

    final token = _tokens[i];
    if (token.isNumber) {
      _matchYearFirst(i, add);
      _matchNumeric(i, add);
      _matchDayAndMonthName(i, add);
    } else if (token.isWord) {
      _matchMonthNameFirst(i, add);
    }

    _Match? longest;
    for (final candidate in candidates) {
      if (_canEndAt(candidate.endIndex) &&
          (longest == null || candidate.endIndex > longest.endIndex)) {
        longest = candidate;
      }
    }

    return longest;
  }

  /// `YYYYMMDD`, `YYYY-MM-DD`, and `YYYY January DD`.
  ///
  void _matchYearFirst(int i, _AddMatch add) {
    final token = _tokens[i];
    if (token.text.length == 8) {
      final year = int.parse(token.text.substring(0, 4));
      final month = int.parse(token.text.substring(4, 6));
      final day = int.parse(token.text.substring(6));
      if (_isYear(year) && _isMonth(month) && _isDay(day)) {
        add(i + 1, year: year, month: month, day: day);
      }
      return;
    }

    final year = _year(i, allowTwoDigits: false);
    if (year == null) {
      return;
    }

    final numericMonthIndex = _numericGap(i + 1);
    final numericMonth = _month(numericMonthIndex);
    if (numericMonth != null) {
      final dayIndex = _numericGap(numericMonthIndex! + 1);
      final day = _day(dayIndex);
      if (day != null) {
        add(dayIndex! + 1, year: year, month: numericMonth, day: day);
      }
    }

    final monthIndex = _namedGap(i + 1);
    final month = _monthName(monthIndex);
    if (month != null) {
      final dayIndex = _namedGap(monthIndex! + 1);
      final day = _day(dayIndex);
      if (day != null) {
        add(_skipOrdinalSuffix(dayIndex! + 1),
            year: year, month: month, day: day);
      }
    }
  }

  /// `DD.MM.YYYY` and `MM.DD.YYYY`, where the order is decided by the values when possible and by
  /// [DatifyConfig.dayFirst] otherwise.
  ///
  void _matchNumeric(int i, _AddMatch add) {
    final first = _day(i);
    final secondIndex = _numericGap(i + 1);
    final second = _day(secondIndex);
    if (first == null || second == null) {
      return;
    }

    final yearIndex = _numericGap(secondIndex! + 1);
    final year = _year(yearIndex, allowTwoDigits: true);
    if (year == null) {
      return;
    }

    final int day, month;
    if (first > 12 && second > 12) {
      return;
    } else if (first > 12 || (second <= 12 && _config.dayFirst)) {
      (day, month) = (first, second);
    } else {
      (day, month) = (second, first);
    }

    add(
      yearIndex! + 1,
      year: year,
      month: month,
      day: day,
      isAmbiguous: first <= 12 && second <= 12 && first != second,
    );
  }

  /// `20th of January, 2021`, with an optional year.
  ///
  void _matchDayAndMonthName(int i, _AddMatch add) {
    final day = _day(i);
    if (day == null) {
      return;
    }

    final monthIndex = _skipConnector(_namedGap(_skipOrdinalSuffix(i + 1)));
    final month = _monthName(monthIndex);
    if (month == null) {
      return;
    }

    add(monthIndex! + 1, month: month, day: day);

    final yearIndex = _skipConnector(_namedGap(monthIndex + 1));
    final year = _year(yearIndex, allowTwoDigits: true);
    if (year != null) {
      add(yearIndex! + 1, year: year, month: month, day: day);
    }
  }

  /// `January 20, 2021` and `January 2021`.
  ///
  void _matchMonthNameFirst(int i, _AddMatch add) {
    final month = _monthName(i);
    if (month == null) {
      return;
    }

    final nextIndex = _namedGap(i + 1);
    final day = _day(nextIndex);
    if (day != null) {
      final dayEnd = _skipOrdinalSuffix(nextIndex! + 1);
      add(dayEnd, month: month, day: day);

      final yearIndex = _skipConnector(_namedGap(dayEnd));
      final year = _year(yearIndex, allowTwoDigits: true);
      if (year != null) {
        add(yearIndex! + 1, year: year, month: month, day: day);
      }
    }

    final yearIndex = _skipConnector(nextIndex);
    final year = _year(yearIndex, allowTwoDigits: false);
    if (year != null) {
      add(yearIndex! + 1, year: year, month: month);
    }
  }

  /// Whether the token [i] directly follows the previous one, without whitespace.
  ///
  bool _isGlued(int i) => i > 0 && _tokens[i - 1].end == _tokens[i].start;

  /// A date cannot continue a word or a number, as in `abc2021` or `1.10.07.2006`.
  ///
  bool _canStartAt(int i) {
    if (!_isGlued(i)) {
      return true;
    }

    final previous = _tokens[i - 1];
    if (previous.isNumber || previous.isWord) {
      return false;
    }

    return !(previous.isSeparator &&
        _isGlued(i - 1) &&
        _tokens[i - 2].isNumber);
  }

  /// A date cannot be continued by a word or a number, except for the time in ISO 8601
  /// timestamps such as `2020-01-01T10:00`.
  ///
  bool _canEndAt(int i) {
    if (i >= _tokens.length || !_isGlued(i)) {
      return true;
    }

    final next = _tokens[i];
    final isFollowedByGluedNumber =
        i + 1 < _tokens.length && _isGlued(i + 1) && _tokens[i + 1].isNumber;

    if (next.isWord) {
      return next.lowercase == 't' && isFollowedByGluedNumber;
    }

    return !next.isNumber && !(next.isSeparator && isFollowedByGluedNumber);
  }

  /// Returns the index of the token after an optional separator following the token before [i].
  ///
  /// Two numbers must be separated by whitespace, a separator, or both.
  ///
  int? _numericGap(int i) {
    if (i >= _tokens.length) {
      return null;
    }

    if (_tokens[i].isSeparator) {
      return i + 1 < _tokens.length ? i + 1 : null;
    }

    return _isGlued(i) ? null : i;
  }

  /// Returns the index of the token after the separators and commas following the token before
  /// [i], or null if the tokens are not separated.
  ///
  int? _namedGap(int? i) {
    if (i == null) {
      return null;
    }

    var next = i;
    while (next < _tokens.length &&
        next - i < _maxNamedGapLength &&
        (_tokens[next].isSeparator || _tokens[next].text == ',')) {
      next++;
    }

    if (next >= _tokens.length || (next == i && _isGlued(next))) {
      return null;
    }

    return next;
  }

  int _skipOrdinalSuffix(int i) {
    if (i < _tokens.length &&
        _isGlued(i) &&
        _tokens[i].isWord &&
        _vocabulary.ordinalSuffixes.contains(_tokens[i].lowercase)) {
      return i + 1;
    }

    return i;
  }

  int? _skipConnector(int? i) {
    if (i == null ||
        !_tokens[i].isWord ||
        !_vocabulary.connectors.contains(_tokens[i].lowercase)) {
      return i;
    }

    return _namedGap(i + 1);
  }

  int? _day(int? i) {
    final value = _number(i, maxDigits: 2);
    return value != null && _isDay(value) ? value : null;
  }

  int? _month(int? i) {
    final value = _number(i, maxDigits: 2);
    return value != null && _isMonth(value) ? value : null;
  }

  int? _monthName(int? i) {
    if (i == null || !_tokens[i].isWord) {
      return null;
    }

    return _vocabulary.monthOfWord(_tokens[i].lowercase);
  }

  /// A four-digit year, or a two-digit one if [allowTwoDigits] is true.
  ///
  /// A two-digit number followed by a colon is the hour of a time, as in `15 March 10:30`.
  ///
  int? _year(int? i, {required bool allowTwoDigits}) {
    if (i == null || !_tokens[i].isNumber) {
      return null;
    }

    final token = _tokens[i];
    if (token.text.length == 4) {
      return _isYear(token.value) ? token.value : null;
    }

    final isHour =
        i + 1 < _tokens.length && _isGlued(i + 1) && _tokens[i + 1].text == ':';

    return allowTwoDigits && token.text.length == 2 && !isHour
        ? expandTwoDigitYear(token.value)
        : null;
  }

  int? _number(int? i, {required int maxDigits}) {
    if (i == null ||
        !_tokens[i].isNumber ||
        _tokens[i].text.length > maxDigits) {
      return null;
    }

    return _tokens[i].value;
  }

  static bool _isYear(int value) => value >= 1000 && value <= 2999;
  static bool _isMonth(int value) => value >= 1 && value <= 12;
  static bool _isDay(int value) => value >= 1 && value <= 31;
}

typedef _AddMatch = void Function(
  int endIndex, {
  int? year,
  int? month,
  int? day,
  bool isAmbiguous,
});

class _Match {
  final DatifyResult result;

  /// The index of the token after the date.
  final int endIndex;

  _Match(this.result, this.endIndex);
}
