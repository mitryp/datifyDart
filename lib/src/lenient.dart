import 'config.dart';
import 'grammar.dart';
import 'lexer.dart';
import 'result.dart';
import 'util.dart';
import 'vocabulary.dart';

final _dayPattern = RegExp(r'\b((0?[1-9])|([12]\d)|(3[01]))(\b|(?=\D))');
final _monthPattern = RegExp(r'\b((0?[1-9])|(1[012]))\b');
final _yearPattern = RegExp(r'\b[12]\d\d\d\b');
final _twoDigitYearPattern = RegExp(r'^(\d\d)[.,;:!?)]*$');

enum _Part { day, month, year }

/// A run of tokens between whitespace and separators, such as `20th` or `January,`.
///
class _Chunk {
  final String text;
  final int start;
  final int end;

  _Chunk(this.text, this.start, this.end);
}

/// Picks the date parts from anywhere in the text, in the order of [DatifyConfig.dayFirst].
///
/// Each chunk of the text is taken as the first part it fits that has not been found yet. This is
/// how Datify 1.x parsed dates, and it is used when [DatifyConfig.lenient] is true and the text has
/// no date that [Grammar] recognizes.
///
class LenientParser {
  final String _input;
  final List<Token> _tokens;
  final DatifyConfig _config;
  final Vocabulary _vocabulary;

  int? _year, _month, _day;
  int? _start, _end;
  var _isMonthNumeric = false;

  LenientParser(this._input, this._tokens, this._config, this._vocabulary);

  DatifyResult? parse() {
    final chunks = _chunks();

    // when the month goes first, a month name must not be taken for the day
    if (!_config.dayFirst) {
      for (final chunk in chunks) {
        final month = _vocabulary.monthOfText(chunk.text);
        if (month != null) {
          _month = month;
          _use(chunk);
          break;
        }
      }
    }

    final remainingParts = [
      ...(_config.dayFirst
          ? [_Part.day, _Part.month]
          : [_Part.month, _Part.day]),
      _Part.year,
    ];
    if (_month != null) {
      remainingParts.remove(_Part.month);
    }

    _Chunk? twoDigitYearChunk;
    int? twoDigitYear;

    for (final chunk in chunks) {
      if (_trySwapDayAndMonth(chunk, remainingParts)) {
        continue;
      }

      // a two-digit year is only used if no four-digit year follows
      if (_year == null && _day != null && _month != null) {
        final match = _twoDigitYearPattern.firstMatch(chunk.text);
        if (match != null) {
          twoDigitYearChunk ??= chunk;
          twoDigitYear ??= expandTwoDigitYear(int.parse(match[1]!));
          continue;
        }
      }

      for (final part in remainingParts) {
        final match = _patternOf(part).stringMatch(chunk.text);

        if (match == null) {
          if (_month != null) {
            continue;
          }

          final month = _vocabulary.monthOfText(chunk.text);
          if (month == null) {
            continue;
          }

          _month = month;
          _use(chunk);
          remainingParts.remove(_Part.month);
          break;
        }

        final value = int.parse(match);
        switch (part) {
          case _Part.day:
            _day = value;
          case _Part.month:
            _month = value;
            _isMonthNumeric = true;
          case _Part.year:
            _year = value;
        }

        _use(chunk);
        remainingParts.remove(part);
        break;
      }
    }

    if (_year == null && twoDigitYearChunk != null) {
      _year = twoDigitYear;
      _use(twoDigitYearChunk);
    }

    final start = _start, end = _end;
    if (start == null || end == null) {
      return null;
    }

    final day = _day, month = _month;
    return DatifyResult(
      year: _year,
      month: month,
      day: day,
      start: start,
      end: end,
      isAmbiguous: _isMonthNumeric &&
          day != null &&
          month != null &&
          day <= 12 &&
          month != day,
    );
  }

  List<_Chunk> _chunks() {
    final chunks = <_Chunk>[];
    int? start;

    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.isSeparator) {
        if (start != null) {
          chunks.add(_chunk(start, _tokens[i - 1].end));
          start = null;
        }
        continue;
      }

      if (start != null && _tokens[i - 1].end != token.start) {
        chunks.add(_chunk(start, _tokens[i - 1].end));
        start = null;
      }

      start ??= token.start;
    }

    if (start != null) {
      chunks.add(_chunk(start, _tokens.last.end));
    }

    return chunks;
  }

  _Chunk _chunk(int start, int end) =>
      _Chunk(_input.substring(start, end), start, end);

  /// Handles month-first dates when [DatifyConfig.dayFirst] is true: in `12/31/2021`, `12` is
  /// parsed as the day first, and since `31` cannot be a month, the two values are swapped.
  ///
  bool _trySwapDayAndMonth(_Chunk chunk, List<_Part> remainingParts) {
    final parsedDay = _day;
    if (!_config.dayFirst ||
        parsedDay == null ||
        parsedDay > 12 ||
        remainingParts.contains(_Part.day) ||
        !remainingParts.contains(_Part.month)) {
      return false;
    }

    final match = _dayPattern.stringMatch(chunk.text);
    if (match == null) {
      return false;
    }

    final value = int.parse(match);
    if (value <= 12) {
      return false;
    }

    _month = parsedDay;
    _day = value;
    _use(chunk);
    remainingParts.remove(_Part.month);
    return true;
  }

  void _use(_Chunk chunk) {
    final start = _start, end = _end;
    _start = start == null || chunk.start < start ? chunk.start : start;
    _end = end == null || chunk.end > end ? chunk.end : end;
  }

  static RegExp _patternOf(_Part part) => switch (part) {
        _Part.day => _dayPattern,
        _Part.month => _monthPattern,
        _Part.year => _yearPattern,
      };
}
