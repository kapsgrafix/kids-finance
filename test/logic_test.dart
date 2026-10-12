import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiny_treasury/models/models.dart';
import 'package:tiny_treasury/state/app_state.dart';
import 'package:tiny_treasury/state/format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('money formatting', () {
    expect(money(1240, 'INR'), '₹1,240');
    expect(money(100000, 'INR'), '₹1,00,000');
    expect(money(1234567, 'USD'), r'$1,234,567');
    expect(money(120, 'INR', signed: true, negative: true), '−₹120');
  });

  test('pocket-money day pays interest, fills the jar and pays it out', () async {
    final s = AppState();
    await s.load();
    final kid = s.addKid(name: 'Aarav', pocketMoney: 500, frequency: Frequency.monthly, currency: 'INR');
    expect(s.balanceOf(kid), 500);

    expect(s.addExpense(kid, 380, Category.food, 'Lunch'), isNull);
    expect(s.balanceOf(kid), 120);
    expect(s.addExpense(kid, 1000, Category.fun, ''), isNotNull); // more than the balance

    final jar = s.createJar(kid, percent: 5, months: 3)!; // ₹25 × 3
    expect(jar.amountPerCycle, 25);
    expect(jar.payout, 78);
    expect(s.nextPocketMoney(kid), 475);

    // First pocket-money day: 10% interest on ₹120, ₹475 pocket money, ₹25 to the jar.
    s.processDueCycles(kid.nextDueAt);
    expect(s.balanceOf(kid), 120 + 12 + 475);
    expect(jar.saved, 25);

    // Two more days: the jar opens on the third.
    s.processDueCycles(kid.nextDueAt);
    s.processDueCycles(kid.nextDueAt);
    expect(jar.status, JarStatus.matured);
    expect(s.activeJars(kid), isEmpty);
  });

  test('jars share a 10% cap', () async {
    final s = AppState();
    await s.load();
    final kid = s.addKid(name: 'Kabir', pocketMoney: 1000, frequency: Frequency.monthly, currency: 'INR');
    expect(s.createJar(kid, percent: 6, months: 3), isNotNull);
    expect(s.availableJarPercent(kid), 4);
    expect(s.createJar(kid, percent: 5, months: 6), isNull);
    expect(s.createJar(kid, percent: 4, months: 6), isNotNull);
    expect(s.canStartJar(kid), isFalse);
  });

  test('review schedule moves the next pocket-money day', () async {
    final s = AppState();
    await s.load();
    final kid = s.addKid(name: 'Riya', pocketMoney: 300, frequency: Frequency.weekly, currency: 'INR');
    s.setReviewSchedule(kid, payDay: DateTime.sunday, hour: 10, minute: 30);
    expect(kid.nextPayDate.weekday, DateTime.sunday);
    expect(kid.nextDueAt.hour, 10);
  });

  test('settling a jar returns savings without the bonus', () async {
    final s = AppState();
    await s.load();
    final kid = s.addKid(name: 'Riya', pocketMoney: 200, frequency: Frequency.weekly, currency: 'INR');
    final jar = s.createJar(kid, percent: 10, months: 3)!;
    s.processDueCycles(kid.nextDueAt);
    final before = s.balanceOf(kid);
    s.settleJar(jar);
    expect(s.balanceOf(kid), before + 20);
    expect(jar.status, JarStatus.cancelled);
  });
}
