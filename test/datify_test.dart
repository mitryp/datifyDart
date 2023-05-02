import 'dart:math';

import 'package:datify/datify.dart';
import 'package:test/test.dart';

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
      final random = Random();
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
        final expectedDateTime =
            DateTime(expected.year!, expected.month!, expected.day!);
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
  final random = Random();

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
  final monthNum = Random().nextIntInRange(1, 13);
  final monthNamesSet = DatifyConfig.months[monthNum - 1];

  return {monthNum: _randomElementOf(monthNamesSet)};
}

T _randomElementOf<T>(Iterable<T> collection) {
  final random = Random();
  return collection.elementAt(random.nextInt(collection.length));
}

extension _RadomRangeInt on Random {
  /// Returns a random number in the range between min (inclusive) and max (exclusive).
  ///
  int nextIntInRange(int min, int max) {
    return min + nextInt(max - min);
  }
}
