// Measures the median time per Datify.parse call for different kinds of input.
//
// For numbers representative of release builds, compile AOT:
//   dart compile exe benchmark/parse_benchmark.dart -o parse_benchmark && ./parse_benchmark

import 'package:datify/datify.dart';

const _cases = {
  'Digits (DD.MM.YYYY)': ['31.12.2021', '20/01/2022', '14 02 2022', '9-1-2005'],
  'General (YYYY-MM-DD)': [
    '2022-02-23',
    '20190301',
    '2001.12.21',
    '2020/04/15'
  ],
  'English month names': [
    '20th of January, 2021',
    '3 of May 2018',
    '11 July 2020',
    '1 Dec 1999',
  ],
  'Ukrainian/Russian names': [
    '14 лютого 2022',
    '10 мая 2022',
    '6 липня 2021',
    '31 декабря 2021',
  ],
  'Not a date': ['not a date', 'hello world', 'foo bar baz', 'nothing here'],
};

const _monthFirstCase = [
  '12.31.2021',
  '02 22 2020',
  '1.9/2005',
  '10 April 2020',
];

const _warmup = 20000;
const _iterations = 200000;
const _rounds = 7;

double _medianMicrosPerParse(List<String> inputs) {
  for (var i = 0; i < _warmup; i++) {
    Datify.parse(inputs[i % inputs.length]);
  }

  final times = <double>[];
  for (var round = 0; round < _rounds; round++) {
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < _iterations; i++) {
      Datify.parse(inputs[i % inputs.length]);
    }
    times.add(stopwatch.elapsedMicroseconds / _iterations);
  }

  times.sort();
  return times[_rounds ~/ 2];
}

void _report(String name, List<String> inputs) {
  final micros = _medianMicrosPerParse(inputs).toStringAsFixed(2);
  print('${name.padRight(26)} $micros µs');
}

void main() {
  for (final entry in _cases.entries) {
    _report(entry.key, entry.value);
  }

  DatifyConfig.dayFirst = false;
  _report('Digits, dayFirst: false', _monthFirstCase);
}
