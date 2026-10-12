import '../models/models.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The pocket-money day after [d] (which is itself a pocket-money day).
DateTime nextCycle(DateTime d, Frequency f, int payDay) => f == Frequency.monthly
    ? DateTime(d.year, d.month + 1, payDay.clamp(1, 28).toInt())
    : dateOnly(d).add(const Duration(days: 7));

/// First pocket-money day strictly after [now]'s date.
DateTime firstPayDateAfter(DateTime now, Frequency f, int payDay) {
  final today = dateOnly(now);
  if (f == Frequency.monthly) {
    final day = payDay.clamp(1, 28).toInt();
    final thisMonth = DateTime(today.year, today.month, day);
    return thisMonth.isAfter(today) ? thisMonth : DateTime(today.year, today.month + 1, day);
  }
  var ahead = (payDay - today.weekday) % 7;
  if (ahead == 0) ahead = 7;
  return today.add(Duration(days: ahead));
}

String ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
}

String clock(int hour, int minute) => timeOfDay(DateTime(2000, 1, 1, hour, minute));

String weekdayOf(int weekday) => _weekdays[(weekday - 1) % 7];

/// "1st of every month · 6:00 PM" / "Every Saturday · 6:00 PM"
String scheduleLabel(Frequency f, int payDay, int hour, int minute, {bool short = false}) {
  final day = f == Frequency.monthly
      ? (short ? '${ordinal(payDay)} of month' : '${ordinal(payDay)} of every month')
      : (short ? '${weekdayOf(payDay)}s' : 'Every ${weekdayOf(payDay)}');
  return '$day · ${clock(hour, minute)}';
}

int cyclesForMonths(int months, Frequency f) => f == Frequency.monthly ? months : months * 4;

String cycleWord(Frequency f) => f == Frequency.monthly ? 'month' : 'week';

/// 1,240 · Indian grouping for INR (1,00,000), western grouping otherwise.
String groupDigits(int n, {bool indian = false}) {
  final s = n.abs().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  final size = indian ? 2 : 3;
  while (rest.length > size) {
    parts.insert(0, rest.substring(rest.length - size));
    rest = rest.substring(0, rest.length - size);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// Formats money: money(1240, 'INR') → ₹1,240; with [signed] → +₹200 / −₹120.
String money(int amount, String currencyCode, {bool signed = false, bool negative = false}) {
  final c = Currency.of(currencyCode);
  final body = '${c.symbol}${groupDigits(amount, indian: c.code == 'INR')}';
  if (!signed) return amount < 0 ? '−$body' : body;
  return negative ? '−$body' : '+$body';
}

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String longDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String monthName(int m) => _monthsLong[m - 1];
String monthYear(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';
String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

String timeOfDay(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String dayLabel(DateTime d, DateTime now) {
  final a = dateOnly(d), b = dateOnly(now);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return a.year == b.year ? shortDate(a) : longDate(a);
}

String ago(DateTime d, DateTime now) {
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return shortDate(d);
}
