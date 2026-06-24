import 'package:pedometer/common/config/resource_loader.dart';

bool get isZhLocale => ResourceLoader.languageCode == 'zh';

String lt(String en, String zh) => isZhLocale ? zh : en;

String shortMonthName(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[(month - 1).clamp(0, names.length - 1)];
}

String localizedShortDate(DateTime date) {
  if (isZhLocale) return '${date.month}月${date.day}日';
  return '${shortMonthName(date.month)} ${date.day}';
}

String localizedDayTitle(DateTime date) {
  if (isZhLocale) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}月${date.day}日 ${labels[date.weekday - 1]}';
  }
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${shortMonthName(date.month)} ${date.day} ${labels[date.weekday - 1]}';
}

String localizedMonthTitle(DateTime date) {
  if (isZhLocale) return '${date.year}年${date.month}月';
  return '${shortMonthName(date.month)} ${date.year}';
}
