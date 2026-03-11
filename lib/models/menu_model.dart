import 'dart:convert';

class MealModel {
  final String name;
  final String note;

  MealModel({this.name = '', this.note = ''});

  MealModel copyWith({String? name, String? note}) {
    return MealModel(
      name: name ?? this.name,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'note': note};
  }

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      name: json['name'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class DayMenuModel {
  final String dayName;
  final MealModel breakfast;
  final MealModel lunch;
  final MealModel dinner;

  DayMenuModel({
    required this.dayName,
    MealModel? breakfast,
    MealModel? lunch,
    MealModel? dinner,
  })  : breakfast = breakfast ?? MealModel(),
        lunch = lunch ?? MealModel(),
        dinner = dinner ?? MealModel();

  DayMenuModel copyWith({
    String? dayName,
    MealModel? breakfast,
    MealModel? lunch,
    MealModel? dinner,
  }) {
    return DayMenuModel(
      dayName: dayName ?? this.dayName,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'breakfast': breakfast.toJson(),
      'lunch': lunch.toJson(),
      'dinner': dinner.toJson(),
    };
  }

  factory DayMenuModel.fromJson(Map<String, dynamic> json) {
    return DayMenuModel(
      dayName: json['dayName'] ?? '',
      breakfast: json['breakfast'] != null
          ? MealModel.fromJson(json['breakfast'])
          : null,
      lunch: json['lunch'] != null ? MealModel.fromJson(json['lunch']) : null,
      dinner:
          json['dinner'] != null ? MealModel.fromJson(json['dinner']) : null,
    );
  }
}

class WeekMenuModel {
  final String weekId;
  final List<DayMenuModel> days;

  WeekMenuModel({required this.weekId, List<DayMenuModel>? days})
      : days = days ?? _getDefaultDays();

  static List<DayMenuModel> _getDefaultDays() {
    return [
      DayMenuModel(dayName: '周一'),
      DayMenuModel(dayName: '周二'),
      DayMenuModel(dayName: '周三'),
      DayMenuModel(dayName: '周四'),
      DayMenuModel(dayName: '周五'),
      DayMenuModel(dayName: '周六'),
      DayMenuModel(dayName: '周日'),
    ];
  }

  WeekMenuModel copyWith({String? weekId, List<DayMenuModel>? days}) {
    return WeekMenuModel(
      weekId: weekId ?? this.weekId,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekId': weekId,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  factory WeekMenuModel.fromJson(Map<String, dynamic> json) {
    return WeekMenuModel(
      weekId: json['weekId'] ?? '',
      days: json['days'] != null
          ? (json['days'] as List)
              .map((d) => DayMenuModel.fromJson(d))
              .toList()
          : null,
    );
  }

  String toPlainText() {
    final buffer = StringBuffer();
    buffer.writeln('【本周菜谱】');
    buffer.writeln();

    for (final day in days) {
      buffer.writeln('【${day.dayName}】');
      buffer.writeln('早餐：${day.breakfast.name}${day.breakfast.note.isNotEmpty ? '（${day.breakfast.note}）' : ''}');
      buffer.writeln('午餐：${day.lunch.name}${day.lunch.note.isNotEmpty ? '（${day.lunch.note}）' : ''}');
      buffer.writeln('晚餐：${day.dinner.name}${day.dinner.note.isNotEmpty ? '（${day.dinner.note}）' : ''}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
