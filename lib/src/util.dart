/// Trims and lowercase the given string.
///
String normalize(String str) => str.trim().toLowerCase();

/// Returns a [DateTime] of the given parts, or null if any part is missing or the parts do not form
/// an existing date (e.g. February 31).
///
DateTime? dateFromParts(int? year, int? month, int? day) {
  if (year == null || month == null || day == null) {
    return null;
  }

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }

  return date;
}

/// Expands a two-digit year: 00–68 become 2000–2068, 69–99 become 1969–1999.
///
int expandTwoDigitYear(int year) => year < 69 ? 2000 + year : 1900 + year;
