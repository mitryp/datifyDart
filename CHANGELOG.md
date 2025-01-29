# 1.1.6

- Fixed Pub static analysis warnings about angle brackets being interpreted as HTML.

# 1.1.5

- Fixed a link in the README.

# 1.1.4

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