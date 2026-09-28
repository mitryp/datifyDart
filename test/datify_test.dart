import 'dart:math';

import 'package:datify/datify.dart';
import 'package:test/test.dart';

// seeded to make failures of the random tests reproducible
final _random = Random(20260928);

void main() {
  // Test the Datify parsing on the defined digit dates with a different date splitters
  group('Digit dates test', () {
    const strings = [
      '31.12.2021',
      '20/01/2022',
      '14 02 2022',
    ];

    test('days are defined correctly', () {
      for (var s in strings) {
        final d = Datify.parse(s);
        expect(d.day, int.parse(s.substring(0, 2)));
      }
    });

    test('digit months are defined correctly', () {
      for (var s in strings) {
        final d = Datify.parse(s);
        expect(d.month, int.parse(s.substring(3, 5)));
      }
    });

    test('years are defined correctly', () {
      for (var s in strings) {
        final d = Datify.parse(s);
        expect(d.year, int.parse(s.substring(6)));
      }
    });

    test('multiline dates are defined correctly', () {
      expect(
        Datify.parse('''31.
        12
        .2003''').isComplete,
        true,
      );
    });
  });

  // Test the Datify parsing alphabetic months in different formats correctly
  group('Alphabetic months tests', () {
    const dates = {
      '10 мая 2022': 5,
      '20th of January, 2021': 1,
      '14 лютого 2022': 2,
      '3 of may 2018': 5
    };

    test('alphabetic months are defined correctly', () {
      for (var date in dates.keys) {
        final d = Datify.parse(date);
        expect(d.month, dates[date]);
      }
    });
  });

  // Test the Datify parsing dates in general date format with optional separators correctly
  group('General dates tests', () {
    const dates = {
      '20190301': [2019, 3, 1],
      '20220831': [2022, 8, 31],
      '20201201': [2020, 12, 1],
      '2020-01-20': [2020, 1, 20],
      '2001.12.21': [2001, 12, 21]
    };

    test('general dates are defined correctly', () {
      for (var date in dates.keys) {
        final d = Datify.parse(date);
        expect([d.year, d.month, d.day], dates[date]);
      }
    });
  });

  // Test the Datify parsing all the commonly-used Ukrainian and russian month names forms correctly
  group('Months forms tests', () {
    const ukrainian = [
      'січня',
      'лютого',
      'березня',
      'квітня',
      'травня',
      'червня',
      'липня',
      'серпня',
      'вересня',
      'жовтня',
      'листопада',
      'грудня',
    ];

    const russian = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];

    void testMonthsList(List<String> monthsList, String testName) {
      final random = _random;
      test(testName, () {
        for (var month = 0; month < monthsList.length; month++) {
          final separator = _randomElementOf(DatifyConfig.splitters);
          final dateString = [
            random.nextIntInRange(1, 32),
            monthsList[month],
            random.nextIntInRange(1, 13)
          ].join(separator);

          expect(Datify.parse(dateString).month, month + 1,
              reason:
                  '${monthsList[month]} should be parsed as a ${month + 1} month number');
        }
      });
    }

    // test the Ukrainian month forms
    testMonthsList(ukrainian, 'ukrainian months forms are defined correctly');

    // test the russian month forms
    testMonthsList(russian, 'russian months forms are defined correctly');
  });

  // Test the Datify parsing incomplete dates correctly
  group('Incomplete dates tests', () {
    const dates = {
      '10 of Jan': [10, 1, null],
      'липень 2022': [null, 7, 2022],
      'июнь 2021': [null, 6, 2021],
      '10 2004': [10, null, 2004]
    };
    test('incomplete dates are defined correctly', () {
      for (var entry in dates.entries) {
        final d = Datify.parse(entry.key);

        expect(d.day, entry.value[0]);
        expect(d.month, entry.value[1]);
        expect(d.year, entry.value[2]);
      }
    });

    test('incomplete Datify objects does not allow to get DateTime', () {
      for (var entry in dates.entries) {
        final d = Datify.parse(entry.key);

        expect(d.date, null);
      }
    });
  });

  group('Predefining dates tests', () {
    const dates = {
      '20200101': [3, 12, 2021],
      '20040120': [31, 12, 2003],
      '11th of June 2004': [11, 07, 2004]
    };

    test('predefining dates works correctly', () {
      for (var entry in dates.entries) {
        final day = entry.value[0];
        final month = entry.value[1];
        final year = entry.value[2];
        final d = Datify.parse(entry.key, day: day, month: month, year: year);
        expect(d.day, day);
        expect(d.month, month);
        expect(d.year, year);
      }
    });
  });

  group('Settings tests', () {
    test('adding new separators works correctly', () {
      final sep = '%';
      DatifyConfig.splitters.add(sep);

      final dateString = [10, 07, 2006].join(sep);
      final d = Datify.parse(dateString);
      expect(d.isComplete, true);

      DatifyConfig.splitters.remove(sep);
    });

    test('dayFirst setting works correctly', () {
      DatifyConfig.dayFirst = false;

      final dates =
          List.generate(100, (_) => _randomDate()).map((m) => m.entries.first);

      for (var entry in dates) {
        final d = Datify.parse(entry.key);
        expect(
          d.month,
          // if the first date part is larger than 12, the first date part is considered to be
          // a day even if the dayFirst setting is set to false
          (entry.value.day! <= 12 ? entry.value.day : entry.value.month),
          reason: 'Datify{dayFirst: false}.parse(${entry.key}) was $d',
        );
      }

      const alphanumericDates = {
        'May, 20, 2021': [2021, 5, 20],
        '10 April 2020': [2020, 4, 10],
        '12 2020 march': [2020, 3, 12],
      };

      for (var entry in alphanumericDates.entries) {
        final d = Datify.parse(entry.key);

        expect([d.year, d.month, d.day], entry.value);
      }

      DatifyConfig.dayFirst = true;
    });
  });

  group('Random tests', () {
    const randomTestCount = 100000;
    test('random dates are defined correctly', () {
      for (var i = 0; i < randomTestCount; i++) {
        final data = _randomDate(isAlphanumeric: i > (randomTestCount / 2));
        final dateString = data.keys.first;
        final expected = data.values.first;

        final d = Datify.parse(dateString);
        expect(
          d,
          expected,
          reason: 'Date of $dateString should be equal to $expected',
        );

        final actualDateTime = d.date;
        final dateTime =
            DateTime(expected.year!, expected.month!, expected.day!);
        // random days such as November 31 do not exist
        final expectedDateTime =
            dateTime.month == expected.month ? dateTime : null;
        expect(
          actualDateTime,
          expectedDateTime,
          reason: 'DateTime of $d should be equal to $expectedDateTime',
        );

        expect(
          d.result.date,
          expectedDateTime,
          reason:
              'Result ${d.result}.date should be equal to $expectedDateTime',
        );
      }
    });
  });

  group('Invalid dates tests', () {
    const dates = ['31.02.2021', '30 2 2020', '29.02.2021', '31 April 2022'];

    test('non-existent dates do not produce a DateTime', () {
      for (final date in dates) {
        final d = Datify.parse(date);

        expect(d.isComplete, true, reason: '$date should be fully parsed');
        expect(d.date, null, reason: '$date is not an existing date');
        expect(d.result.date, null, reason: '$date is not an existing date');
      }
    });

    test('leap days produce a DateTime', () {
      expect(Datify.parse('29.02.2020').date, DateTime(2020, 2, 29));
    });
  });

  group('Non-month words tests', () {
    const strings = {
      'Maybe tomorrow': [null, null, null],
      'Mayday': [null, null, null],
      'Junk 2020': [null, null, 2020],
      'Decent 12 2020': [12, null, 2020],
      'Juneteenth': [null, null, null],
      'Marching band': [null, null, null],
      'not a date': [null, null, null],
    };

    test('words starting with a month name are not months', () {
      for (final entry in strings.entries) {
        final d = Datify.parse(entry.key);
        expect([d.day, d.month, d.year], entry.value, reason: entry.key);
      }
    });

    test('abbreviations and punctuated month names are months', () {
      const dates = {
        'Sept 5, 2020': [5, 9, 2020],
        '1 Febr. 2019': [1, 2, 2019],
        '(March) 3 2021': [3, 3, 2021],
        'Monday, 3 January 2022': [3, 1, 2022],
      };

      for (final entry in dates.entries) {
        final d = Datify.parse(entry.key);
        expect([d.day, d.month, d.year], entry.value, reason: entry.key);
      }
    });
  });

  group('ISO 8601 tests', () {
    const dates = {
      '2020-01-01T10:00:00Z': [2020, 1, 1],
      '2021-12-31T23:59:59.999+02:00': [2021, 12, 31],
      '20220704T120000': [2022, 7, 4],
    };

    test('timestamps are parsed as dates', () {
      for (final entry in dates.entries) {
        final d = Datify.parse(entry.key);
        expect([d.year, d.month, d.day], entry.value, reason: entry.key);
      }
    });
  });

  group('Month-first dates tests', () {
    test('unambiguous month-first dates are parsed with dayFirst', () {
      const dates = {
        '12/31/2021': [2021, 12, 31],
        '2 29 2020': [2020, 2, 29],
        '1.13.1999': [1999, 1, 13],
      };

      for (final entry in dates.entries) {
        final d = Datify.parse(entry.key);
        expect([d.year, d.month, d.day], entry.value, reason: entry.key);
      }
    });

    test('ambiguous dates keep the dayFirst order', () {
      final d = Datify.parse('05/06/2021');
      expect([d.day, d.month], [5, 6]);
    });

    test('predefined days are not swapped', () {
      final d = Datify.parse('12/31/2021', day: 5);
      expect([d.year, d.month, d.day], [2021, 12, 5]);
    });
  });

  group('Two-digit years tests', () {
    const dates = {
      '15.03.22': [2022, 3, 15],
      '5 May 99': [1999, 5, 5],
      '1/1/00': [2000, 1, 1],
      '31 Dec 68.': [2068, 12, 31],
      '1 Jan 69': [1969, 1, 1],
    };

    test('two-digit years are expanded', () {
      for (final entry in dates.entries) {
        final d = Datify.parse(entry.key);
        expect([d.year, d.month, d.day], entry.value, reason: entry.key);
      }
    });

    test('two-digit numbers are not years before the day and month', () {
      expect(Datify.parse('15 March at 10:30').year, null);
      expect(Datify.parse('10 2004').year, 2004);
    });
  });

  group('Localization tests', () {
    test('adding new localizations works correctly', () {
      const frenchMonths = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Peut',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];

      expect(
        () => DatifyConfig.addNewMonthsLocale(['1', '2', '3']),
        throwsArgumentError,
        reason: 'Wrong month names length should throw an ArgumentError',
      );

      expect(
        () => DatifyConfig.addNewMonthsLocale(frenchMonths),
        returnsNormally,
        reason: 'Adding months with correct length should execute successfully',
      );
    });

    test('added months are defined correctly', () {
      const dates = {
        '20 septembre 2022': [20, 09, 2022],
        '17 Peut 2020': [17, 05, 2020],
        '2 Avril 2008': [2, 4, 2008],
      };

      for (var entry in dates.entries) {
        final d = Datify.parse(entry.key);
        expect([d.day, d.month, d.year], entry.value);
      }
    });
  });
}

String _randomSplitter() => _randomElementOf(DatifyConfig.splitters);

Map<String, Datify> _randomDate({bool isAlphanumeric = false}) {
  final random = _random;

  // define a random date parts
  final day = random.nextIntInRange(1, 32);
  final month = isAlphanumeric
      ? randomAlphanumericMonth()
      : {random.nextIntInRange(1, 13): ''};
  final year = random.nextIntInRange(1900, 2023);

  // create a date string from the previously generated data joined with the random date part splitter
  // final dateString =
  //     [day, (isAlphanumeric ? month.values.first : month.keys.first), year].join(_randomSplitter());

  // changed the way of date string generation to include random splitters in each string instead of
  // using only one few times
  final dateString =
      '$day${_randomSplitter()}${isAlphanumeric ? month.values.first : month.keys.first}'
      '${_randomSplitter()}$year';

  return {
    dateString: Datify.fromValues(day: day, month: month.keys.first, year: year)
  };
}

Map<int, String> randomAlphanumericMonth() {
  final monthNum = _random.nextIntInRange(1, 13);
  final monthNamesSet = DatifyConfig.months[monthNum - 1];

  return {monthNum: _randomElementOf(monthNamesSet)};
}

T _randomElementOf<T>(Iterable<T> collection) =>
    collection.elementAt(_random.nextInt(collection.length));

extension _RadomRangeInt on Random {
  /// Returns a random number in the range between min (inclusive) and max (exclusive).
  ///
  int nextIntInRange(int min, int max) {
    return min + nextInt(max - min);
  }
}
