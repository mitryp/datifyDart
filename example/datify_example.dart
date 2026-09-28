import 'package:datify/datify.dart';

void main() {
  const datify = Datify();

  const inputs = [
    '31.12.2021',
    '2022-02-23T10:00:00Z',
    '20th of January, 2021',
    'Sept 5, 2020',
    '14 лютого 2022',
    '3 січ 26',
    '5. Mai 2020',
    '12/31/2021',
    '05/06/2021', // ambiguous
    'Room 12, meeting on 15 March 2022 at 10:30',
    'January 2021', // incomplete
    '31.02.2021', // does not exist
    'Maybe tomorrow', // not a date
  ];

  for (final input in inputs) {
    print('$input → ${describe(datify.parse(input))}');
  }

  // read ambiguous dates in the US order
  const us = Datify(DatifyConfig(dayFirst: false));
  print('05/06/2021 (US) → ${describe(us.parse('05/06/2021'))}');

  // find all dates in a text
  const text = 'Booked on 2021-03-01 for 14 May 2021, paid 10.04.2021';
  for (final result in datify.parseAll(text)) {
    print(
        '"${text.substring(result.start, result.end)}" → ${describe(result)}');
  }

  // add month names in another language
  const italian = DatifyLocale(months: [
    ['gennaio'], ['febbraio'], ['marzo'], ['aprile'], //
    ['maggio'], ['giugno'], ['luglio'], ['agosto'], //
    ['settembre'], ['ottobre'], ['novembre'], ['dicembre'],
  ]);
  const withItalian =
      Datify(DatifyConfig(locales: [...DatifyLocale.builtIn, italian]));
  print('14 luglio 2021 → ${describe(withItalian.parse('14 luglio 2021'))}');
}

String describe(DatifyResult? result) {
  if (result == null) {
    return 'no date found';
  }

  final date = result.date;
  if (date != null) {
    final text = date.toIso8601String().substring(0, 10);
    return result.isAmbiguous ? '$text (ambiguous)' : text;
  }

  if (result.isComplete) {
    return 'not an existing date';
  }

  final parts = {
    'year': result.year,
    'month': result.month,
    'day': result.day,
  }.entries.where((part) => part.value != null);

  return parts.map((part) => '${part.key} ${part.value}').join(', ');
}
