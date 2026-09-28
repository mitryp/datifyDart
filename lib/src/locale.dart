/// The words of a language that Datify uses to recognize dates.
///
/// A custom language can be added alongside the built-in ones:
/// ```dart
/// const italian = DatifyLocale(months: [
///   ['gennaio'], ['febbraio'], ['marzo'], ['aprile'], ['maggio'], ['giugno'],
///   ['luglio'], ['agosto'], ['settembre'], ['ottobre'], ['novembre'], ['dicembre'],
/// ], connectors: ['di']);
///
/// const datify = Datify(DatifyConfig(locales: [...DatifyLocale.builtIn, italian]));
/// ```
///
final class DatifyLocale {
  /// The names of each month, starting with January.
  ///
  /// Must contain exactly 12 lists. Abbreviations that a name starts with, such as `sept`, and forms
  /// that differ from a name only in a short ending, such as `januari`, are recognized without being
  /// listed. Other forms, like the genitive `січня` for `січень`, must be listed.
  ///
  final List<List<String>> months;

  /// The endings written directly after a day number, such as `th` in `20th`.
  ///
  final List<String> ordinalSuffixes;

  /// The words that may connect the date parts, such as `of` in `20th of January`.
  ///
  final List<String> connectors;

  const DatifyLocale({
    required this.months,
    this.ordinalSuffixes = const [],
    this.connectors = const [],
  });

  static const en = DatifyLocale(
    months: [
      ['january', 'jan'],
      ['february', 'feb'],
      ['march', 'mar'],
      ['april', 'apr'],
      ['may'],
      ['june', 'jun'],
      ['july', 'jul'],
      ['august', 'aug'],
      ['september', 'sep'],
      ['october', 'oct'],
      ['november', 'nov'],
      ['december', 'dec'],
    ],
    ordinalSuffixes: ['st', 'nd', 'rd', 'th'],
    connectors: ['of'],
  );

  static const uk = DatifyLocale(months: [
    ['січень', 'січня'],
    ['лютий', 'лютого'],
    ['березень', 'березня'],
    ['квітень', 'квітня'],
    ['травень', 'травня'],
    ['червень', 'червня'],
    ['липень', 'липня'],
    ['серпень', 'серпня'],
    ['вересень', 'вересня'],
    ['жовтень', 'жовтня'],
    ['листопад', 'листопада'],
    ['грудень', 'грудня'],
  ]);

  static const ru = DatifyLocale(months: [
    ['январь', 'января'],
    ['февраль', 'февраля'],
    ['март', 'марта'],
    ['апрель', 'апреля'],
    ['май', 'мая'],
    ['июнь', 'июня'],
    ['июль', 'июля'],
    ['август', 'августа'],
    ['сентябрь', 'сентября'],
    ['октябрь', 'октября'],
    ['ноябрь', 'ноября'],
    ['декабрь', 'декабря'],
  ]);

  static const de = DatifyLocale(months: [
    ['januar', 'jänner'],
    ['februar'],
    ['märz', 'mrz'],
    ['april'],
    ['mai'],
    ['juni'],
    ['juli'],
    ['august'],
    ['september'],
    ['oktober'],
    ['november'],
    ['dezember'],
  ]);

  static const fr = DatifyLocale(
    months: [
      ['janvier'],
      ['février', 'fevrier'],
      ['mars'],
      ['avril'],
      ['mai'],
      ['juin'],
      ['juillet'],
      ['août', 'aout'],
      ['septembre'],
      ['octobre'],
      ['novembre'],
      ['décembre', 'decembre'],
    ],
    ordinalSuffixes: ['er'],
  );

  static const es = DatifyLocale(
    months: [
      ['enero'],
      ['febrero'],
      ['marzo'],
      ['abril'],
      ['mayo'],
      ['junio'],
      ['julio'],
      ['agosto'],
      ['septiembre', 'setiembre'],
      ['octubre'],
      ['noviembre'],
      ['diciembre'],
    ],
    ordinalSuffixes: ['º'],
    connectors: ['de', 'del'],
  );

  static const pl = DatifyLocale(months: [
    ['styczeń', 'stycznia'],
    ['luty', 'lutego'],
    ['marzec', 'marca'],
    ['kwiecień', 'kwietnia'],
    ['maj', 'maja'],
    ['czerwiec', 'czerwca'],
    ['lipiec', 'lipca'],
    ['sierpień', 'sierpnia'],
    ['wrzesień', 'września'],
    ['październik', 'października'],
    ['listopad', 'listopada'],
    ['grudzień', 'grudnia'],
  ]);

  /// English, Ukrainian, Russian, German, French, Spanish, and Polish.
  ///
  static const builtIn = [en, uk, ru, de, fr, es, pl];
}
