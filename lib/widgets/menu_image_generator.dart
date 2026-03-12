import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/menu_model.dart';

/// 菜谱图片生成器组件 - 宽幅排版模式
/// 采用16:9宽幅比例，7天菜谱横向网格布局
class MenuImageGenerator extends StatefulWidget {
  final WeekMenuModel menu;

  const MenuImageGenerator({super.key, required this.menu});

  @override
  State<MenuImageGenerator> createState() => _MenuImageGeneratorState();
}

class _MenuImageGeneratorState extends State<MenuImageGenerator> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  String? _message;
  late TextEditingController _titleController;
  String _menuTitle = '本周菜谱';

  /// 宽幅图片尺寸配置 (16:9比例)
  static const double _imageWidth = 1280.0;
  static const double _imageHeight = 720.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _menuTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// 保存图片到相册
  Future<void> _saveImage() async {
    setState(() {
      _isSaving = true;
      _message = '正在生成图片...';
    });

    try {
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
        setState(() {
          _message = '需要存储权限才能保存图片，请在设置中开启权限';
          _isSaving = false;
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        setState(() {
          _message = '生成图片失败';
          _isSaving = false;
        });
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final result = await ImageGallerySaver.saveImage(
        buffer,
        quality: 100,
        name: '菜谱_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        setState(() {
          _message = '图片已保存到相册！';
          _isSaving = false;
        });
      } else {
        setState(() {
          _message = '保存失败，请重试';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = '保存出错：$e';
        _isSaving = false;
      });
    }
  }

  /// 更新菜谱标题
  void _updateTitle() {
    setState(() {
      _menuTitle = _titleController.text.trim().isEmpty
          ? '本周菜谱'
          : _titleController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '菜谱预览（宽幅模式）',
                      style: TextStyle(
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('菜谱标题：', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: '输入菜谱标题',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          onPressed: _updateTitle,
                        ),
                      ),
                      onSubmitted: (_) => _updateTitle(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    color: Colors.white,
                    width: _imageWidth,
                    height: _imageHeight,
                    padding: const EdgeInsets.all(20),
                    child: _buildWideMenuContent(),
                  ),
                ),
              ),
            ),
            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: _message!.contains('成功') || _message!.contains('已保存')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: _message!.contains('成功') || _message!.contains('已保存')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('关闭', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveImage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存到相册', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建宽幅菜谱内容 - 横向网格布局
  Widget _buildWideMenuContent() {
    return Column(
      children: [
        _buildTitle(),
        const SizedBox(height: 12),
        Expanded(
          child: _buildDaysGrid(),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '【$_menuTitle】',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  /// 构建7天网格布局 - 第一行4天，第二行3天
  Widget _buildDaysGrid() {
    final days = widget.menu.days;
    final firstRowDays = days.take(4).toList();
    final secondRowDays = days.skip(4).toList();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: firstRowDays.map((day) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDayCard(day),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              ...secondRowDays.map((day) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDayCard(day),
                ),
              )).toList(),
              Expanded(
                flex: secondRowDays.length == 3 ? 0 : 1,
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建单天卡片
  Widget _buildDayCard(DayMenuModel day) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Center(
              child: Text(
                day.dayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMealItem('早', day.breakfast),
                  _buildMealItem('午', day.lunch),
                  _buildMealItem('晚', day.dinner),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建餐次项目 - 紧凑横向布局
  Widget _buildMealItem(String title, MealModel meal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name.isEmpty ? '待定' : meal.name,
                style: TextStyle(
                  fontSize: 13,
                  color: meal.name.isEmpty ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (meal.note.isNotEmpty)
                Text(
                  '(${meal.note})',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
