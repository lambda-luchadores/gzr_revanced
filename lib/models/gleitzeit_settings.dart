class GleitzeitSettings {
  final double weeklyHours;
  final Duration currentBalance;
  final bool enableMobileWork;
  final double mobileWorkPercentage;
  
  static const Duration minGleitzeitTime = Duration(hours: 6);
  static const Duration maxGleitzeitTime = Duration(hours: 20);
  static const Duration funktionszeitStart = Duration(hours: 9);
  static const Duration funktionszeitEnd = Duration(hours: 15);
  static const Duration breakWindowStart = Duration(hours: 11, minutes: 15);
  static const Duration breakWindowEnd = Duration(hours: 14, minutes: 30);
  static const Duration maxDailyWork = Duration(hours: 10);
  static const Duration shortBreakThreshold = Duration(hours: 6);
  static const Duration longBreakThreshold = Duration(hours: 9);
  static const Duration shortBreakDuration = Duration(minutes: 30);
  static const Duration additionalBreakDuration = Duration(minutes: 15);
  static const int maxNegativeBalance = -10;
  static const int maxPositiveBalance = 20;
  static const int yearEndCap = 40;
  
  const GleitzeitSettings({
    this.weeklyHours = 40,
    this.currentBalance = Duration.zero,
    this.enableMobileWork = true,
    this.mobileWorkPercentage = 0.6,
  });
  
  double get dailyTargetHours => weeklyHours / 5;
  
  Duration get dailyTargetDuration => Duration(
    hours: dailyTargetHours.floor(),
    minutes: ((dailyTargetHours - dailyTargetHours.floor()) * 60).round(),
  );
  
  bool isBalanceInWarningRange() {
    final hours = currentBalance.inHours;
    return hours <= maxNegativeBalance || hours >= maxPositiveBalance;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'weeklyHours': weeklyHours,
      'currentBalance': currentBalance.inMinutes,
      'enableMobileWork': enableMobileWork,
      'mobileWorkPercentage': mobileWorkPercentage,
    };
  }
  
  factory GleitzeitSettings.fromJson(Map<String, dynamic> json) {
    return GleitzeitSettings(
      weeklyHours: json['weeklyHours']?.toDouble() ?? 40,
      currentBalance: Duration(minutes: json['currentBalance'] ?? 0),
      enableMobileWork: json['enableMobileWork'] ?? true,
      mobileWorkPercentage: json['mobileWorkPercentage']?.toDouble() ?? 0.6,
    );
  }
  
  GleitzeitSettings copyWith({
    double? weeklyHours,
    Duration? currentBalance,
    bool? enableMobileWork,
    double? mobileWorkPercentage,
  }) {
    return GleitzeitSettings(
      weeklyHours: weeklyHours ?? this.weeklyHours,
      currentBalance: currentBalance ?? this.currentBalance,
      enableMobileWork: enableMobileWork ?? this.enableMobileWork,
      mobileWorkPercentage: mobileWorkPercentage ?? this.mobileWorkPercentage,
    );
  }
}