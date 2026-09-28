import 'dart:math';

import 'locale.dart';

final _nonLetterPattern = RegExp(r'[^\p{L}\p{M}]', unicode: true);
final _digitPattern = RegExp(r'\d');

/// The minimum length of an abbreviation matched against a month name, e.g. `sept`.
const _minAbbreviationLength = 3;

/// The minimum shared prefix for two words to be considered forms of the same word.
const _minStemLength = 4;

/// The maximum number of trailing characters that may differ between two forms of the same word.
const _maxEndingLength = 2;

/// Greater than any month ordinal; marks the absence of a match.
const _noMonth = 13;

final _vocabularies = Expando<Vocabulary>();

/// Lowercases [word] and removes the characters that are not letters.
///
String normalizeWord(String word) =>
    word.toLowerCase().replaceAll(_nonLetterPattern, '');

/// A prefix tree node of the month names.
///
/// Each node stores the lowest month ordinal among the names below it, so that when several
/// month names match a word, the earliest month wins.
///
class _MonthTrieNode {
  final children = <int, _MonthTrieNode>{};

  /// The lowest month of all names in this subtree.
  var month = _noMonth;

  /// The lowest month of the names in this subtree that are at most `i` characters longer than
  /// the prefix leading to this node, at index `i`.
  final monthByEndingLength = List.filled(_maxEndingLength + 1, _noMonth);

  void add(int month, int endingLength) {
    this.month = min(this.month, month);
    for (var i = endingLength; i <= _maxEndingLength; i++) {
      monthByEndingLength[i] = min(monthByEndingLength[i], month);
    }
  }
}

/// The words of a list of locales, indexed for lookup.
///
class Vocabulary {
  final _exactMonths = <String, int>{};
  final _trie = _MonthTrieNode();
  final ordinalSuffixes = <String>{};
  final connectors = <String>{};

  /// Returns the vocabulary of [locales], which is built once per list.
  ///
  factory Vocabulary.of(List<DatifyLocale> locales) =>
      _vocabularies[locales] ??= Vocabulary._(locales);

  Vocabulary._(List<DatifyLocale> locales) {
    for (final locale in locales) {
      if (locale.months.length != 12) {
        throw ArgumentError.value(locale.months.length, 'months',
            'A locale must have the names of 12 months');
      }

      for (var ordinal = 1; ordinal <= 12; ordinal++) {
        for (final name in locale.months[ordinal - 1].map(normalizeWord)) {
          _exactMonths.putIfAbsent(name, () => ordinal);
          _addToTrie(name, ordinal);
        }
      }

      ordinalSuffixes.addAll(locale.ordinalSuffixes.map(normalizeWord));
      connectors.addAll(locale.connectors.map(normalizeWord));
    }
  }

  void _addToTrie(String name, int month) {
    var node = _trie..add(month, name.length);
    for (var depth = 0; depth < name.length; depth++) {
      node = node.children
          .putIfAbsent(name.codeUnitAt(depth), _MonthTrieNode.new)
        ..add(month, name.length - depth - 1);
    }
  }

  /// Returns the month of a lowercase [word] of letters, or null if it is not a month name.
  ///
  int? monthOfWord(String word) => _exactMonths[word] ?? _findSimilar(word);

  /// Returns the month named in [text], ignoring the characters around the name that are not
  /// letters, such as in `(March)`.
  ///
  int? monthOfText(String text) {
    // an alphabetic month cannot contain digits
    if (_digitPattern.hasMatch(text)) {
      return null;
    }

    final word = normalizeWord(text);
    return word.isEmpty ? null : monthOfWord(word);
  }

  /// Returns the month of which the [word] is an abbreviation or a different form.
  ///
  /// A word is an abbreviation of a name if the name starts with it. Two words are forms of the
  /// same word if they share a prefix of at least [_minStemLength] characters, and neither has
  /// more than [_maxEndingLength] characters after it.
  ///
  int? _findSimilar(String word) {
    var best = _noMonth;
    var node = _trie;

    for (var depth = 0;; depth++) {
      if (depth >= _minStemLength && word.length - depth <= _maxEndingLength) {
        best = min(best, node.monthByEndingLength[_maxEndingLength]);
      }

      if (depth == word.length) {
        if (depth >= _minAbbreviationLength) {
          best = min(best, node.month);
        }
        break;
      }

      final next = node.children[word.codeUnitAt(depth)];
      if (next == null) break;
      node = next;
    }

    return best == _noMonth ? null : best;
  }
}
