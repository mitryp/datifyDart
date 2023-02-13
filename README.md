[![Dart Tests](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml/badge.svg)](https://github.com/mitryp/datifyDart/actions/workflows/dart.yml?branch=master)
[![pub package](https://img.shields.io/pub/v/datify.svg)](https://pub.dev/packages/datify)
[![package publisher](https://img.shields.io/pub/publisher/datify.svg)](https://pub.dev/packages/datify/publisher)

## Automatic flexible date extracting from strings in any formats.

**Datify** makes it easy to extract dates from strings in _(nearly)_ any formats.

You will need only to parse the date string with Datify, and it's all good.

The date formats supported by Datify are the following:

* Day first digit-only dates: 20.02.2020, 09/07/2000, 9-1-2005;
* Month first digit-only dates: 02 22 2020, 09.07.2000, 1.9/2005;
* Dates in the general date format: 2020-04-15;
* **Alphanumeric dates in different languages**: 11th of July 2020; 6 липня 2021; 31 декабря, 2021.

See the [Formats](#Formats) section for the detailed information about the supported formats.

The behavior of Datify can be configured with the DatifyConfig - see [Configuration](#Configuring-Datify) section.

### Month name languages supported by default:

- [x] English
- [x] Ukrainian
- [x] Russian

[Documentation link](https://pub.dev/documentation/datify/latest/)

## Example

___
See the `example/datify_example.dart` for full example.

```dart
String handleRequest(SearchRequest searchRequest) {
  final dateQuery = searchRequest['date'];

  // the Datify handles all the parsing inside freeing
  // you from even thinking about it!
  final res = Datify
      .parse(dateQuery)
      .result;

  // make the search request
  final response =
      Events.query(year: res.year, month: res.month, day: res.day) ?? 'No events found for this query 👀';

  return response;
}

void main() {
  // define dates in the different formats
  const dates = [
    '31.12.2021',     // common digit-only date format
    '2022-02-23',     // another commonly-used date format
    '23-02/2022',     // the supported separators can be combined in the string
    '20 of January',  // date is incomplete but still correctly parsed
    'May',            // just a month name
    '14 лютого 2022', // Ukrainian date which stands for 14.02.2022
    'not a date',     // not a date at all
  ];

  // 'request' all the dates
  for (var date in dates) {
    print('$date: ${handleRequest({'date': date})}');
  }
}

/// Database emulation for the example.
///
/// This class stored dates and the corresponding event descriptions and provides the method for
/// record requesting from the storage.
///
abstract class Events {
  /// Stores the dates and the corresponding event descriptions.
  ///
  static const _records = {
    Date(year: 2021, month: 12, day: 31): 'New Year party 🎄',
    Date(year: 2022, month: 1, day: 20): 'Birthday celebration 🎁',
    Date(year: 2022, month: 2, day: 14): 'St. Valentines Day 💖',
    Date(year: 2022, month: 2, day: 23): 'The cinema attendance 📽',
    Date(year: 2022, month: 5, day: 23): 'A long-awaited Moment 🔥',
  };

  /// Returns an event descriptions based on the provided date parts.
  ///
  /// If no date parts provided or no corresponding event descriptions are found, the method returns
  /// null.
  ///
  static String? query({int? year, int? month, int? day}) {
    // handle empty requests
    if (year == null && month == null && day == null) {
      return null;
    }

    // find the first event corresponding to the given date
    final res = _records.entries
        .firstWhere(
            (record) =>
            record.key.satisfies(year: year, month: month, day: day),
        orElse: () => MapEntry(Date.empty(), ''))
        .value;
    return (res.isEmpty ? null : res);
  }
}
```

The output of the example above:

```plaintext
31.12.2021: New Year party 🎄
2022-02-23: The cinema attendance 📽
23-02/2022: The cinema attendance 📽
20 of January: Birthday celebration 🎁
May: A long-awaited Moment 🔥
14 лютого 2022: St. Valentines Day 💖
not a date: No events found for this query 👀
```

_Uncritical code was omitted._

---

## Data parsing

To extract a date from a string, use the `.parse` constructor of the `Datify` class.
The constructor takes a nullable input string and the optional parameters `year`, `month`, and `day`.

After that the input string will be parsed. If the optional parameters were given, the respective object fields will
have the provided values.

Datify class has the `.fromValues` constructor that takes only optional parameters `year`, `month`, and `day` to create
the instance of the class without parsing, and `.empty` constructor that will create a Datify object with all the values
set to null.

### Getting the result

After the parsing is done, the result can be retrieved in a different ways:

* If the date is complete, the result can be transformed into a `DateTime` object with the `DateTime? date` getter.

  However, if the date is incomplete the `date` getter will return null.

  The result is considered complete when the `year`, `month`, and `day` fields are not null of the result are not null.

  To make sure the parsed result is complete and can be transformed to a DateTime, the `bool isComplete` getter is used.


* To get the not nullable result independent of the parsing result, use the `DatifyResult result` getter.

  It will return a `DatifyResult` object which is not nullable by itself, but its fields may be null.

  The `DatifyResult` object has the nullable `year`, `month`, and `day` final fields, the `isComplete` and `date` getters
  that work just as the respective getters of the Datify instances. Moreover, the DatifyResult object can be transformed
  to a `Map<String, int?>` with the predefined structure. See the DatifyResult description for more details.


* The Datify instance itself has the `year`, `month`, and `day` mutable nullable fields, that can be used to access
  the parsing result.

## Formats

> In the formats below, the sign `$` represents any of the supported date splitters.
>
> The `$?` sign represents an optional separator character (the separator may or may not be present).

- General date format: `YYYY$?MM$?DD` - e.g. _20210706_ or _2022-02-23_ etc;

- `Alphanumeric dates in different languages` - e.g. _6th of July 2021_, _31st of December 2021_, _20 жовтня_, _1 июля_
  etc;
  > Datify tries to find different forms of month names in the natural languages where they are present.

When the `dayFirst` is set to `true`:

- The most common digit-only date format: `DD$MM$YYYY` - e.g. _20.01.2022_;

When the `dayFirst` is set to `false`:

- American digit date format (the month is first): `MM$DD$YYYY` - e.g. _12.31.2021_;

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


2. Month names localizations, different month aliases.
   By default, Datify supports English, English shortened, Ukrainian and Russian month names:
   `{'january','jan','січень','январь',}`

   More localizations can be added whenever they needed with the `DatifyConfig`:


  * To add a new month name for the specified month, the `DatifyConfig.addNewMonthName(int ordinal, String name)` method
    is used. The `ordinal` argument takes int number in range [1, 12] inclusive to represent the month number.

    For example, to add the French name, `Septembre`, for the 9th month, the following syntax is used:
    ```dart
    DatifyConfig.addNewMonthName(9, 'Septembre');
    ```
    _If the `ordinal` is not in the defined range, the IndexError will be thrown._


* To add a new entire localization, which consists of the 12 ordered month names, the
  `DatifyConfig.addNewMonthsLocale(Iterable<String> monthNames)` method is used.

  > The `monthNames` iterable must have a length of 12 and consist of the unique elements
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
  > Note: The months should be ordered in the months order for the correct work.

### Motivation
The Datify library was originally [developed](https://github.com/mitryp/datify) in Python in the summer of 2021, when I 
was working on my first pet project which needed to support user input of dates in any formats.

It was fascinating to write, and I decided to maintain the library.

In the Dart implementation, there are several major logic improvements;

Also, the regular expressions used in Python were replaced with the new ones, that work more predictable.
