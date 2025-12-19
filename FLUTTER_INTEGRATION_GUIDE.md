# Flutter 项目集成指南

这份文档将指导您如何在 Flutter 项目中集成和使用 flutter_icu 库。

## 前置条件

1. 确保您已经构建了 iOS 和 Android 平台的库文件
2. 准备好一个 Flutter 项目

## 集成步骤

### 1. 复制库文件到 Flutter 项目

首先，将已编译的库文件复制到您的 Flutter 项目中：

#### 对于 Android:
```bash
# 从您的 icu 项目根目录
mkdir -p /path/to/your/flutter/project/android/app/src/main/jniLibs/arm64-v8a
cp jniLibs/arm64-v8a/libflutter_icu.so /path/to/your/flutter/project/android/app/src/main/jniLibs/arm64-v8a/
```

#### 对于 iOS:
```bash
# 复制 dylib 文件到您的 Flutter 项目
cp target/aarch64-apple-ios/release/libflutter_icu.dylib /path/to/your/flutter/project/ios/
```

在您的案例中，路径应该是：
```bash
# Android
mkdir -p /Users/macbook/StudioProjects/icu_flutter/android/app/src/main/jniLibs/arm64-v8a
cp /Users/macbook/development/icu/icu/jniLibs/arm64-v8a/libflutter_icu.so /Users/macbook/StudioProjects/icu_flutter/android/app/src/main/jniLibs/arm64-v8a/

# iOS
cp /Users/macbook/development/icu/icu/target/aarch64-apple-ios/release/libflutter_icu.dylib /Users/macbook/StudioProjects/icu_flutter/
```

### 2. 更新您的 Flutter 项目

#### Android 配置

Android 不需要额外配置。当您构建应用程序时，库会自动包含进去。

#### iOS 配置

将以下内容添加到您的 Flutter 项目的 `ios/Podfile` 中：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # 为 flutter_icu 添加这部分配置
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

另外，您需要将库添加到您的 Xcode 项目中：
1. 在 Xcode 中打开您的 Flutter 项目
2. 右键点击 Runner 文件夹并选择 "Add Files to Runner..."
3. 选择您之前复制的 `libflutter_icu.dylib` 文件
4. 确保勾选 "Copy items if needed" 并将其添加到 Runner 目标中

### 3. 创建 Dart 绑定

在您的 Flutter 项目中创建一个新的 Dart 文件，例如 `lib/icu_converter.dart`：

```dart
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class ICUConverter {
  static final ICUConverter _instance = ICUConverter._internal();
  factory ICUConverter() => _instance;
  ICUConverter._internal();

  static final DynamicLibrary _dylib = Platform.isAndroid
      ? DynamicLibrary.open('libflutter_icu.so')
      : DynamicLibrary.process();

  late final _ConvertPngToLvgl _convertPngToLvgl = _dylib
      .lookup<NativeFunction<_ConvertPngToLvglC>>('convert_png_to_lvgl')
      .asFunction<_ConvertPngToLvglDart>();

  late final _ConvertLvglToPng _convertLvglToPng = _dylib
      .lookup<NativeFunction<_ConvertLvglToPngC>>('convert_lvgl_to_png')
      .asFunction<_ConvertLvglToPngDart>();

  late final _FreeConvertedData _freeConvertedData = _dylib
      .lookup<NativeFunction<_FreeConvertedDataC>>('free_converted_data')
      .asFunction<_FreeConvertedDataDart>();

  /// 将 PNG 数据转换为 LVGL 格式
  ///
  /// [pngData] - PNG 图像数据
  /// [colorFormat] - 所需的 LVGL 颜色格式 (默认: I8)
  /// [strideAlign] - 步长对齐 (默认: 1)
  ///
  /// 返回转换后的 LVGL 数据，失败则返回 null
  Uint8List? convertPngToLvgl(
    Uint8List pngData, {
    int colorFormat = 0x0A, // I8
    int strideAlign = 1,
  }) {
    final pngDataPtr = malloc<Uint8>(pngData.length);
    final pngDataBuffer = pngDataPtr.asTypedList(pngData.length);
    pngDataBuffer.setAll(0, pngData);

    final outputPtr = malloc<Pointer<Uint8>>();
    final outputLen = malloc<Uint32>();

    try {
      final result = _convertPngToLvgl(
        pngDataPtr,
        pngData.length,
        outputPtr,
        outputLen,
        colorFormat,
        strideAlign,
      );

      if (result == 0) {
        final lvglDataLength = outputLen.value;
        final lvglData = outputPtr.value.asTypedList(lvglDataLength);
        return Uint8List.fromList(lvglData);
      } else {
        print('转换失败，错误代码: $result');
        return null;
      }
    } finally {
      malloc.free(pngDataPtr);
      if (outputPtr.value != nullptr) {
        _freeConvertedData(outputPtr.value, outputLen.value);
      }
      malloc.free(outputPtr);
      malloc.free(outputLen);
    }
  }

  /// 将 LVGL 数据转换为 PNG 格式
  ///
  /// [lvglData] - LVGL 图像数据
  ///
  /// 返回转换后的 PNG 数据，失败则返回 null
  Uint8List? convertLvglToPng(Uint8List lvglData) {
    final lvglDataPtr = malloc<Uint8>(lvglData.length);
    final lvglDataBuffer = lvglDataPtr.asTypedList(lvglData.length);
    lvglDataBuffer.setAll(0, lvglData);

    final outputPtr = malloc<Pointer<Uint8>>();
    final outputLen = malloc<Uint32>();

    try {
      final result = _convertLvglToPng(
        lvglDataPtr,
        lvglData.length,
        outputPtr,
        outputLen,
      );

      if (result == 0) {
        final pngDataLength = outputLen.value;
        final pngData = outputPtr.value.asTypedList(pngDataLength);
        return Uint8List.fromList(pngData);
      } else {
        print('转换失败，错误代码: $result');
        return null;
      }
    } finally {
      malloc.free(lvglDataPtr);
      if (outputPtr.value != nullptr) {
        _freeConvertedData(outputPtr.value, outputLen.value);
      }
      malloc.free(outputPtr);
      malloc.free(outputLen);
    }
  }
}

// 函数签名类型定义
typedef _ConvertPngToLvglC = Int32 Function(
  Pointer<Uint8> pngDataPtr,
  Uint32 pngDataLen,
  Pointer<Pointer<Uint8>> outputPtr,
  Pointer<Uint32> outputLen,
  Uint32 colorFormat,
  Uint32 strideAlign,
);

typedef _ConvertPngToLvglDart = int Function(
  Pointer<Uint8> pngDataPtr,
  int pngDataLen,
  Pointer<Pointer<Uint8>> outputPtr,
  Pointer<Uint32> outputLen,
  int colorFormat,
  int strideAlign,
);

typedef _ConvertLvglToPngC = Int32 Function(
  Pointer<Uint8> lvglDataPtr,
  Uint32 lvglDataLen,
  Pointer<Pointer<Uint8>> outputPtr,
  Pointer<Uint32> outputLen,
);

typedef _ConvertLvglToPngDart = int Function(
  Pointer<Uint8> lvglDataPtr,
  int lvglDataLen,
  Pointer<Pointer<Uint8>> outputPtr,
  Pointer<Uint32> outputLen,
);

typedef _FreeConvertedDataC = Void Function(
  Pointer<Uint8> ptr,
  Uint32 len,
);

typedef _FreeConvertedDataDart = void Function(
  Pointer<Uint8> ptr,
  int len,
);
```

### 4. 使用示例

现在您可以在 Flutter 应用程序中使用转换器：

```dart
import 'package:your_app/icu_converter.dart';

class ImageConverterWidget extends StatefulWidget {
  @override
  _ImageConverterWidgetState createState() => _ImageConverterWidgetState();
}

class _ImageConverterWidgetState extends State<ImageConverterWidget> {
  final ICUConverter _converter = ICUConverter();
  
  void _convertPngToLvgl() async {
    // 以某种方式加载您的 PNG 数据（从资源、文件、网络等）
    final pngBytes = await rootBundle.load('assets/sample.png');
    final pngData = Uint8List.view(pngBytes.buffer);
    
    final lvglData = _converter.convertPngToLvgl(pngData, colorFormat: 0x0A);
    if (lvglData != null) {
      print('成功将 PNG 转换为 LVGL: ${lvglData.length} 字节');
      // 根据需要使用 lvglData
    } else {
      print('PNG 转 LVGL 失败');
    }
  }
  
  void _convertLvglToPng() async {
    // 您需要从某处获取 LVGL 数据
    // final lvglData = ...;
    
    final pngData = _converter.convertLvglToPng(lvglData);
    if (pngData != null) {
      print('成功将 LVGL 转换为 PNG: ${pngData.length} 字节');
      // 根据需要使用 pngData，例如在 Image 控件中显示
    } else {
      print('LVGL 转 PNG 失败');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _convertPngToLvgl,
          child: Text('将 PNG 转换为 LVGL'),
        ),
        ElevatedButton(
          onPressed: _convertLvglToPng,
          child: Text('将 LVGL 转换为 PNG'),
        ),
      ],
    );
  }
}
```

## 故障排除

### 常见问题

1. **Android 上找不到库**: 确保您已将 jniLibs 文件夹复制到 Android 项目中的正确位置。

2. **iOS 上找不到库**: 检查您是否已将 dylib 文件添加到 Xcode 项目中，并且它已包含在 "Copy Bundle Resources" 构建阶段中。

3. **符号未找到错误**: 确保您在 Dart FFI 绑定中使用了正确的函数名称。它们应该与 Rust 库中导出的 C 函数完全匹配。

4. **iOS 上崩溃**: 确保在您的 iOS 构建设置中禁用了 bitcode。

### 测试您的集成

您可以创建一个简单测试来验证库是否正常工作：

```dart
void testICUIntegration() {
  final converter = ICUConverter();
  
  // 测试数据 - 一个简单的 1x1 白色像素 PNG
  final testPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG 头部
    0x00, 0x00, 0x00, 0x0D, // IHDR 块长度
    0x49, 0x48, 0x44, 0x52, // IHDR 块类型
    0x00, 0x00, 0x00, 0x01, // 宽度: 1
    0x00, 0x00, 0x00, 0x01, // 高度: 1
    0x08, 0x06, 0x00, 0x00, 0x00, // 位深度、颜色类型、压缩、过滤、隔行扫描
    0x1F, 0x15, 0xC4, 0x89, // IHDR CRC
    0x00, 0x00, 0x00, 0x0A, // IDAT 块长度
    0x49, 0x44, 0x41, 0x54, // IDAT 块类型
    0x78, 0xDA, 0x63, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x02, // 压缩数据
    0x2D, 0xB0, 0x01, 0x62, // IDAT CRC
    0x00, 0x00, 0x00, 0x00, // IEND 块长度
    0x49, 0x45, 0x4E, 0x44, // IEND 块类型
    0xAE, 0x42, 0x60, 0x82, // IEND CRC
  ]);
  
  final lvglData = converter.convertPngToLvgl(testPng, colorFormat: 0x0A);
  if (lvglData != null) {
    print('✓ 成功将测试 PNG 转换为 LVGL');
    
    final backToPng = converter.convertLvglToPng(lvglData);
    if (backToPng != null) {
      print('✓ 成功将 LVGL 转换回 PNG');
    } else {
      print('✗ 未能将 LVGL 转换回 PNG');
    }
  } else {
    print('✗ 未能将测试 PNG 转换为 LVGL');
  }
}
```

这样就完成了在 Flutter 应用程序中使用 flutter_icu 库的集成指南。