import 'package:meta/meta.dart';


enum BclCalendarType {
  unknown,
  gregorian,
  persian,
  hijri,
  umAlQura
}

@immutable
class DateTimeFormatInfo {
  final String amDesignator;
  final String pmDesignator;

  final String timeSeparator;
  final String dateSeparator;

  final List<String> abbreviatedDayNames;
  final List<String> dayNames;
  final List<String> monthNames;
  final List<String> abbreviatedMonthNames;
  final List<String> monthGenitiveNames;
  final List<String> abbreviatedMonthGenitiveNames;

  // BCL Calendar Class
  final BclCalendarType calendar;

  final List<String> eraNames;
  String getEraName(int era) {
    if (era == 0) throw new UnimplementedError('Calendar.CurrentEraValue not implemented.');
    if (--era < this.eraNames.length && era >= 0) return eraNames[era];
    throw new ArgumentError.value(era, 'era');
  }

  final String fullDateTimePattern;
  final String shortDatePattern;
  final String longDatePattern;
  final String shortTimePattern;
  final String longTimePattern;

  // Month's have a blank entry at the end
  static final List<String> invariantMonthNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''];
  static final List<String> invariantAbbreviatedMonthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', ''];

  DateTimeFormatInfo.invariantCulture()
      : amDesignator = 'AM',
        pmDesignator = 'PM',
        timeSeparator = ':',
        dateSeparator = '/',
        abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        monthNames = invariantMonthNames,
        abbreviatedMonthNames = invariantAbbreviatedMonthNames,
        monthGenitiveNames = invariantMonthNames,
        abbreviatedMonthGenitiveNames = invariantAbbreviatedMonthNames,
        calendar = BclCalendarType.gregorian,
        eraNames = const ['A.D.'],
        fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss',
        shortDatePattern = 'MM/dd/yyyy',
        longDatePattern = 'dddd, dd MMMM yyyy',
        shortTimePattern = 'HH:mm',
        longTimePattern = 'HH:mm:ss'
  ;

  DateTimeFormatInfo(
      this.amDesignator,
      this.pmDesignator,
      this.timeSeparator,
      this.dateSeparator,
      this.abbreviatedDayNames,
      this.dayNames,
      this.monthNames,
      this.abbreviatedMonthNames,
      this.monthGenitiveNames,
      this.abbreviatedMonthGenitiveNames,
      this.calendar,
      this.eraNames,
      this.fullDateTimePattern,
      this.shortDatePattern,
      this.longDatePattern,
      this.shortTimePattern,
      this.longTimePattern
      );
}

class DateTimeFormatInfoBuilder {
  String amDesignator;
  String pmDesignator;

  String timeSeparator;
  String dateSeparator;

  List<String> abbreviatedDayNames;
  List<String> dayNames;
  List<String> monthNames;
  List<String> abbreviatedMonthNames;
  List<String> monthGenitiveNames;
  List<String> abbreviatedMonthGenitiveNames;

  // BCL Calendar Class
  BclCalendarType calendar;

  List<String> eraNames;

  String fullDateTimePattern;
  String shortDatePattern;
  String longDatePattern;
  String shortTimePattern;
  String longTimePattern;

  DateTimeFormatInfo Build() =>
      new DateTimeFormatInfo(
          amDesignator,
          pmDesignator,
          timeSeparator,
          dateSeparator,
          abbreviatedDayNames,
          dayNames,
          monthNames,
          abbreviatedMonthNames,
          monthGenitiveNames,
          abbreviatedMonthGenitiveNames,
          calendar,
          eraNames,
          fullDateTimePattern,
          shortDatePattern,
          longDatePattern,
          shortTimePattern,
          longTimePattern);

  DateTimeFormatInfoBuilder();
}