/// Earnings period summary row (**Fake Alpha only**).
///
/// [amountSar] uses `double` solely for deterministic Fake UI seeds.
/// Real production / settlement / accounting monetary values must use
/// **integer minor units** (e.g. halalas) or an approved decimal type —
/// never promote this `double` field into settlement-grade logic.
class EarningsPeriod {
  const EarningsPeriod({
    required this.id,
    required this.labelKey,
    required this.amountSar,
    required this.tripsCount,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;

  /// today | week | month
  final String labelKey;

  /// Fake Alpha display amount only — not settlement-grade (see class doc).
  final double amountSar;
  final int tripsCount;
  final DateTime startsAt;
  final DateTime endsAt;
}

enum EarningsFilter { all, today, week, month }
