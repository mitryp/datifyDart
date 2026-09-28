import 'package:datify/datify.dart';

void main() {
  const inputs = [
    '31.12.2021',
    '2022-02-23T10:00:00Z',
    '20th of January, 2021',
    'Sept 5, 2020',
    '14 лютого 2022',
    '3 січ 26',
    '12/31/2021',
    'The meeting on 15 March 2022 at 10:30',
    '20 of January', // incomplete
    '31.02.2021', // does not exist
    'Maybe tomorrow', // not a date
  ];

  for (final input in inputs) {
    print('$input → ${describe(Datify.parse(input))}');
  }

  // read ambiguous dates in the US order
  DatifyConfig.dayFirst = false;
  print('05/06/2021 → ${describe(Datify.parse('05/06/2021'))}');
  DatifyConfig.dayFirst = true;

  // add month names in another language
  DatifyConfig.addNewMonthsLocale([
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ]);
  print('14 juillet 2021 → ${describe(Datify.parse('14 juillet 2021'))}');
}

String describe(Datify datify) {
  final date = datify.date;
  if (date != null) {
    return date.toIso8601String().substring(0, 10);
  }

  if (datify.isComplete) {
    return 'not an existing date';
  }

  final parts = {
    'year': datify.year,
    'month': datify.month,
    'day': datify.day,
  }.entries.where((part) => part.value != null);

  return parts.isEmpty
      ? 'no date found'
      : parts.map((part) => '${part.key} ${part.value}').join(', ');
}
