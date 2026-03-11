# 食堂菜谱管理应用

一个专为学校食堂阿姨设计的菜谱管理安卓应用。

## 功能特点

- ✅ 无需登录、无联网、无广告
- ✅ 显示周一到周日，每天早中晚三餐
- ✅ 可编辑菜名与备注
- ✅ 常用菜品库，点选快速填入
- ✅ 一键复制全文菜谱文本
- ✅ 一键生成发群图片，保存到相册
- ✅ 可复制上周菜谱快速复用
- ✅ 本地存储，打开即用
- ✅ 界面大字简洁、长辈易用

## 构建APK步骤

### 1. 安装Flutter环境

如果还没有安装Flutter，请先安装：

1. 下载Flutter SDK: https://docs.flutter.dev/get-started/install
2. 解压到任意目录（如 `C:\flutter`）
3. 添加Flutter到系统环境变量PATH
4. 运行 `flutter doctor` 检查环境

### 2. 配置项目

在项目根目录创建 `local.properties` 文件：

```properties
sdk.dir=C:\\Users\\你的用户名\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\flutter
```

### 3. 获取依赖

```bash
cd canteen_menu
flutter pub get
```

### 4. 构建APK

```bash
flutter build apk --release
```

构建完成后，APK文件位于：
`build/app/outputs/flutter-apk/app-release.apk`

### 5. 安装到手机

将APK文件传输到安卓手机，点击安装即可使用。

## 项目结构

```
canteen_menu/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/
│   │   └── menu_model.dart       # 数据模型
│   ├── services/
│   │   └── storage_service.dart  # 本地存储服务
│   ├── screens/
│   │   └── home_screen.dart      # 主界面
│   └── widgets/
│       ├── meal_edit_dialog.dart      # 编辑菜品对话框
│       ├── common_dishes_panel.dart   # 常用菜品库面板
│       └── menu_image_generator.dart  # 图片生成器
├── android/                      # Android配置
├── ios/                          # iOS配置
└── pubspec.yaml                  # 依赖配置
```

## 使用说明

1. **查看/编辑菜谱**：点击顶部的星期标签切换日期，点击三餐卡片编辑菜品
2. **常用菜品库**：在编辑界面展开菜品库，点击快速填入，长按可删除
3. **复制文本**：点击底部"复制文本"按钮，菜谱内容将复制到剪贴板
4. **生成图片**：点击"生成图片"按钮，预览后可保存到相册
5. **复制上周菜谱**：点击右上角历史按钮，可快速复制上周菜谱

## 技术栈

- Flutter 3.x
- SharedPreferences（本地存储）
- screenshot + image_gallery_saver（图片生成保存）
