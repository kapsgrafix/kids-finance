import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'format.dart';

/// Single source of truth for the app. Everything is stored locally on the device.
class AppState extends ChangeNotifier {
  static const _storageKey = 'tiny_treasury_state_v1';

  /// Kids can put 2–10% of their pocket money into jars (all jars together).
  static const minJarPct = 2;
  static const maxJarPct = 10;

  final List<Kid> kids = [];
  final List<Entry> entries = [];
  final List<Jar> jars = [];
  final List<Notice> notices = [];
  String? _selectedKidId;
  bool loaded = false;

  int _idSeed = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSeed++}';

  // ---------------------------------------------------------------- loading

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        kids.addAll((j['kids'] as List).map((e) => Kid.fromJson(e as Map<String, dynamic>)));
        entries.addAll((j['entries'] as List).map((e) => Entry.fromJson(e as Map<String, dynamic>)));
        jars.addAll((j['jars'] as List).map((e) => Jar.fromJson(e as Map<String, dynamic>)));
        notices.addAll((j['notices'] as List).map((e) => Notice.fromJson(e as Map<String, dynamic>)));
        _selectedKidId = j['selectedKidId'] as String?;
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
        kids.clear();
        entries.clear();
        jars.clear();
        notices.clear();
      }
    }
    processDueCycles(DateTime.now(), save: false);
    loaded = true;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'kids': kids.map((k) => k.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'jars': jars.map((e) => e.toJson()).toList(),
        'notices': notices.map((e) => e.toJson()).toList(),
        'selectedKidId': _selectedKidId,
      }),
    );
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  // ---------------------------------------------------------------- kids

  bool get hasKids => kids.isNotEmpty;

  Kid? get selectedKid {
    if (kids.isEmpty) return null;
    return kids.firstWhere((k) => k.id == _selectedKidId, orElse: () => kids.first);
  }

  void selectKid(String id) {
    if (_selectedKidId == id) return;
    _selectedKidId = id;
    _commit();
  }

  int _nextColorIndex() {
    final used = kids.map((k) => k.colorIndex).toSet();
    for (var i = 0; i < 5; i++) {
      if (!used.contains(i)) return i;
    }
    return kids.length;
  }

  Kid addKid({
    required String name,
    required int pocketMoney,
    required Frequency frequency,
    required String currency,
  }) {
    final now = DateTime.now();
    final payDay = Kid.defaultPayDay(frequency);
    final kid = Kid(
      id: _newId(),
      name: name.trim(),
      colorIndex: _nextColorIndex(),
      pocketMoney: pocketMoney,
      frequency: frequency,
      currency: currency,
      payDay: payDay,
      nextPayDate: firstPayDateAfter(now, frequency, payDay),
      createdAt: now,
    );
    kids.add(kid);
    _selectedKidId = kid.id;
    // The first pocket money lands straight away so the treasury isn't empty.
    entries.add(Entry(
      id: _newId(),
      kidId: kid.id,
      type: EntryType.deposit,
      amount: pocketMoney,
      depositKind: DepositKind.pocketMoney,
      note: 'First pocket money',
      date: now,
    ));
    _notify(kid, NoticeKind.pocketMoney, 'Welcome, ${kid.name}!',
        'Your treasury is open! ${money(pocketMoney, currency)} is ready to spend or save. Next pocket money comes on ${shortDate(kid.nextPayDate)}.',
        now);
    _commit();
    return kid;
  }

  void updateKid(
    Kid kid, {
    String? name,
    int? pocketMoney,
    Frequency? frequency,
    String? currency,
    int? interestPct,
    Map<int, int>? jarBonus,
  }) {
    if (name != null && name.trim().isNotEmpty) kid.name = name.trim();
    if (pocketMoney != null && pocketMoney > 0) kid.pocketMoney = pocketMoney;
    if (currency != null) kid.currency = currency;
    if (interestPct != null) kid.interestPct = interestPct;
    if (jarBonus != null) kid.jarBonus = Map.of(jarBonus);
    if (frequency != null && frequency != kid.frequency) {
      kid.frequency = frequency;
      kid.payDay = Kid.defaultPayDay(frequency);
      kid.nextPayDate = firstPayDateAfter(DateTime.now(), frequency, kid.payDay);
    }
    _commit();
  }

  /// Sets the pocket-money / money-chat day and time.
  void setReviewSchedule(Kid kid, {required int payDay, required int hour, required int minute}) {
    kid.payDay = payDay;
    kid.reviewHour = hour;
    kid.reviewMinute = minute;
    final now = DateTime.now();
    final today = dateOnly(now);
    // Today still counts if the chosen time hasn't passed yet.
    final todayMatches = kid.frequency == Frequency.monthly ? today.day == payDay : today.weekday == payDay;
    final todayAt = DateTime(today.year, today.month, today.day, hour, minute);
    kid.nextPayDate = todayMatches && todayAt.isAfter(now) ? today : firstPayDateAfter(now, kid.frequency, payDay);
    _commit();
  }

  /// Deletes a kid with all their money history, jars and notifications.
  void removeKid(Kid kid) {
    kids.removeWhere((k) => k.id == kid.id);
    entries.removeWhere((e) => e.kidId == kid.id);
    jars.removeWhere((j) => j.kidId == kid.id);
    notices.removeWhere((n) => n.kidId == kid.id);
    if (_selectedKidId == kid.id) _selectedKidId = kids.isEmpty ? null : kids.first.id;
    _commit();
  }

  // ---------------------------------------------------------------- money

  List<Entry> entriesFor(Kid kid) =>
      entries.where((e) => e.kidId == kid.id).toList()..sort((a, b) => b.date.compareTo(a.date));

  int balanceOf(Kid kid) {
    var total = 0;
    for (final e in entries) {
      if (e.kidId != kid.id) continue;
      total += e.isExpense ? -e.amount : e.amount;
    }
    return total;
  }

  int spentInMonth(Kid kid, DateTime month) => entries
      .where((e) => e.kidId == kid.id && e.isExpense && e.date.year == month.year && e.date.month == month.month)
      .fold(0, (s, e) => s + e.amount);

  int inInMonth(Kid kid, DateTime month) => entries
      .where((e) => e.kidId == kid.id && !e.isExpense && e.date.year == month.year && e.date.month == month.month)
      .fold(0, (s, e) => s + e.amount);

  /// Months (first day) that have entries for this kid, newest first, always including the current month.
  List<DateTime> activeMonths(Kid kid) {
    final now = DateTime.now();
    final set = <DateTime>{DateTime(now.year, now.month)};
    for (final e in entries) {
      if (e.kidId == kid.id) set.add(DateTime(e.date.year, e.date.month));
    }
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Returns an error message, or null on success.
  String? addExpense(Kid kid, int amount, Category category, String note) {
    if (amount <= 0) return 'Type how much it cost';
    final balance = balanceOf(kid);
    if (amount > balance) {
      return 'Whoa! ${kid.name} only has ${money(balance < 0 ? 0 : balance, kid.currency)} in the treasury';
    }
    final now = DateTime.now();
    entries.add(Entry(
      id: _newId(),
      kidId: kid.id,
      type: EntryType.expense,
      amount: amount,
      category: category,
      note: note.trim(),
      date: now,
    ));
    final what = note.trim().isEmpty ? categoryLabel(category).toLowerCase() : note.trim();
    _notify(kid, NoticeKind.expense, 'Spend logged', '${kid.name} spent ${money(amount, kid.currency)} on $what.', now,
        read: true);
    _commit();
    return null;
  }

  String? addMoney(Kid kid, int amount, String note) {
    if (amount <= 0) return 'Type how much came in';
    final now = DateTime.now();
    entries.add(Entry(
      id: _newId(),
      kidId: kid.id,
      type: EntryType.deposit,
      amount: amount,
      depositKind: DepositKind.gift,
      note: note.trim().isEmpty ? 'Money in' : note.trim(),
      date: now,
    ));
    _notify(kid, NoticeKind.deposit, 'Ka-ching!',
        '${money(amount, kid.currency)} landed in ${kid.name}\'s treasury.', now,
        read: true);
    _commit();
    return null;
  }

  /// Pocket money after this cycle's jar contributions.
  int nextPocketMoney(Kid kid) {
    final v = kid.pocketMoney - jarContributionPerCycle(kid);
    return v < 0 ? 0 : v;
  }

  int jarContributionPerCycle(Kid kid) =>
      activeJars(kid).where((j) => j.cyclesPaid < j.totalCycles).fold(0, (s, j) => s + j.amountPerCycle);

  // ---------------------------------------------------------------- jars

  List<Jar> activeJars(Kid kid) =>
      jars.where((j) => j.kidId == kid.id && j.isActive).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<Jar> pastJars(Kid kid) =>
      jars.where((j) => j.kidId == kid.id && !j.isActive).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));

  bool hasAnyJar(Kid kid) => jars.any((j) => j.kidId == kid.id);

  /// Percent of pocket money already going into active jars.
  int usedJarPercent(Kid kid) => activeJars(kid).fold(0, (s, j) => s + j.percent);

  /// The most a new jar can take, keeping all jars within 10%. Below 2 means no room.
  int availableJarPercent(Kid kid) => maxJarPct - usedJarPercent(kid);

  bool canStartJar(Kid kid) => availableJarPercent(kid) >= minJarPct;

  int jarAmountForPercent(Kid kid, int pct) => (kid.pocketMoney * pct / 100).round();

  /// The pocket-money day on which a jar of [months] would open if started now.
  DateTime jarOpensOn(Kid kid, int months) {
    final cycles = cyclesForMonths(months, kid.frequency);
    var d = kid.nextPayDate;
    for (var i = 1; i < cycles; i++) {
      d = nextCycle(d, kid.frequency, kid.payDay);
    }
    return d;
  }

  Jar? createJar(Kid kid, {required int percent, required int months}) {
    if (percent < minJarPct || percent > availableJarPercent(kid)) return null;
    final now = DateTime.now();
    final jar = Jar(
      id: _newId(),
      kidId: kid.id,
      amountPerCycle: jarAmountForPercent(kid, percent),
      percent: percent,
      months: months,
      bonusPct: kid.jarBonus[months] ?? 0,
      totalCycles: cyclesForMonths(months, kid.frequency),
      startDate: now,
      opensOn: jarOpensOn(kid, months),
    );
    jars.add(jar);
    _notify(kid, NoticeKind.jarProgress, 'A new jar is growing!',
        '${kid.name} will drop ${money(jar.amountPerCycle, kid.currency)} in every ${cycleWord(kid.frequency)} and get back ${money(jar.payout, kid.currency)}.',
        now,
        read: true);
    _commit();
    return jar;
  }

  /// Cancels a jar and returns what was saved, without the bonus.
  void settleJar(Jar jar) {
    if (!jar.isActive) return;
    final kid = kids.firstWhere((k) => k.id == jar.kidId);
    final now = DateTime.now();
    jar.status = JarStatus.cancelled;
    jar.closedOn = now;
    if (jar.saved > 0) {
      entries.add(Entry(
        id: _newId(),
        kidId: kid.id,
        type: EntryType.deposit,
        amount: jar.saved,
        depositKind: DepositKind.jarSettled,
        note: 'Jar opened early',
        date: now,
      ));
    }
    _notify(kid, NoticeKind.jarSettled, 'Jar opened early',
        '${money(jar.saved, kid.currency)} went back to ${kid.name}\'s treasury. No bonus this time!', now,
        read: true);
    _commit();
  }

  // ---------------------------------------------------------------- pocket-money days

  /// Runs every pocket-money day that has come due: interest on leftover money,
  /// jar contributions, the new pocket money, and jar payouts.
  void processDueCycles(DateTime now, {bool save = true}) {
    var changed = false;
    for (final kid in kids) {
      var guard = 0;
      while (!kid.nextDueAt.isAfter(now) && guard < 120) {
        guard++;
        changed = true;
        final payDay = kid.nextDueAt;

        // 1. Interest on money left over from the last cycle.
        final leftover = balanceOf(kid);
        final interest = leftover > 0 ? (leftover * kid.interestPct / 100).round() : 0;

        // 2. Jar contributions.
        var contributed = 0;
        final opened = <Jar>[];
        for (final jar in activeJars(kid)) {
          if (jar.cyclesPaid >= jar.totalCycles) continue;
          jar.cyclesPaid++;
          jar.saved += jar.amountPerCycle;
          contributed += jar.amountPerCycle;
          if (jar.cyclesPaid >= jar.totalCycles) opened.add(jar);
        }

        // 3. Pocket money, minus what went into jars.
        final remaining = kid.pocketMoney - contributed;
        final int pocket = remaining < 0 ? 0 : remaining;
        entries.add(Entry(
          id: _newId(),
          kidId: kid.id,
          type: EntryType.deposit,
          amount: pocket,
          depositKind: DepositKind.pocketMoney,
          note: 'Pocket money',
          date: payDay,
        ));
        if (interest > 0) {
          entries.add(Entry(
            id: _newId(),
            kidId: kid.id,
            type: EntryType.deposit,
            amount: interest,
            depositKind: DepositKind.interest,
            note: 'Saving bonus',
            date: payDay.add(const Duration(minutes: 1)),
          ));
        }

        final jarText = contributed > 0 ? ' ${money(contributed, kid.currency)} hopped into the jar.' : '';
        _notify(kid, NoticeKind.pocketMoney, 'Pocket money day!',
            'Ka-ching! ${money(pocket, kid.currency)} landed for ${kid.name}.$jarText', payDay);
        if (interest > 0) {
          _notify(kid, NoticeKind.interest, 'Your savings grew!',
              '${kid.name} kept ${money(leftover, kid.currency)} and earned ${money(interest, kid.currency)} extra. Nice saving!',
              payDay);
        }
        _notify(kid, NoticeKind.review, 'Money chat time',
            'Sit with ${kid.name} and catch up on this ${cycleWord(kid.frequency)}\'s spends.', payDay);

        // 4. Jars that just opened pay out with their bonus.
        for (final jar in opened) {
          jar.status = JarStatus.matured;
          jar.closedOn = payDay;
          final payout = jar.saved + (jar.saved * jar.bonusPct / 100).round();
          entries.add(Entry(
            id: _newId(),
            kidId: kid.id,
            type: EntryType.deposit,
            amount: payout,
            depositKind: DepositKind.jarPayout,
            note: '${jar.months}-month jar popped open',
            date: payDay.add(const Duration(minutes: 2)),
          ));
          _notify(kid, NoticeKind.jarOpened, 'Jar popped open!',
              '${kid.name}\'s ${jar.months}-month jar paid out ${money(payout, kid.currency)}, bonus included. Woohoo!', payDay);
        }

        kid.nextPayDate = nextCycle(kid.nextPayDate, kid.frequency, kid.payDay);
      }
    }
    if (changed) {
      notifyListeners();
      if (save) _save();
    }
  }

  // ---------------------------------------------------------------- notices

  List<Notice> get sortedNotices => [...notices]..sort((a, b) => b.date.compareTo(a.date));

  bool get hasUnread => notices.any((n) => !n.read);

  void markAllRead() {
    var changed = false;
    for (final n in notices) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) _commit();
  }

  void _notify(Kid kid, NoticeKind kind, String title, String body, DateTime date, {bool read = false}) {
    notices.add(Notice(id: _newId(), kidId: kid.id, kind: kind, title: title, body: body, date: date, read: read));
    if (notices.length > 200) {
      notices.sort((a, b) => a.date.compareTo(b.date));
      notices.removeRange(0, notices.length - 200);
    }
  }
}

String categoryLabel(Category c) => switch (c) {
      Category.food => 'Food',
      Category.travel => 'Travel',
      Category.fun => 'Fun',
    };
