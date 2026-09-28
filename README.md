[![Dart Tests](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml/badge.svg)](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml?branch=master)
[![pub package](https://img.shields.io/pub/v/datify.svg)](https://pub.dev/packages/datify)
[![package publisher](https://img.shields.io/pub/publisher/datify.svg)](https://pub.dev/packages/datify/publisher)

## Flexible automatic date extracting from strings in any formats.

**Datify** makes it easy to extract dates from strings in _(nearly)_ any formats.

You will need only to parse the date string with Datify, and it's all good.

The date formats supported by Datify are the following:

* Day first digit-only dates: 20.02.2020, 09/07/2000, 9-1-2005;
* Month first digit-only dates: 02 22 2020, 09.07.2000, 1.9/2005;
* Dates in the general date format and ISO 8601 timestamps: 2020-04-15, 2020-04-15T10:00:00Z;
* Two-digit years: 15.03.22, 5 May 99;
* **Alphanumeric dates in different languages**: 11th of July 2020; Sept 5, 2020; 6 липня 2021; 31 декабря, 2021.

See the [Formats](#Formats) section for the detailed information about the supported formats.

The behavior of Datify can be configured with DatifyConfig - see [Configuration](#Configuring-Datify) section.

### Month name languages supported by default:

- [x] English
- [x] Ukrainian
- [x] Russian

[Documentation link](https://pub.dev/documentation/datify/latest/)

## Example

```dart
import 'package:datify/datify.dart';

void main() {
  final datify = Datify.parse('20th of January, 2021');

  print(datify.date); // 2021-01-20 00:00:00.000
  print(datify.result); // DatifyResult{year: 2021, month: 1, day: 20}
}
```

Datify handles the following inputs out of the box:

| Input                                   | Result                  |
|-----------------------------------------|-------------------------|
| `31.12.2021`                            | 2021-12-31              |
| `2022-02-23T10:00:00Z`                  | 2022-02-23              |
| `20th of January, 2021`                 | 2021-01-20              |
| `Sept 5, 2020`                          | 2020-09-05              |
| `14 лютого 2022`                        | 2022-02-14              |
| `3 січ 26`                              | 2026-01-03              |
| `12/31/2021`                            | 2021-12-31              |
| `The meeting on 15 March 2022 at 10:30` | 2022-03-15              |
| `20 of January`                         | month 1, day 20         |
| `31.02.2021`                            | not an existing date    |
| `Maybe tomorrow`                        | no date found           |

With `DatifyConfig.dayFirst = false`, `05/06/2021` is read as May 6, and after adding French month names with
`DatifyConfig.addNewMonthsLocale`, `14 juillet 2021` is parsed as 2021-07-14.

See [`example/datify_example.dart`](https://github.com/mitryp/datifyDart/blob/master/example/datify_example.dart) for the code that produces this table.

---

## Data parsing

To extract a date from a string, use the `.parse` constructor of the `Datify` class.
The constructor takes a nullable input string and optional parameters `year`, `month`, and `day`.

After that the input string will be parsed. If the optional parameters were given, the respective object fields will
have the provided values.

Datify class has the `.fromValues` constructor that takes only optional parameters `year`, `month`, and `day` to create
the instance of the class without parsing, and `.empty` constructor that will create a Datify object with all the values
set to null.

### Getting the result

After the parsing is done, the result can be retrieved in a different ways:

* If the date is complete, the result can be transformed into a `DateTime` object with the `DateTime? date` getter.

  However, if the date is incomplete or does not exist (e.g. `31.02.2021`), the `date` getter will return null.

  The result is considered complete when the `year`, `month`, and `day` fields of the result are not null.

  To make sure the parsed result is complete and can be transformed to a DateTime, the `bool isComplete` getter is used.


* To get a non-nullable result independent of the parsing result, use the `DatifyResult result` getter.

  It will return a `DatifyResult` object which is not nullable by itself, but its fields may be null.

  The `DatifyResult` object has the nullable `year`, `month`, and `day` final fields, the `isComplete` and `date` getters
  that work just as the respective getters of the Datify instances. Moreover, the DatifyResult object can be transformed
  to a `Map<String, int?>` with the predefined structure. See the DatifyResult description for more details.


* The Datify instance itself has the mutable nullable fields `year`, `month`, and `day`, which can be used to access
  the parsing result.

## Formats

> In the formats below, the sign `$` represents any of the supported date splitters.
>
> The `$?` sign represents an optional separator character (the separator may or may not be present).

- General date format: `YYYY$?MM$?DD` - e.g. _20210706_ or _2022-02-23_ etc. The date may be followed by a time, as in
  ISO 8601 timestamps: _2022-02-23T10:00:00Z_;

- `Alphanumeric dates in different languages` - e.g. _6th of July 2021_, _31st of December 2021_, _20 жовтня_, _1 июля_
  etc;
  > Month names are matched exactly, as abbreviations (_Sept_), or as forms that differ only in a short ending
  (_январ**я**_). Words that merely start like a month name, such as _Maybe_ or _Junk_, are not treated as months.

When the `dayFirst` is set to `true`:

- The most common digit-only date format: `DD$MM$YYYY` - e.g. _20.01.2022_;

When the `dayFirst` is set to `false`:

- American digit date format (the month is first): `MM$DD$YYYY` - e.g. _12.31.2021_;

Regardless of `dayFirst`, a date is read in the other order when the day would otherwise be out of range, e.g. _12.31.2021_
is parsed as December 31 even when `dayFirst` is `true`.

A two-digit year is accepted after the day and month (_15.03.22_) when no four-digit year is present: _00–68_ are
read as _2000–2068_, and _69–99_ as _1969–1999_.

> When the `dayFirst` is set to `false`, Datify will try to find the alphabetic month names before the parsing to avoid
losing the month values in the strings of the format '1 of July 2020'. However, this makes the parsing a bit slower with
this option enabled.

## Configuring Datify

The library behavior can be customized with the `DatifyConfig` class fields and methods.

The following can be customized:

1. Date splitters (`.`, `/`, `-`, ` ` by default).

   Any of the supported splitters can be present in digit-only or alphanumeric dates (See [Formats](#formats) section
   of the documentation).

   To define a new custom separator, it must be added to the `DatifyConfig.splitters` set.

   For instance, to add the `#` separator to the config, the following syntax is used:
   ```dart
   DatifyConfig.splitters.add('#');
   ```
   After that the next `Datify.parse()` invocations will use the added splitter in the parsing operations.
   > Splitters can also be string more than one character long


2. Month names localization, different month aliases.
   By default, Datify supports English, English shortened, Ukrainian and Russian month names:
   `{'january','jan','січень','январь',}`

   More localizations can be added whenever they needed with `DatifyConfig`:


* To add a new month name for the specific month, the `DatifyConfig.addNewMonthName(int ordinal, String name)` method
  is used. The `ordinal` argument takes int number in range [1, 12] inclusive to represent the month number.

  For example, to add the French name, `Septembre`, for the 9th month, the following syntax is used:
  ```dart
  DatifyConfig.addNewMonthName(9, 'Septembre');
  ```
  _If the `ordinal` is not in the defined range, the StateError will be thrown._


* To add an entire new localization, which consists of 12 ordered month names, the
  `DatifyConfig.addNewMonthsLocale(Iterable<String> monthNames)` method is used.

  > The `monthNames` iterable must have the length of 12 and consist of the unique elements
  If these conditions are not satisfied, the ArgumentError will be thrown.

  For example, to add the French month localization, the following syntax is used:
  ```dart
  const frenchMonths = [
     'Janvier', 'Février', 'Mars', 'Avril', 'Peut', 'Juin',
     'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 
     'Décembre'
   ];
  
  DatifyConfig.addNewMonthsLocale(frenchMonths);
  ```
  > If the language inflects month names, add the inflected forms with `addNewMonthName` as well: forms with a stem
  shorter than 4 letters or an ending longer than 2 letters are not recognized automatically.
  > Note: The months should be ordered in the months order for the correct work.

### Motivation
Datify was originally developed in Python in the summer of 2021, when I
was working on my first pet project which needed to support user input of dates in various formats.

It was fascinating to write, and I decided to maintain the library.

In Dart implementation, there are several major logic and performance improvements;

Also, the regular expressions used in Python were replaced with the new ones, which work more predictable.
