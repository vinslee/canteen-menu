import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/menu_model.dart';

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
  
  static const double _a4Width = 2480.0;
  static const double _a4Height = 3508.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: '本周菜谱');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
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
                      '菜谱预览',
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
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  labelText: '菜谱标题',
                  labelStyle: const TextStyle(fontSize: 18),
                  hintText: '请输入菜谱标题',
                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _titleController.clear(),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    width: _a4Width,
                    height: _a4Height,
                    color: Colors.white,
                    padding: const EdgeInsets.all(80),
                    child: _buildMenuContent(),
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

  Widget _buildMenuContent() {
    final title = _titleController.text.trim().isEmpty 
        ? '本周菜谱' 
        : _titleController.text.trim();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              '【$title】',
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
        ...widget.menu.days.map((day) => _buildDayCard(day)),
      ],
    );
  }

  Widget _buildDayCard(DayMenuModel day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4CAF50), width: 4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                day.dayName,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                _buildMealRow('早餐', day.breakfast),
                const Divider(height: 40, color: Colors.grey, thickness: 2),
                _buildMealRow('午餐', day.lunch),
                const Divider(height: 40, color: Colors.grey, thickness: 2),
                _buildMealRow('晚餐', day.dinner),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealRow(String title, MealModel meal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name.isEmpty ? '待定' : meal.name,
                style: TextStyle(
                  fontSize: 56,
                  color: meal.name.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),
              if (meal.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '（${meal.note}）',
                    style: TextStyle(
                      fontSize: 44,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
