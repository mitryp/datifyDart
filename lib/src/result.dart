/// The class used to represent the result of Datify parsing.
///
/// The result is not nullable, but any of the values in the result can be null depending on the
/// parsing context.
///
/// The result can be transformed into a [DateTime] object using the [date] getter if all the values
/// in the result are not null. Otherwise, the date getter will return null.
///
/// The result has the [year], [month], and [day] nullable final fields.
///
/// The result can be transformed into Map<String, int?> with the [toMap] method.
///
class DatifyResult {
  // TODO: decide if we need it or not
  /// The year of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? year;

  /// The month of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? month;

  /// The day of the result.
  /// May be null if the Datify could not parse the respective date part.
  ///
  final int? day;

  /// Creates a new DatifyResult with the specified values.
  ///
  const DatifyResult(
      {required this.year, required this.month, required this.day});

  /// Returns a Map of the values of the DatifyResult.
  ///
  /// The structure of the returned Map is as follows:
  /// ```json
  /// {
  ///   "year": year | null,
  ///   "month": month | null,
  ///   "day": day | null
  /// }
  /// ```
  Map<String, int?> toMap() => {'year': year, 'month': month, 'day': day};

  /// Returns true if all the values of the result are not null.
  ///
  /// If the result is complete, this means that it can be successfully transformed into a
  /// [DateTime] object with the [date] getter.
  ///
  bool get isComplete => year != null && month != null && day != null;

  /// Returns the [DateTime] object with the values of the result.
  /// This works if all the values of the result are not null.
  ///
  /// If the result is incomplete, this getter will return null instead.
  ///
  DateTime? get date => (isComplete ? DateTime(year!, month!, day!) : null);

  @override
  String toString() => 'DatifyResult{year: $year, month: $month, day: $day}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatifyResult &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}
