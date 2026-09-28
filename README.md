[![Dart Tests](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml/badge.svg)](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml?branch=master)
[![pub package](https://img.shields.io/pub/v/datify.svg)](https://pub.dev/packages/datify)
[![package publisher](https://img.shields.io/pub/publisher/datify.svg)](https://pub.dev/packages/datify/publisher)

## Find dates in text, in _(nearly)_ any format.

**Datify** makes it easy to find dates in strings: digit-only dates in either day-month order, ISO 8601 timestamps,
and dates with month names in 7 languages.

You only need to pass the text to Datify, and it's all good: it will tell you the date, where it is in the text, and
whether its day and month could be read the other way around.

[Documentation link](https://pub.dev/documentation/datify/latest/)

## Installation

```shell
dart pub add datify
```

## Example

```dart
import 'package:datify/datify.dart';

void main() {
  const datify = Datify();

  final result = datify.parse('Room 12, meeting on 20th of January, 2021')!;
  print(result.date); // 2021-01-20 00:00:00.000
  print(result.start); // 20

  print(datify.parseAll('from 1.02.2021 to 2021-03-15').length); // 2
}
```

Datify handles the following inputs out of the box:

| Input                                        | Result                 |
|----------------------------------------------|------------------------|
| `31.12.2021`                                 | 2021-12-31             |
| `2022-02-23T10:00:00Z`                       | 2022-02-23             |
| `20th of January, 2021`                      | 2021-01-20             |
| `Sept 5, 2020`                               | 2020-09-05             |
| `14 лютого 2022`                             | 2022-02-14             |
| `3 січ 26`                                   | 2026-01-03             |
| `5. Mai 2020`                                | 2020-05-05             |
| `12/31/2021`                                 | 2021-12-31             |
| `05/06/2021`                                 | 2021-06-05 (ambiguous) |
| `Room 12, meeting on 15 March 2022 at 10:30` | 2022-03-15             |
| `January 2021`                               | year 2021, month 1     |
| `31.02.2021`                                 | not an existing date   |
| `Maybe tomorrow`                             | no date found          |

See [`example/datify_example.dart`](https://github.com/mitryp/datifyDart/blob/master/example/datify_example.dart) for
the code that produces this table.

---

## Parsing

To find a date in a string, create a `Datify` parser and call one of its methods:

* `parse(text)` returns the first date in the text as a `DatifyResult`, or `null` if there is none;
* `parseAll(text)` returns all dates in the text, in the order they appear.

```dart
const datify = Datify();

const text = 'Booked on 2021-03-01 for 14 May 2021';
for (final result in datify.parseAll(text)) {
  print(text.substring(result.start, result.end)); // 2021-03-01, then 14 May 2021
}
```

### Getting the result

A `DatifyResult` has the following fields:

| Field                  | Description                                                                                   |
|------------------------|-----------------------------------------------------------------------------------------------|
| `year`, `month`, `day` | The date parts. Any of them may be null for partial dates, such as `January 2021`.            |
| `isComplete`           | Whether the year, month, and day were all found.                                              |
| `date`                 | The result as a `DateTime`, or null if it is incomplete or doesn't exist (e.g. `31.02.2021`). |
| `start`, `end`         | The position of the date in the text.                                                         |
| `isAmbiguous`          | Whether the day and month could be read in the other order, as in `05/06/2021`.               |

So, to use a date that may be partial, read its parts:

```dart
final result = datify.parse('Invoice for January 2021');
print(result?.isComplete); // false
print(result?.date); // null
print('${result?.year}, ${result?.month}'); // 2021, 1
```

## Formats

> In the formats below, `$` stands for whitespace or any of the separators (`.`, `/`, `-` by default).
> The separators can be combined in one date, e.g. _23-02/2022_.

* Digit-only dates: `DD$MM$YYYY` or `MM$DD$YYYY` - e.g. _31.12.2021_, _12/31/2021_, _31 12 2021_;
* Year-first dates: `YYYY$MM$DD` or `YYYYMMDD` - e.g. _2021-12-31_, _20211231_, and ISO 8601 timestamps such as
  _2021-12-31T10:00:00Z_;
* **Dates with month names in different languages** - e.g. _20th of January, 2021_, _Jan 20, 2021_, _2021-Jan-20_,
  _14 лютого 2022_, _5 de mayo de 2020_;
* Partial dates with month names - e.g. _January 2021_, _20 of January_, _Jan 20_;
* Two-digit years - e.g. _15.03.22_, _5 May 99_. The years `00–68` are read as `2000–2068`, and `69–99` as
  `1969–1999`.

A digit-only date is read in the order set by `dayFirst`, unless one of its numbers is greater than 12: `12/31/2021`
is always December 31.

> Month names are matched exactly, as abbreviations (_Sept_), or as forms that differ only in a short ending
> (_марте_ for _март_). Words that merely start like a month name, such as _Maybe_ or _Junk_, are not months.

### Month name languages supported by default:

- [x] English
- [x] Ukrainian
- [x] Russian
- [x] German
- [x] French
- [x] Spanish
- [x] Polish

## Configuring Datify

The behavior of a `Datify` parser is set with an immutable `DatifyConfig`:

```dart
const datify = Datify(DatifyConfig(
  dayFirst: false, // read 05/06/2021 as May 6
  separators: {'/', '.', '-', '#'}, // besides whitespace
  locales: [DatifyLocale.en, DatifyLocale.de],
  lenient: true,
));
```

| Option       | Default                | Description                                                      |
|--------------|------------------------|------------------------------------------------------------------|
| `dayFirst`   | `true`                 | Whether the day comes first in ambiguous digit-only dates.       |
| `separators` | `{'/', '.', '-'}`      | Single characters that separate the numbers of a date.           |
| `locales`    | `DatifyLocale.builtIn` | The languages of month names.                                    |
| `lenient`    | `false`                | See [Lenient parsing](#lenient-parsing).                         |

> Create the parser once and reuse it: the month names of its locales are indexed on the first parse.

### Adding a language

To add a new language, define a `DatifyLocale` with the names of its 12 months, and pass it along with the built-in
ones:

```dart
const italian = DatifyLocale(
  months: [
    ['gennaio'], ['febbraio'], ['marzo'], ['aprile'],
    ['maggio'], ['giugno'], ['luglio'], ['agosto'],
    ['settembre'], ['ottobre'], ['novembre'], ['dicembre'],
  ],
  connectors: ['di'], // as in "14 di luglio"
);

const datify = Datify(DatifyConfig(locales: [...DatifyLocale.builtIn, italian]));
```

Each month takes a list of names, starting with January. Abbreviations don't need to be listed, but inflected forms
do if their stem is shorter than 4 letters or their ending is longer than 2 letters (like the Ukrainian _січня_ for
_січень_).

A locale can also define `ordinalSuffixes`, like _th_ in _20th_, and `connectors`, like _of_ in _20th of January_.

### Lenient parsing

By default, Datify only recognizes the [formats](#formats) above, so _12 2020 march_ or _Decent 12 2020_ return
`null`.

With `lenient: true`, when no such date is found, Datify picks any numbers and month names that fit a date part, just
as Datify 1.x did: _12 2020 march_ becomes March 12, 2020. This finds dates in more unusual orders, but may also take
unrelated numbers for date parts. In this case, `parseAll` returns the picked date parts as a single result.

## Migrating from 1.x

| 1.x                                              | 2.0                                                     |
|--------------------------------------------------|---------------------------------------------------------|
| `Datify.parse(text).date`                        | `const Datify().parse(text)?.date`                      |
| `Datify.parse(text).result`                      | `const Datify().parse(text)`                            |
| `DatifyConfig.dayFirst = false`                  | `Datify(DatifyConfig(dayFirst: false))`                 |
| `DatifyConfig.splitters.add('#')`                | `DatifyConfig(separators: {'/', '.', '-', '#'})`        |
| `DatifyConfig.addNewMonthsLocale([...])`         | `DatifyConfig(locales: [...DatifyLocale.builtIn, ...])` |
| `Datify.parse(text, year: 2021)`                 | `result?.year ?? 2021`                                  |
| `DatifyResult.toMap()`                           | `{'year': result.year, ...}`                            |
| Date parts picked from anywhere in the text      | `DatifyConfig(lenient: true)`                           |

## Motivation

Datify was originally developed in Python in the summer of 2021, when I was working on my first pet project, which
needed to support user input of dates in various formats.

It was fascinating to write, and I decided to maintain the library.

In the Dart implementation, there are several major logic and performance improvements.

Also, the regular expressions used in Python were replaced with new ones, which work more predictably.
