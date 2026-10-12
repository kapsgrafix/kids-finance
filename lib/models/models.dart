// Data models for Tiny Treasury. All money is stored as whole currency units (int).

enum Frequency { weekly, monthly }

enum EntryType { expense, deposit }

enum Category { food, travel, fun }

enum DepositKind { pocketMoney, interest, gift, jarPayout, jarSettled }

enum JarStatus { active, matured, cancelled }

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class Currency {
  final String code;
  final String symbol;
  final String label;
  const Currency(this.code, this.symbol, this.label);

  static const all = [
    Currency('INR', '₹', 'Indian Rupee'),
    Currency('USD', r'$', 'US Dollar'),
    Currency('EUR', '€', 'Euro'),
    Currency('GBP', '£', 'British Pound'),
    Currency('AED', 'AED ', 'UAE Dirham'),
  ];

  static Currency of(String code) => all.firstWhere((c) => c.code == code, orElse: () => all.first);
}

class Kid {
  final String id;
  String name;
  int colorIndex;
  int pocketMoney;
  Frequency frequency;
  String currency;

  /// Interest paid on money left at each pocket-money day, in percent.
  int interestPct;

  /// Jar bonus in percent, keyed by plan length in months (3, 6, 12).
  Map<int, int> jarBonus;

  /// Pocket-money / review day: day of month (1–28) when monthly, weekday (1 = Mon … 7 = Sun) when weekly.
  int payDay;
  int reviewHour;
  int reviewMinute;

  /// The next pocket-money day (date only).
  DateTime nextPayDate;
  final DateTime createdAt;

  Kid({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.pocketMoney,
    required this.frequency,
    required this.currency,
    required this.nextPayDate,
    required this.createdAt,
    required this.payDay,
    this.reviewHour = 18,
    this.reviewMinute = 0,
    this.interestPct = 10,
    Map<int, int>? jarBonus,
  }) : jarBonus = jarBonus ?? {3: 4, 6: 8, 12: 12};

  static int defaultPayDay(Frequency f) => f == Frequency.monthly ? 1 : DateTime.saturday;

  /// When the next pocket-money day (and money chat) happens.
  DateTime get nextDueAt => DateTime(nextPayDate.year, nextPayDate.month, nextPayDate.day, reviewHour, reviewMinute);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'pocketMoney': pocketMoney,
        'frequency': frequency.name,
        'currency': currency,
        'interestPct': interestPct,
        'jarBonus': jarBonus.map((k, v) => MapEntry(k.toString(), v)),
        'payDay': payDay,
        'reviewHour': reviewHour,
        'reviewMinute': reviewMinute,
        'nextPayDate': nextPayDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Kid.fromJson(Map<String, dynamic> j) {
    final frequency = _enumByName(Frequency.values, j['frequency'] as String?, Frequency.monthly);
    return Kid(
        id: j['id'] as String,
        name: j['name'] as String,
        colorIndex: (j['colorIndex'] as num?)?.toInt() ?? 0,
        pocketMoney: (j['pocketMoney'] as num).toInt(),
        frequency: frequency,
        currency: (j['currency'] as String?) ?? 'INR',
        payDay: (j['payDay'] as num?)?.toInt() ?? defaultPayDay(frequency),
        reviewHour: (j['reviewHour'] as num?)?.toInt() ?? 18,
        reviewMinute: (j['reviewMinute'] as num?)?.toInt() ?? 0,
        interestPct: (j['interestPct'] as num?)?.toInt() ?? 10,
        jarBonus: (j['jarBonus'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
        nextPayDate: DateTime.parse(j['nextPayDate'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
  }
}

class Entry {
  final String id;
  final String kidId;
  final EntryType type;
  final int amount;
  final Category? category; // expenses only
  final DepositKind? depositKind; // deposits only
  final String note;
  final DateTime date;

  Entry({
    required this.id,
    required this.kidId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    this.category,
    this.depositKind,
  });

  bool get isExpense => type == EntryType.expense;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kidId': kidId,
        'type': type.name,
        'amount': amount,
        'category': category?.name,
        'depositKind': depositKind?.name,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> j) {
    final type = _enumByName(EntryType.values, j['type'] as String?, EntryType.expense);
    return Entry(
      id: j['id'] as String,
      kidId: j['kidId'] as String,
      type: type,
      amount: (j['amount'] as num).toInt(),
      category: j['category'] == null ? null : _enumByName(Category.values, j['category'] as String?, Category.food),
      depositKind: j['depositKind'] == null ? null : _enumByName(DepositKind.values, j['depositKind'] as String?, DepositKind.gift),
      note: (j['note'] as String?) ?? '',
      date: DateTime.parse(j['date'] as String),
    );
  }
}

class Jar {
  final String id;
  final String kidId;

  /// Amount set aside on every pocket-money day.
  final int amountPerCycle;

  /// Percent of pocket money chosen on the slider (2–10).
  final int percent;
  final int months;
  final int bonusPct;

  /// Number of pocket-money days this jar collects on.
  final int totalCycles;
  int cyclesPaid;
  int saved;
  JarStatus status;
  final DateTime startDate;

  /// The pocket-money day on which the jar opens and pays out.
  final DateTime opensOn;
  DateTime? closedOn;

  Jar({
    required this.id,
    required this.kidId,
    required this.amountPerCycle,
    required this.percent,
    required this.months,
    required this.bonusPct,
    required this.totalCycles,
    required this.startDate,
    required this.opensOn,
    this.cyclesPaid = 0,
    this.saved = 0,
    this.status = JarStatus.active,
    this.closedOn,
  });

  int get target => amountPerCycle * totalCycles;
  int get bonusAmount => (target * bonusPct / 100).round();
  int get payout => target + bonusAmount;
  bool get isActive => status == JarStatus.active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kidId': kidId,
        'amountPerCycle': amountPerCycle,
        'percent': percent,
        'months': months,
        'bonusPct': bonusPct,
        'totalCycles': totalCycles,
        'cyclesPaid': cyclesPaid,
        'saved': saved,
        'status': status.name,
        'startDate': startDate.toIso8601String(),
        'opensOn': opensOn.toIso8601String(),
        'closedOn': closedOn?.toIso8601String(),
      };

  factory Jar.fromJson(Map<String, dynamic> j) => Jar(
        id: j['id'] as String,
        kidId: j['kidId'] as String,
        amountPerCycle: (j['amountPerCycle'] as num).toInt(),
        percent: (j['percent'] as num?)?.toInt() ?? 5,
        months: (j['months'] as num).toInt(),
        bonusPct: (j['bonusPct'] as num).toInt(),
        totalCycles: (j['totalCycles'] as num).toInt(),
        cyclesPaid: (j['cyclesPaid'] as num?)?.toInt() ?? 0,
        saved: (j['saved'] as num?)?.toInt() ?? 0,
        status: _enumByName(JarStatus.values, j['status'] as String?, JarStatus.active),
        startDate: DateTime.parse(j['startDate'] as String),
        opensOn: DateTime.parse(j['opensOn'] as String),
        closedOn: j['closedOn'] == null ? null : DateTime.parse(j['closedOn'] as String),
      );
}

enum NoticeKind { pocketMoney, interest, review, jarProgress, jarOpened, jarSettled, expense, deposit }

class Notice {
  final String id;
  final String? kidId;
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime date;
  bool read;

  Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.date,
    this.kidId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kidId': kidId,
        'kind': kind.name,
        'title': title,
        'body': body,
        'date': date.toIso8601String(),
        'read': read,
      };

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        id: j['id'] as String,
        kidId: j['kidId'] as String?,
        kind: _enumByName(NoticeKind.values, j['kind'] as String?, NoticeKind.deposit),
        title: j['title'] as String,
        body: j['body'] as String,
        date: DateTime.parse(j['date'] as String),
        read: (j['read'] as bool?) ?? false,
      );
}
