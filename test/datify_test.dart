import 'dart:math';

import 'package:datify/datify.dart';
import 'package:test/test.dart';

// seeded to make failures of the random tests reproducible
final _random = Random(20260928);

const _datify = Datify();
const _lenient = Datify(DatifyConfig(lenient: true));
const _monthFirst = Datify(DatifyConfig(dayFirst: false));

/// Expects [datify] to find the given date parts in each input.
void _expectParts(Map<String, List<int?>> dates, {Datify datify = _datify}) {
  for (final MapEntry(key: input, value: parts) in dates.entries) {
    final result = datify.parse(input);
    expect([result?.year, result?.month, result?.day], parts, reason: input);
  }
}

void main() {
  group('Numeric dates', () {
    test('day-first dates with different separators', () {
      _expectParts({
        '31.12.2021': [2021, 12, 31],
        '20/01/2022': [2022, 1, 20],
        '14 02 2022': [2022, 2, 14],
        '9-1-2005': [2005, 1, 9],
        '31. 12. 2003': [2003, 12, 31],
        '31.\n  12\n  .2003': [2003, 12, 31],
      });
    });

    test('year-first dates', () {
      _expectParts({
        '20190301': [2019, 3, 1],
        '2020-01-20': [2020, 1, 20],
        '2001.12.21': [2001, 12, 21],
        '2020/4/5': [2020, 4, 5],
      });
    });

    test('ISO 8601 timestamps', () {
      _expectParts({
        '2020-01-01T10:00:00Z': [2020, 1, 1],
        '2021-12-31T23:59:59.999+02:00': [2021, 12, 31],
        '20220704T120000': [2022, 7, 4],
      });
    });

    test('unambiguous month-first dates are detected with dayFirst', () {
      _expectParts({
        '12/31/2021': [2021, 12, 31],
        '2 29 2020': [2020, 2, 29],
        '1.13.1999': [1999, 1, 13],
      });
    });

    test('ambiguous dates follow dayFirst and are marked', () {
      expect(_datify.parse('05/06/2021'),
          _result(2021, 6, 5, 0, 10, isAmbiguous: true));
      expect(_monthFirst.parse('05/06/2021'),
          _result(2021, 5, 6, 0, 10, isAmbiguous: true));
      expect(_monthFirst.parse('13/06/2021')?.isAmbiguous, false);
      expect(_datify.parse('06/06/2021')?.isAmbiguous, false);
    });

    test('two-digit years', () {
      _expectParts({
        '15.03.22': [2022, 3, 15],
        '1/1/00': [2000, 1, 1],
        '31.12.68': [2068, 12, 31],
        '1.1.69': [1969, 1, 1],
      });
    });

    test('numbers that are not dates', () {
      for (final input in [
        '10 2004',
        '13/13/2021',
        '32.01.2021',
        '1.2.3',
        '192.168.1.10',
        '10.07.2006.1',
        'abc10.07.2006',
        '12:30:45',
      ]) {
        expect(_datify.parse(input), null, reason: input);
      }
    });
  });

  group('Dates with month names', () {
    test('day before the month', () {
      _expectParts({
        '10 мая 2022': [2022, 5, 10],
        '20th of January, 2021': [2021, 1, 20],
        '14 лютого 2022': [2022, 2, 14],
        '3 of may 2018': [2018, 5, 3],
        '1 Febr. 2019': [2019, 2, 1],
        '5 May 99': [1999, 5, 5],
        '31 Dec 68.': [2068, 12, 31],
        '05-Mar-2021': [2021, 3, 5],
      });
    });

    test('month before the day', () {
      _expectParts({
        'Sept 5, 2020': [2020, 9, 5],
        'May, 20, 2021': [2021, 5, 20],
        'January 1st 2022': [2022, 1, 1],
        '2021-Mar-05': [2021, 3, 5],
        '2021 March 5': [2021, 3, 5],
      });
    });

    test('partial dates', () {
      _expectParts({
        '10 of Jan': [null, 1, 10],
        'May 5': [null, 5, 5],
        'липень 2022': [2022, 7, null],
        'июнь 2021': [2021, 6, null],
        '15 March at 10:30': [null, 3, 15],
      });
    });

    test('built-in languages', () {
      _expectParts({
        '5. Mai 2020': [2020, 5, 5],
        '3. März 2021': [2021, 3, 3],
        '1er janvier 2021': [2021, 1, 1],
        '14 juillet 1789': [1789, 7, 14],
        '5 de mayo de 2020': [2020, 5, 5],
        '1º de mayo': [null, 5, 1],
        '1 stycznia 2021': [2021, 1, 1],
        '11 listopada 1918': [1918, 11, 11],
      });
    });

    test('every built-in month name is its own month', () {
      for (final locale in DatifyLocale.builtIn) {
        for (var month = 1; month <= 12; month++) {
          for (final name in locale.months[month - 1]) {
            expect(_datify.parse('3 $name 2020')?.month, month, reason: name);
          }
        }
      }
    });

    test('Ukrainian and Russian abbreviations', () {
      const abbreviations = [
        'січ', 'лют', 'бер', 'кві', 'тра', 'чер', //
        'лип', 'сер', 'вер', 'жов', 'лис', 'гру',
      ];

      for (var month = 1; month <= 12; month++) {
        final abbreviation = abbreviations[month - 1];
        expect(_datify.parse('3 $abbreviation 2026')?.date,
            DateTime(2026, month, 3),
            reason: abbreviation);
      }

      expect(_datify.parse('3 січ. 2026')?.date, DateTime(2026, 1, 3));
      expect(_datify.parse('3 янв 2026')?.date, DateTime(2026, 1, 3));
      expect(_datify.parse('3 сі 2026'), null);
    });

    test('words that only look like month names', () {
      for (final input in [
        'Maybe tomorrow',
        'Mayday',
        'Junk 2020',
        'Decent 12 2020',
        'Juneteenth',
        'Marching band',
        'May I help you?',
        'not a date',
      ]) {
        expect(_datify.parse(input), null, reason: input);
      }
    });
  });

  group('Dates in text', () {
    test('the position of the date is reported', () {
      const text = 'Monday, 3 January 2022';
      final result = _datify.parse(text)!;

      expect(result, _result(2022, 1, 3, 8, 22));
      expect(text.substring(result.start, result.end), '3 January 2022');
    });

    test('unrelated numbers are not taken for date parts', () {
      _expectParts({
        'Room 12, meeting on 5 May 2020': [2020, 5, 5],
        'Order #15 shipped 03.04.2021': [2021, 4, 3],
        'Call 555 1234 on 1 June': [null, 6, 1],
      });
    });

    test('parseAll finds every date', () {
      expect(
        _datify.parseAll('from 1.02.2021 to 2021-03-15, then March 2022'),
        [
          _result(2021, 2, 1, 5, 14, isAmbiguous: true),
          _result(2021, 3, 15, 18, 28),
          _result(2022, 3, null, 35, 45),
        ],
      );
      expect(_datify.parseAll('no dates here'), isEmpty);
    });
  });

  group('Non-existent dates', () {
    test('are parsed, but do not produce a DateTime', () {
      for (final input in [
        '31.02.2021',
        '30 2 2020',
        '29.02.2021',
        '31 April 2022'
      ]) {
        final result = _datify.parse(input);

        expect(result?.isComplete, true, reason: input);
        expect(result?.date, null, reason: input);
      }
    });

    test('leap days produce a DateTime', () {
      expect(_datify.parse('29.02.2020')?.date, DateTime(2020, 2, 29));
    });
  });

  group('Config', () {
    test('custom separators', () {
      expect(_datify.parse('10%07%2006'), null);

      const datify = Datify(DatifyConfig(separators: {'%'}));
      expect(datify.parse('10%07%2006')?.date, DateTime(2006, 7, 10));
      expect(datify.parse('10.07.2006'), null);
      expect(datify.parse('10 07 2006')?.date, DateTime(2006, 7, 10));
    });

    test('invalid separators are rejected', () {
      for (final separator in ['', '--', 'a', '1', ' ']) {
        final datify = Datify(DatifyConfig(separators: {separator}));
        expect(() => datify.parse('10.07.2006'), throwsArgumentError,
            reason: "'$separator'");
      }
    });

    test('dayFirst: false', () {
      _expectParts(datify: _monthFirst, {
        '05/06/2021': [2021, 5, 6],
        '13/06/2021': [2021, 6, 13],
        'May, 20, 2021': [2021, 5, 20],
        '10 April 2020': [2020, 4, 10],
      });
    });

    test('custom locales', () {
      const italian = DatifyLocale(
        months: [
          ['gennaio'], ['febbraio'], ['marzo'], ['aprile'], //
          ['maggio'], ['giugno'], ['luglio'], ['agosto'],
          ['settembre'], ['ottobre'], ['novembre'], ['dicembre'],
        ],
        connectors: ['di'],
      );

      expect(_datify.parse('14 luglio 2021'), null);

      const datify =
          Datify(DatifyConfig(locales: [...DatifyLocale.builtIn, italian]));
      expect(datify.parse('14 luglio 2021')?.date, DateTime(2021, 7, 14));
      expect(datify.parse('14 di luglio')?.month, 7);
      expect(datify.parse('14 July 2021')?.month, 7);
    });

    test('only the chosen locales are used', () {
      const datify = Datify(DatifyConfig(locales: [DatifyLocale.en]));
      expect(datify.parse('14 July 2021')?.month, 7);
      expect(datify.parse('14 липня 2021'), null);
    });

    test('a locale without 12 months is rejected', () {
      const datify = Datify(DatifyConfig(locales: [
        DatifyLocale(months: [
          ['one'],
          ['two'],
        ]),
      ]));

      expect(() => datify.parse('1 one 2020'), throwsArgumentError);
    });
  });

  group('Lenient parsing', () {
    test('picks date parts in any order', () {
      _expectParts(datify: _lenient, {
        '12 2020 march': [2020, 3, 12],
        '(March) 3 2021': [2021, 3, 3],
        '10 2004': [2004, null, 10],
        'Decent 12 2020': [2020, null, 12],
      });
    });

    test('is only used when no date is recognized', () {
      expect(_lenient.parse('Room 12, meeting on 5 May 2020'),
          _result(2020, 5, 5, 20, 30));
    });

    test('reports the span of the parts', () {
      const text = 'on 12, 2020 in march';
      final result = _lenient.parse(text)!;

      expect(text.substring(result.start, result.end), '12, 2020 in march');
    });

    test('finds nothing in text without date parts', () {
      expect(_lenient.parse('Maybe tomorrow'), null);
      expect(_lenient.parseAll('Maybe tomorrow'), isEmpty);
    });

    test('month-first order', () {
      const datify = Datify(DatifyConfig(dayFirst: false, lenient: true));
      _expectParts(datify: datify, {
        '12 2020 march': [2020, 3, 12],
        '5 2020 7': [2020, 5, 7],
      });
    });
  });

  group('Random dates', () {
    const count = 100000;
    final separators = [' ', ...const DatifyConfig().separators];
    final monthNames = [
      for (var month = 1; month <= 12; month++)
        [
          for (final locale in DatifyLocale.builtIn) ...locale.months[month - 1]
        ],
    ];

    T randomOf<T>(List<T> list) => list[_random.nextInt(list.length)];

    test('are parsed correctly', () {
      for (var i = 0; i < count; i++) {
        final day = 1 + _random.nextInt(31);
        final month = 1 + _random.nextInt(12);
        final year = 1900 + _random.nextInt(200);
        final monthText = i.isEven ? '$month' : randomOf(monthNames[month - 1]);

        final input =
            '$day${randomOf(separators)}$monthText${randomOf(separators)}$year';
        final result = _datify.parse(input);

        expect([result?.year, result?.month, result?.day], [year, month, day],
            reason: input);

        final date = DateTime(year, month, day);
        expect(result?.date, date.month == month ? date : null, reason: input);
      }
    });
  });
}

DatifyResult _result(
  int? year,
  int? month,
  int? day,
  int start,
  int end, {
  bool isAmbiguous = false,
}) =>
    DatifyResult(
      year: year,
      month: month,
      day: day,
      start: start,
      end: end,
      isAmbiguous: isAmbiguous,
    );
