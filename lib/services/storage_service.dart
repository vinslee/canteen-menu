import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_model.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  SharedPreferences? _prefs;

  static const String _currentWeekKey = 'current_week_menu';
  static const String _lastWeekKey = 'last_week_menu';
  static const String _commonDishesKey = 'common_dishes';
  static const String _weekHistoryKey = 'week_history';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String _getCurrentWeekId() {
    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor();
    return '${now.year}-W$weekNumber';
  }

  Future<void> saveCurrentWeekMenu(WeekMenuModel menu) async {
    final json = jsonEncode(menu.toJson());
    await _prefs?.setString(_currentWeekKey, json);
    await _saveToHistory(menu);
  }

  Future<WeekMenuModel?> getCurrentWeekMenu() async {
    final json = _prefs?.getString(_currentWeekKey);
    if (json == null) {
      return WeekMenuModel(weekId: _getCurrentWeekId());
    }
    try {
      return WeekMenuModel.fromJson(jsonDecode(json));
    } catch (e) {
      return WeekMenuModel(weekId: _getCurrentWeekId());
    }
  }

  Future<void> _saveToHistory(WeekMenuModel menu) async {
    final historyJson = _prefs?.getString(_weekHistoryKey) ?? '{}';
    final history = jsonDecode(historyJson) as Map<String, dynamic>;
    history[menu.weekId] = menu.toJson();
    await _prefs?.setString(_weekHistoryKey, jsonEncode(history));
  }

  Future<WeekMenuModel?> getLastWeekMenu() async {
    final historyJson = _prefs?.getString(_weekHistoryKey) ?? '{}';
    final history = jsonDecode(historyJson) as Map<String, dynamic>;
    
    if (history.isEmpty) return null;

    final sortedKeys = history.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final currentWeekId = _getCurrentWeekId();
    for (final key in sortedKeys) {
      if (key != currentWeekId) {
        return WeekMenuModel.fromJson(history[key]);
      }
    }

    return null;
  }

  Future<void> saveCommonDishes(List<String> dishes) async {
    await _prefs?.setStringList(_commonDishesKey, dishes);
  }

  List<String> getCommonDishes() {
    return _prefs?.getStringList(_commonDishesKey) ?? _getDefaultDishes();
  }

  List<String> _getDefaultDishes() {
    return [
      '红烧肉',
      '糖醋排骨',
      '宫保鸡丁',
      '麻婆豆腐',
      '清炒时蔬',
      '番茄炒蛋',
      '红烧茄子',
      '鱼香肉丝',
      '土豆炖牛肉',
      '青椒肉丝',
      '蒜蓉西兰花',
      '醋溜白菜',
      '红烧鱼块',
      '可乐鸡翅',
      '冬瓜排骨汤',
      '紫菜蛋花汤',
      '西红柿鸡蛋汤',
      '米饭',
      '馒头',
      '花卷',
      '包子',
      '油条',
      '豆浆',
      '小米粥',
      '八宝粥',
      '鸡蛋',
      '牛奶',
    ];
  }

  Future<void> addCommonDish(String dish) async {
    final dishes = getCommonDishes();
    if (!dishes.contains(dish)) {
      dishes.insert(0, dish);
      await saveCommonDishes(dishes);
    }
  }

  Future<void> removeCommonDish(String dish) async {
    final dishes = getCommonDishes();
    dishes.remove(dish);
    await saveCommonDishes(dishes);
  }
}
