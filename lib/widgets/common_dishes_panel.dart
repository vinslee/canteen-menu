import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class CommonDishesPanel extends StatefulWidget {
  final List<String> dishes;
  final Function(String) onSelect;
  final Function(String) onAdd;

  const CommonDishesPanel({
    super.key,
    required this.dishes,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  State<CommonDishesPanel> createState() => _CommonDishesPanelState();
}

class _CommonDishesPanelState extends State<CommonDishesPanel> {
  final TextEditingController _newDishController = TextEditingController();
  String _searchText = '';

  List<String> get _filteredDishes {
    if (_searchText.isEmpty) return widget.dishes;
    return widget.dishes
        .where((d) => d.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  void _addNewDish() {
    final dish = _newDishController.text.trim();
    if (dish.isEmpty) return;

    widget.onAdd(dish);
    _newDishController.clear();
    setState(() {});
  }

  Future<void> _removeDish(String dish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除菜品', style: TextStyle(fontSize: 22)),
        content: Text('确定要删除"$dish"吗？', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.removeCommonDish(dish);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _newDishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDishes = _filteredDishes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: '搜索菜品',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 24),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: filteredDishes.length,
              itemBuilder: (context, index) {
                final dish = filteredDishes[index];
                return GestureDetector(
                  onTap: () => widget.onSelect(dish),
                  onLongPress: () => _removeDish(dish),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      dish,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newDishController,
                    decoration: InputDecoration(
                      hintText: '添加新菜品',
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addNewDish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('添加', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Text(
              '提示：点击选择菜品，长按可删除',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
