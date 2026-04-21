class Habit {
  final int? id;
  final String name;
  final String? motto;
  final List<String> notifTimes;
  final String durationType;
  final int? durationValue;
  final List<String> customDays;
  final String template;
  final int? waterTargetAmount;
  final String? waterTargetUnit;
  final int currentWaterAmount;
  final String? startDate;
  final String? endDate;
  final bool active;
  final bool completedToday;

  Habit({
    this.id,
    required this.name,
    this.motto,
    this.notifTimes = const [],
    this.durationType = 'ALL_TIME',
    this.durationValue,
    this.customDays = const [], // ← tambah
    this.template = 'CUSTOM',
    this.waterTargetAmount,
    this.waterTargetUnit,
    this.currentWaterAmount = 0,
    this.startDate,
    this.endDate,
    this.active = true,
    this.completedToday = false,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      motto: json['motto'],
      notifTimes: json['notifTimes'] != null
          ? List<String>.from(json['notifTimes'])
          : [],
      durationType: json['durationType'] ?? 'ALL_TIME',
      durationValue: json['durationValue'],
      customDays: json['customDays'] != null
          ? List<String>.from(json['customDays'])
          : [], 
      template: json['template'] ?? 'CUSTOM',
      waterTargetAmount: json['waterTargetAmount'],
      waterTargetUnit: json['waterTargetUnit'],
      currentWaterAmount: json['currentWaterAmount'] ?? 0,
      startDate: json['startDate'],
      endDate: json['endDate'],
      active: json['active'] ?? true,
      completedToday: json['completedToday'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'motto': motto,
      'notifTimes': notifTimes,
      'durationType': durationType,
      'durationValue': durationValue,
      'customDays': customDays, 
      'template': template,
      'waterTargetAmount': waterTargetAmount,
      'waterTargetUnit': waterTargetUnit,
      'startDate': startDate,
    };
  }
}