import 'dart:math';

import '../config.dart';
import '../util.dart';

final _nonLetterPattern = RegExp(r'[^\p{L}]', unicode: true);
final _digitPattern = RegExp(r'\d');

/// The minimum length of an abbreviation matched against a month name, e.g. `sept`.
const _minAbbreviationLength = 3;

/// The minimum shared prefix for two words to be considered forms of the same word.
const _minStemLength = 4;

/// The maximum number of trailing characters that may differ between two forms of the same word.
const _maxEndingLength = 2;

/// Greater than any month ordinal; marks the absence of a match.
const _noMonth = 13;

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

/// The month names indexed for lookup.
///
class _MonthIndex {
  final exact = <String, int>{};
  final trie = _MonthTrieNode();

  _MonthIndex(List<Set<String>> months) {
    for (var ordinal = 1; ordinal <= months.length; ordinal++) {
      for (final name in months[ordinal - 1]) {
        exact.putIfAbsent(name, () => ordinal);
        _addToTrie(name, ordinal);
      }
    }
  }

  void _addToTrie(String name, int month) {
    var node = trie..add(month, name.length);
    for (var depth = 0; depth < name.length; depth++) {
      node = node.children
          .putIfAbsent(name.codeUnitAt(depth), _MonthTrieNode.new)
        ..add(month, name.length - depth - 1);
    }
  }

  /// Returns the month of which the [word] is an abbreviation or a different form.
  ///
  /// A word is an abbreviation of a name if the name starts with it. Two words are forms of the
  /// same word if they share a prefix of at least [_minStemLength] characters, and neither has
  /// more than [_maxEndingLength] characters after it.
  ///
  int? findSimilar(String word) {
    var best = _noMonth;
    var node = trie;

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

_MonthIndex? _index;
var _indexedNameCount = -1;

/// Returns the index of [DatifyConfig.months], rebuilding it when the number of names changes.
///
/// Hashing the names instead would catch every change, but costs more than the lookup itself.
///
_MonthIndex get _monthIndex {
  final months = DatifyConfig.months;
  final nameCount = months.fold<int>(0, (count, names) => count + names.length);

  if (_index == null || nameCount != _indexedNameCount) {
    _index = _MonthIndex(months);
    _indexedNameCount = nameCount;
  }

  return _index!;
}

/// Parses a string to get a month ordinal number in range [1,12] inclusive.
///
/// Firstly checks if the [DatifyConfig.months] field contains the input string itself.
///
/// If the months list does not contain the input string, then tries to find a month name of which
/// the input is an abbreviation (`sept`) or a different form (`januari`).
///
/// If no corresponding month name is found, then returns null.
///
int? tryParseMonth(String input) {
  // an alphabetic month cannot contain digits
  if (_digitPattern.hasMatch(input)) {
    return null;
  }

  final word = normalize(input).replaceAll(_nonLetterPattern, '');
  if (word.isEmpty) {
    return null;
  }

  final index = _monthIndex;
  return index.exact[word] ?? index.findSimilar(word);
}
