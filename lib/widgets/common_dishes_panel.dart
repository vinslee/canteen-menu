import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class CommonDishesPanel extends StatefulWidget {
  final List<String> dishes;
  final Function(String) onSelect;
  final Function(String) onAdd;
  final Function(String)? onRemove;

  const CommonDishesPanel({
    super.key,
    required this.dishes,
    required this.onSelect,
    required this.onAdd,
    this.onRemove,
  });

  @override
  State<CommonDishesPanel> createState() => _CommonDishesPanelState();
}

class _CommonDishesPanelState extends State<CommonDishesPanel> {
  final TextEditingController _newDishController = TextEditingController();
  String _searchText = '';
  String? _deletingDish;

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
    if (_deletingDish != null) return;
    
    setState(() {
      _deletingDish = dish;
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除菜品', style: TextStyle(fontSize: 24)),
        content: Text('确定要删除"$dish"吗？', style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.removeCommonDish(dish);
      if (widget.onRemove != null) {
        widget.onRemove!(dish);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除"$dish"', style: const TextStyle(fontSize: 18)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    setState(() {
      _deletingDish = null;
    });
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
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: '搜索菜品',
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 28),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: filteredDishes.length,
              itemBuilder: (context, index) {
                final dish = filteredDishes[index];
                final isDeleting = _deletingDish == dish;
                
                return GestureDetector(
                  onTap: isDeleting ? null : () => widget.onSelect(dish),
                  onLongPress: isDeleting ? null : () => _removeDish(dish),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDeleting ? Colors.red.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDeleting ? Colors.red : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu, 
                          color: isDeleting ? Colors.red : Colors.green[600], 
                          size: 24
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dish,
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w500,
                              color: isDeleting ? Colors.red : Colors.black87,
                            ),
                          ),
                        ),
                        if (isDeleting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.delete_outline, 
                            color: Colors.grey[400], 
                            size: 24
                          ),
                      ],
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
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '添加新菜品',
                      hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('添加', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Text(
              '提示：点击添加菜品，长按可删除',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
