import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class ICUConverter {
  static final ICUConverter _instance = ICUConverter._internal();
  factory ICUConverter() => _instance;
  ICUConverter._internal();

  static DynamicLibrary? _dylib;

  static DynamicLibrary _getLibrary() {
    if (_dylib != null) return _dylib!;
    
    if (Platform.isAndroid) {
      _dylib = DynamicLibrary.open('libflutter_icu.so');
    } else if (Platform.isIOS) {
      // 对于iOS，优先尝试从进程加载，如果失败则尝试打开库文件
      try {
        _dylib = DynamicLibrary.process();
      } catch (e) {
        print('Failed to load library from process: $e');
        rethrow;
      }
    } else {
      _dylib = DynamicLibrary.process();
    }
    
    return _dylib!;
  }

  static final DynamicLibrary _dylibInstance = _getLibrary();

  late final _ConvertPngToLvglDart _convertPngToLvgl = _dylibInstance
      .lookup<NativeFunction<_ConvertPngToLvglC>>('convert_png_to_lvgl')
      .asFunction<_ConvertPngToLvglDart>();

  late final _ConvertLvglToPngDart _convertLvglToPng = _dylibInstance
      .lookup<NativeFunction<_ConvertLvglToPngC>>('convert_lvgl_to_png')
      .asFunction<_ConvertLvglToPngDart>();

  late final _FreeConvertedDataDart _freeConvertedData = _dylibInstance
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