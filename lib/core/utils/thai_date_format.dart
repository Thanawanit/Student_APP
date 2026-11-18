/// Formatting helpers for school-local (Asia/Bangkok) dates, times, and masked IDs.
abstract final class ThaiFormat {
  static const List<String> _weekdays = <String>[
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  static const List<String> _monthsFull = <String>[
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  static const List<String> _monthsShort = <String>[
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  /// Converts a DateTime to UTC+7 (Asia/Bangkok) wall-clock representation
  /// without mutating date-only values.
  static DateTime toBangkok(DateTime dateTime) {
    if (!dateTime.isUtc) {
      return dateTime;
    }
    return dateTime.add(const Duration(hours: 7));
  }

  /// Example: `วันจันทร์ที่ 16 พฤศจิกายน 2569`
  static String fullDate(DateTime date) {
    final d = toBangkok(date);
    final weekday = _weekdays[d.weekday - 1];
    final month = _monthsFull[d.month - 1];
    final buddhistYear = d.year + 543;
    return 'วัน$weekdayที่ ${d.day} $month $buddhistYear';
  }

  /// Example: `16 พ.ย. 2569`
  static String shortDate(DateTime date) {
    final d = toBangkok(date);
    final month = _monthsShort[d.month - 1];
    final buddhistYear = d.year + 543;
    return '${d.day} $month $buddhistYear';
  }

  /// Example: `16 พ.ย. 69`
  static String shortDateTwoDigitYear(DateTime date) {
    final d = toBangkok(date);
    final month = _monthsShort[d.month - 1];
    final buddhistYearShort = (d.year + 543) % 100;
    return '${d.day} $month ${buddhistYearShort.toString().padLeft(2, '0')}';
  }

  /// Example: `พ.ย. 2569`
  static String monthYearShort(DateTime date) {
    final d = toBangkok(date);
    final month = _monthsShort[d.month - 1];
    final buddhistYear = d.year + 543;
    return '$month $buddhistYear';
  }

  /// Example: `พ.ย. 69`
  static String monthYearTwoDigit(DateTime date) {
    final d = toBangkok(date);
    final month = _monthsShort[d.month - 1];
    final buddhistYearShort = (d.year + 543) % 100;
    return '$month ${buddhistYearShort.toString().padLeft(2, '0')}';
  }

  /// Example: `วันจันทร์ที่ 16 พ.ย. 2569`
  static String weekdayShortDate(DateTime date) {
    final d = toBangkok(date);
    final weekday = _weekdays[d.weekday - 1];
    final month = _monthsShort[d.month - 1];
    final buddhistYear = d.year + 543;
    return 'วัน$weekdayที่ ${d.day} $month $buddhistYear';
  }

  /// Example: `พ.ย.`
  static String shortMonth(DateTime date) =>
      _monthsShort[toBangkok(date).month - 1];

  /// Example: `วันจันทร์ • 2569`
  static String weekdayAndYear(DateTime date) {
    final d = toBangkok(date);
    return 'วัน${_weekdays[d.weekday - 1]} • ${d.year + 543}';
  }

  /// Example: `16–20 พ.ย. 2569`
  static String schoolWeekRange(DateTime anchorDate) {
    final d = toBangkok(anchorDate);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    final budYear = friday.year + 543;
    if (monday.month == friday.month) {
      return '${monday.day}–${friday.day} ${_monthsShort[friday.month - 1]} $budYear';
    }
    return '${monday.day} ${_monthsShort[monday.month - 1]} – ${friday.day} ${_monthsShort[friday.month - 1]} $budYear';
  }

  /// Example: `07:42 น.`
  static String time24(DateTime dateTime) {
    final d = toBangkok(dateTime);
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  /// Example: `07:42\u00A0น.` (non-breaking space before น.)
  static String time24Nbsp(DateTime dateTime) {
    final d = toBangkok(dateTime);
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute\u00A0น.';
  }

  /// Masks student ID to minimize exposure in parent and summary views.
  static String maskStudentId(String studentId) {
    final trimmed = studentId.trim();
    if (trimmed.length <= 3) {
      return trimmed;
    }
    final visibleSuffix = trimmed.substring(trimmed.length - 3);
    return '•••$visibleSuffix';
  }
}
