import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  static const List<String> _defaultDayNames = [
    '周一', '周二', '周三', '周四', '周五', '周六', '周日'
  ];

  List<String> get _dayNames => _currentMenu?.days.map((d) => d.dayName).toList() ?? _defaultDayNames;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _requestPermissions();
    await _loadData();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      return;
    }
    if (await Permission.manageExternalStorage.request().isGranted) {
      return;
    }
    if (await Permission.photos.request().isGranted) {
      return;
    }
  }

  Future<void> _loadData() async {
    try {
      final menu = await StorageService.instance.getCurrentWeekMenu();
      final dishes = StorageService.instance.getCommonDishes();
      if (mounted) {
        setState(() {
          _currentMenu = menu;
          _commonDishes = dishes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentMenu = WeekMenuModel(weekId: '');
          _commonDishes = StorageService.instance.getCommonDishes();
          _isLoading = false;
        });
      }
    }
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
          content: Text('菜谱已复制到剪贴板', style: TextStyle(fontSize: 20)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_currentMenu == null) return;

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要存储权限才能导出', style: TextStyle(fontSize: 18)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('星期,餐次,菜品,备注');
      
      for (final day in _currentMenu!.days) {
        buffer.writeln('${day.dayName},早餐,${day.breakfast.name},${day.breakfast.note}');
        buffer.writeln('${day.dayName},午餐,${day.lunch.name},${day.lunch.note}');
        buffer.writeln('${day.dayName},晚餐,${day.dinner.name},${day.dinner.note}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '菜谱_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导出到：$fileName', style: const TextStyle(fontSize: 18)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await Share.shareXFiles([XFile(file.path)], text: '菜谱文件');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e', style: const TextStyle(fontSize: 18)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateImage() async {
    if (_currentMenu == null) return;

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要存储权限才能保存图片，请在设置中开启', style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MenuImageGenerator(menu: _currentMenu!),
      );
    }
  }

  Future<void> _copyFromLastWeek() async {
    final lastWeek = await StorageService.instance.getLastWeekMenu();
    if (lastWeek == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('没有找到上周菜谱', style: TextStyle(fontSize: 20)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认复制', style: TextStyle(fontSize: 24)),
        content: const Text(
          '确定要用上周菜谱覆盖当前菜谱吗？',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentMenu != null) {
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
            content: Text('已复制上周菜谱', style: TextStyle(fontSize: 20)),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showMealEditDialog(int dayIndex, String mealType, String mealName, MealModel meal) {
    if (_currentMenu == null) return;
    
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

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择导出格式',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.text_snippet, size: 32, color: Colors.blue),
              title: const Text('文本格式', style: TextStyle(fontSize: 20)),
              subtitle: const Text('复制到剪贴板', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _copyMenuText();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, size: 32, color: Colors.green),
              title: const Text('Excel格式', style: TextStyle(fontSize: 20)),
              subtitle: const Text('导出CSV文件', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, size: 32, color: Colors.orange),
              title: const Text('图片格式', style: TextStyle(fontSize: 20)),
              subtitle: const Text('保存到相册', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _generateImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('胡老三菜谱'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 32),
            tooltip: '复制上周菜谱',
            onPressed: _copyFromLastWeek,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDayTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentMenu == null
                    ? const Center(child: Text('加载失败，请重启应用', style: TextStyle(fontSize: 20)))
                    : _buildDayContent(),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      height: 70,
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
      child: Row(
        children: List.generate(7, (index) {
          final isSelected = index == _selectedDayIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
              child: Container(
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
                  _dayNames[index],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayContent() {
    if (_currentMenu == null || _selectedDayIndex >= _currentMenu!.days.length) {
      return const Center(child: Text('数据加载中...', style: TextStyle(fontSize: 20)));
    }
    
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                        fontSize: 24,
                        color: meal.name.isEmpty ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meal.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '备注：${meal.note}',
                        style: TextStyle(
                          fontSize: 20,
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
                onPressed: _showExportOptions,
                icon: const Icon(Icons.share, size: 28),
                label: const Text('导出', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateImage,
                icon: const Icon(Icons.image, size: 28),
                label: const Text('生成图片', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
