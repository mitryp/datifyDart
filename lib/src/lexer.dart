/// Matches the letters that the fast paths of [_isLetter] don't cover.
final _letterPattern = RegExp(r'^[\p{L}\p{M}]$', unicode: true);

final _validatedSeparators = Expando<bool>();

enum TokenKind { number, word, separator, punctuation }

/// A run of digits, a run of letters, or a single other character of the input.
///
/// Whitespace is not a token; it only shows as a gap between two tokens.
///
final class Token {
  final TokenKind kind;
  final String text;
  final int start;
  final int end;

  Token(this.kind, this.text, this.start, this.end);

  late final int value = int.parse(text);
  late final String lowercase = text.toLowerCase();

  bool get isNumber => kind == TokenKind.number;
  bool get isWord => kind == TokenKind.word;
  bool get isSeparator => kind == TokenKind.separator;
}

/// Splits [input] into tokens; the characters in [separators] become separator tokens.
///
/// Throws an [ArgumentError] if a separator is not a single character, or is a letter, a digit, or
/// whitespace.
///
List<Token> tokenize(String input, Set<String> separators) {
  _validatedSeparators[separators] ??= _validateSeparators(separators);

  final tokens = <Token>[];
  final length = input.length;
  var i = 0;

  while (i < length) {
    final start = i;
    final unit = input.codeUnitAt(i);

    if (_isDigit(unit)) {
      do {
        i++;
      } while (i < length && _isDigit(input.codeUnitAt(i)));
      tokens.add(Token(TokenKind.number, input.substring(start, i), start, i));
      continue;
    }

    final codePoint = _codePointAt(input, i);
    if (_isLetter(codePoint)) {
      i += _lengthOf(codePoint);
      while (i < length) {
        final next = _codePointAt(input, i);
        if (!_isLetter(next)) break;
        i += _lengthOf(next);
      }
      tokens.add(Token(TokenKind.word, input.substring(start, i), start, i));
      continue;
    }

    i += _lengthOf(codePoint);
    if (_isWhitespace(codePoint)) {
      continue;
    }

    final text = input.substring(start, i);
    final kind =
        separators.contains(text) ? TokenKind.separator : TokenKind.punctuation;
    tokens.add(Token(kind, text, start, i));
  }

  return tokens;
}

bool _validateSeparators(Set<String> separators) {
  for (final separator in separators) {
    final codePoints = separator.runes;
    if (codePoints.length != 1 ||
        _isDigit(codePoints.first) ||
        _isLetter(codePoints.first) ||
        _isWhitespace(codePoints.first)) {
      throw ArgumentError.value(separator, 'separators',
          'A separator must be a single character that is not a letter, a digit, or whitespace');
    }
  }

  return true;
}

int _codePointAt(String input, int i) {
  final unit = input.codeUnitAt(i);
  if (unit & 0xFC00 == 0xD800 && i + 1 < input.length) {
    final next = input.codeUnitAt(i + 1);
    if (next & 0xFC00 == 0xDC00) {
      return 0x10000 + ((unit & 0x3FF) << 10) + (next & 0x3FF);
    }
  }

  return unit;
}

int _lengthOf(int codePoint) => codePoint > 0xFFFF ? 2 : 1;

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

/// Whether [codePoint] is a letter or a combining mark, with fast paths for the Latin and Cyrillic
/// scripts and for punctuation.
///
bool _isLetter(int codePoint) {
  if (codePoint < 0x80) {
    final lower = codePoint | 0x20;
    return lower >= 0x61 && lower <= 0x7A;
  }

  if (codePoint < 0xC0) {
    return codePoint == 0xAA || codePoint == 0xB5 || codePoint == 0xBA;
  }

  if (codePoint <= 0x2C1) {
    return codePoint != 0xD7 && codePoint != 0xF7;
  }

  if ((codePoint >= 0x300 && codePoint <= 0x36F) ||
      (codePoint >= 0x400 && codePoint <= 0x52F && codePoint != 0x482)) {
    return true;
  }

  if (codePoint >= 0x2000 && codePoint <= 0x206F) {
    return false;
  }

  return _letterPattern.hasMatch(String.fromCharCode(codePoint));
}

/// Whether [codePoint] is whitespace, as matched by `\s` in regular expressions.
///
bool _isWhitespace(int codePoint) {
  if (codePoint <= 0x20) {
    return codePoint == 0x20 || (codePoint >= 0x09 && codePoint <= 0x0D);
  }

  if (codePoint < 0xA0) {
    return codePoint == 0x85;
  }

  return codePoint == 0xA0 ||
      codePoint == 0x1680 ||
      (codePoint >= 0x2000 && codePoint <= 0x200A) ||
      codePoint == 0x2028 ||
      codePoint == 0x2029 ||
      codePoint == 0x202F ||
      codePoint == 0x205F ||
      codePoint == 0x3000 ||
      codePoint == 0xFEFF;
}
