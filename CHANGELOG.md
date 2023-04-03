## 1.0.0

- Initial version.
- Fully rewritten the [Python implementation](https://github.com/mitryp/datify) of Datify in Dart.
- Major logic and core improvements.
- Written the unit tests to cover all expected cases of the usage.

## 1.0.1

- Formatted with `dart format .`.

## 1.0.2

- Added the documentation link in README.

## 1.0.3

- Extended the example in README.

## 1.0.4

- Fixed a mistake in README.

## 1.1.0

- Changed the minimum Dart SDK version to 2.17.0.
- Changed `complete` getter in the `Datify` and `DatifyResult` classes to `isComplete` to follow the Effective Dart
  guidelines.

## 1.1.1

- Fixed bug causing the inability to parse day values which start with zero (e.g. `02`).