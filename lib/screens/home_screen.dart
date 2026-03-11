import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../models/menu_model.dart';
import '../services/storage_service.dart';
import '../widgets/meal_edit_dialog.dart';
import '../widgets/common_dishes_panel.dart';
import '../widgets/menu_image_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeekMenuModel? _currentMenu;
  List<String> _commonDishes = [];
  bool _isLoading = true;
  int _selectedDayIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final menu = await StorageService.instance.getCurrentWeekMenu();
    final dishes = StorageService.instance.getCommonDishes();
    setState(() {
      _currentMenu = menu;
      _commonDishes = dishes;
      _isLoading = false;
    });
  }

  Future<void> _saveMenu() async {
    if (_currentMenu != null) {
      await StorageService.instance.saveCurrentWeekMenu(_currentMenu!);
    }
  }

  void _updateMeal(int dayIndex, String mealType, MealModel meal) {
    if (_currentMenu == null) return;

    final days = List<DayMenuModel>.from(_currentMenu!.days);
    final day = days[dayIndex];

    DayMenuModel updatedDay;
    switch (mealType) {
      case 'breakfast':
        updatedDay = day.copyWith(breakfast: meal);
        break;
      case 'lunch':
        updatedDay = day.copyWith(lunch: meal);
        break;
      case 'dinner':
        updatedDay = day.copyWith(dinner: meal);
        break;
      default:
        return;
    }

    days[dayIndex] = updatedDay;
    setState(() {
      _currentMenu = _currentMenu!.copyWith(days: days);
    });
    _saveMenu();
  }

  Future<void> _copyMenuText() async {
    if (_currentMenu == null) return;

    final text = _currentMenu!.toPlainText();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('菜谱已复制到剪贴板', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _generateImage() async {
    if (_currentMenu == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MenuImageGenerator(menu: _currentMenu!),
    );
  }

  Future<void> _copyFromLastWeek() async {
    final lastWeek = await StorageService.instance.getLastWeekMenu();
    if (lastWeek == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('没有找到上周菜谱', style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认复制', style: TextStyle(fontSize: 22)),
        content: const Text(
          '确定要用上周菜谱覆盖当前菜谱吗？',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _currentMenu = WeekMenuModel(
          weekId: _currentMenu!.weekId,
          days: lastWeek.days.map((d) => DayMenuModel(
            dayName: d.dayName,
            breakfast: MealModel(name: d.breakfast.name, note: d.breakfast.note),
            lunch: MealModel(name: d.lunch.name, note: d.lunch.note),
            dinner: MealModel(name: d.dinner.name, note: d.dinner.note),
          )).toList(),
        );
      });
      await _saveMenu();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已复制上周菜谱', style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showMealEditDialog(int dayIndex, String mealType, String mealName, MealModel meal) {
    showDialog(
      context: context,
      builder: (context) => MealEditDialog(
        title: '${_currentMenu!.days[dayIndex].dayName} $mealName',
        meal: meal,
        commonDishes: _commonDishes,
        onSave: (updatedMeal) {
          _updateMeal(dayIndex, mealType, updatedMeal);
        },
        onAddDish: (dish) async {
          await StorageService.instance.addCommonDish(dish);
          setState(() {
            _commonDishes.insert(0, dish);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('食堂菜谱'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: '复制上周菜谱',
            onPressed: _copyFromLastWeek,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDayTabs(),
          Expanded(
            child: _currentMenu == null
                ? const Center(child: Text('加载失败'))
                : _buildDayContent(),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width / 7,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                _currentMenu!.days[index].dayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent() {
    final day = _currentMenu!.days[_selectedDayIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMealCard(
            '早餐',
            'breakfast',
            day.breakfast,
            Icons.wb_sunny,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            '午餐',
            'lunch',
            day.lunch,
            Icons.lunch_dining,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            '晚餐',
            'dinner',
            day.dinner,
            Icons.dinner_dining,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    String title,
    String mealType,
    MealModel meal,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showMealEditDialog(_selectedDayIndex, mealType, title, meal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit,
                    color: Colors.grey[400],
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name.isEmpty ? '点击编辑菜品' : meal.name,
                      style: TextStyle(
                        fontSize: 22,
                        color: meal.name.isEmpty ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meal.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '备注：${meal.note}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyMenuText,
                icon: const Icon(Icons.copy, size: 24),
                label: const Text('复制文本'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateImage,
                icon: const Icon(Icons.image, size: 24),
                label: const Text('生成图片'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
