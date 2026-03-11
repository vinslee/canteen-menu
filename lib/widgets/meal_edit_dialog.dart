import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import 'common_dishes_panel.dart';

class MealEditDialog extends StatefulWidget {
  final String title;
  final MealModel meal;
  final List<String> commonDishes;
  final Function(MealModel) onSave;
  final Function(String) onAddDish;

  const MealEditDialog({
    super.key,
    required this.title,
    required this.meal,
    required this.commonDishes,
    required this.onSave,
    required this.onAddDish,
  });

  @override
  State<MealEditDialog> createState() => _MealEditDialogState();
}

class _MealEditDialogState extends State<MealEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  bool _showDishes = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _noteController = TextEditingController(text: widget.meal.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectDish(String dish) {
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameController.text = dish;
      } else {
        _nameController.text = '${_nameController.text}、$dish';
      }
    });
  }

  void _save() {
    final meal = MealModel(
      name: _nameController.text.trim(),
      note: _noteController.text.trim(),
    );
    widget.onSave(meal);
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _nameController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '菜品名称',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        hintText: '输入菜品名称，多个用顿号分隔',
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 24),
                          onPressed: _clear,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        hintText: '可选，如：少油、清淡等',
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDishes = !_showDishes;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu, color: Colors.green, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '常用菜品库',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Icon(
                              _showDishes
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.green,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDishes) ...[
                      const SizedBox(height: 16),
                      CommonDishesPanel(
                        dishes: widget.commonDishes,
                        onSelect: _selectDish,
                        onAdd: widget.onAddDish,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clear,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text(
                              '清空',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '保存',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
