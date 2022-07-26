import 'package:datify/datify.dart';

/// In the example there should be a 'date' field in the map to represent the searching by a date.
///
typedef SearchRequest = Map<String, String>;

/// Handles the [SearchRequest].
///
/// Returns a corresponding event description or the error message.
///
String handleRequest(SearchRequest searchRequest) {
  final dateQuery = searchRequest['date'];

  // the Datify handles all the parsing inside freeing
  // you from even thinking about it!
  final res = Datify.parse(dateQuery).result;

  // make the search request
  final response =
      Events.query(year: res.year, month: res.month, day: res.day) ??
          'No events found for this query 👀';

  return response;
}

void main() {
  // define dates in the different formats
  const dates = [
    '31.12.2021', // common digit-only date format
    '2022-02-23', // another commonly-used date format
    '23-02/2022', // the supported separators can be combined in the string
    '20 of January', // date is incomplete but still correctly parsed
    'May', // just a month name
    '14 лютого 2022', // Ukrainian date which stands for 14.02.2022
    'not a date', // not a date at all
  ];

  // 'request' all the dates
  for (var date in dates) {
    print('$date: ${handleRequest({'date': date})}');
  }
}

// =============================================================================

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

/// The class that represents a date in the example.
///
/// Has nullable year, month, and day final fields and a method that checks if the date satisfies
/// the query.
///
class Date {
  final int? year;
  final int? month;
  final int? day;

  const Date.empty() : this();

  const Date({this.year, this.month, this.day});

  bool satisfies({int? year, int? month, int? day}) {
    return (year == null || this.year == null || this.year == year) &&
        (month == null || this.month == null || this.month == month) &&
        (day == null || this.day == null || this.day == day);
  }

  bool get empty => year == null && month == null && day == null;
}
