## 2.0.0

A new parser that recognizes the shapes of dates instead of picking date parts from anywhere in the text, and an
immutable configuration. See the "Migrating from 1.x" section of the README.

**Breaking changes**

- `Datify` is now a parser configured with an immutable `DatifyConfig`: `const Datify().parse(text)`. The static
  `DatifyConfig` settings and methods are removed.
- `Datify.parse` returns a `DatifyResult?`, which is null when the text has no date. The `Datify` fields and the
  `Datify.fromValues` and `Datify.empty` constructors are removed, as are the predefined values of `Datify.parse`
  and `DatifyResult.toMap`.
- Dates are only recognized in the supported formats, so numbers and month names around them are no longer taken for
  date parts: `Room 12, meeting on 5 May 2020` is May 5, and `12 2020 march` has no date. The 1.x behavior is
  available with `DatifyConfig(lenient: true)`, which is used when no date is recognized.
- A month name or a year alone, as in `May` or `Junk 2020`, is no longer a date. A month name needs a day or a year
  next to it: `May 5`, `May 2021`.
- Month names are configured as `DatifyLocale`s, replacing `DatifyConfig.months`, `addNewMonthName`, and
  `addNewMonthsLocale`.
- `DatifyConfig.splitters` is renamed to `separators`, and takes single characters that are not letters, digits, or
  whitespace; other separators throw an `ArgumentError`. Whitespace always separates date parts.

**New features**

- `DatifyResult.start` and `end` give the position of the date in the text.
- `DatifyResult.isAmbiguous` tells when the day and month could be read in the other order, as in `05/06/2021`.
- `Datify.parseAll` finds every date in the text.
- Added German, French, Spanish, and Polish month names, and the `2021-Mar-05` format.
- Locales can choose which languages are recognized, and define ordinal suffixes (`20th`) and connecting words
  (`20 of May`, `5 de mayo`).

**Performance**

The text is now read in a single pass by a hand-written lexer. Median time per `Datify.parse` call (AOT-compiled,
Dart 3.13, Apple M2 Pro), with 7 languages instead of 3:

| Input                                            | 1.2.0  | 2.0.0   | Speedup |
|--------------------------------------------------|--------|---------|---------|
| Digits (`31.12.2021`)                            | 1.8 µs | 0.24 µs | 7.4×    |
| General format (`2022-02-23`)                    | 1.1 µs | 0.22 µs | 4.8×    |
| English month names (`11 July 2020`)             | 3.0 µs | 0.33 µs | 9.2×    |
| Ukrainian/Russian names (`6 липня 2021`)         | 4.8 µs | 0.47 µs | 10.2×   |
| Not a date (`hello world`)                       | 5.1 µs | 0.26 µs | 19.5×   |
| Digits, `dayFirst: false` (`12.31.2021`)         | 2.1 µs | 0.25 µs | 8.4×    |
| Date in a sentence (`Room 12, meeting on 5 May`) | —      | 0.65 µs |         |

## 1.2.0

- Fixed non-existent dates (e.g. `31.02.2021`) being rolled over to the next month by the `date`
  getters; they now return `null`.
- Fixed words that merely start like a month name (`Maybe`, `Junk`, `Decent`) being parsed as
  months. Month names are now matched exactly, as abbreviations (`Sept`), or as forms that differ
  only in a short ending. Surrounding punctuation is ignored.
- Added the Ukrainian and Russian genitive month forms (`січня`, `января`, ...) to the defaults.
  Inflected forms of custom locales with a short stem may need to be added with
  `DatifyConfig.addNewMonthName`.
- Added support for ISO 8601 timestamps, e.g. `2020-01-01T10:00:00Z`.
- Month-first dates such as `12/31/2021` are now detected when `dayFirst` is `true` and the day is
  greater than 12.
- Added support for two-digit years after the day and month, e.g. `15.03.22`: 00–68 are read as
  2000–2068, and 69–99 as 1969–1999.
- Improved parsing performance by caching regular expressions and indexing month names in a lookup
  table and a prefix tree.
  Median time per `Datify.parse` call (AOT-compiled, Dart 3.13, Apple M2 Pro):

  | Input                                    | 1.1.6    | 1.2.0   | Speedup |
  |------------------------------------------|----------|---------|---------|
  | Digits (`31.12.2021`)                    | 3.1 µs   | 1.8 µs  | 1.7×    |
  | General format (`2022-02-23`)            | 2.3 µs   | 1.1 µs  | 2.1×    |
  | English month names (`11 July 2020`)     | 17.6 µs  | 3.1 µs  | 5.7×    |
  | Ukrainian/Russian names (`6 липня 2021`) | 14.8 µs  | 4.8 µs  | 3.1×    |
  | Not a date (`hello world`)               | 100.1 µs | 5.1 µs  | 19.6×   |
  | Digits, `dayFirst: false` (`12.31.2021`) | 3.5 µs   | 2.1 µs  | 1.7×    |
- Raised the minimum Dart SDK version to 3.0.0.
- Replaced the example with a shorter one showing the supported inputs.

## 1.1.6

- Fixed Pub static analysis warnings about angle brackets being interpreted as HTML.

## 1.1.5

- Fixed a link in the README.

## 1.1.4

- Fixed typos and grammar mistakes in the README.md.
- Updated package description.
- Reordered the CHANGELOG.md for the latest changes to appear first.

## 1.1.3

- Raised the maximum Dart SDK version to support Dart 3.
- Added the issue tracker link to the pubspec file.
- Changed the `IndexError` to `StateError` to remove the deprecation warning and keep the minimum Dart SDK version at
  2.17.0.

## 1.1.2

- Improved overall performance of parsing.
- Significantly improved performance of parsing dates in American format, i.e. when the month goes first.
- Code readability, internal structure, and logic improvements.

## 1.1.1

- Fixed bug causing the inability to parse day values which start with zero (e.g. `02`).
- Improved internal structure, split the source code into multiple files to improve readability.
- Several code readability improvements, still to be cleaned up.

## 1.1.0

- Changed the minimum Dart SDK version to 2.17.0.
- Changed `complete` getter in the `Datify` and `DatifyResult` classes to `isComplete` to follow the Effective Dart
  guidelines.

## 1.0.4

- Fixed a mistake in README.

## 1.0.3

- Extended the example in README.

## 1.0.2

- Added the documentation link in README.

## 1.0.1

- Formatted with `dart format .`.

## 1.0.0

- Initial version.
- Fully rewritten the [Python implementation](https://github.com/mitryp/datify) of Datify in Dart.
- Major logic and core improvements.
- Written the unit tests to cover all expected cases of usage.
~~~~