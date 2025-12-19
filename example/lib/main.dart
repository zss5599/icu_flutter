import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:icu_flutter/icu_converter.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _icuConverter = ICUConverter();
  String _conversionResult = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _convertAndSaveImage() async {
    try {
      // 获取应用文档目录
      String directory ="";
      if(Platform.isAndroid){
        directory  = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);

      }

      if(Platform.isIOS){
       var a =await getApplicationDocumentsDirectory();
       directory = a.path;
      }
      // 从assets读取img_0.png文件
      final ByteData imageData = await rootBundle.load('assets/images/img_0.png');
      final pngData = Uint8List.view(imageData.buffer);

      // 转换PNG到LVGL
      final lvglData = _icuConverter.convertPngToLvgl(pngData, colorFormat: 0x0A);

      if (lvglData != null) {
        // 保存LVGL数据到文件
        final lvglFile = File('${directory.toString()}/converted_image.lvgl');
        await lvglFile.writeAsBytes(lvglData);

        setState(() {
          _conversionResult = 'Success! File saved to: ${lvglFile.path}';
        });

        final pngData = _icuConverter.convertLvglToPng(lvglData);

        final pngFile = File('${directory.toString()}/converted_image.png');
        // 保存LVGL数据到文件
        if(pngData != null){

          await pngFile.writeAsBytes(pngData);
          setState(() {
            _conversionResult = '$_conversionResult \n\nSuccess! PNG file saved to: ${pngFile.path}';
          });
        }

        if(Platform.isIOS){
          await Share.shareXFiles(
            [XFile(lvglFile.path), XFile(pngFile.path)], // 传入临时文件
            subject: 'save file', // 主题（可选）
            text: 'Please select where to save the file.', // 说明文字（可选）
          );
        }
      } else {
        setState(() {
          _conversionResult = 'Error: Conversion failed';
        });


      }
    } catch (e) {
      setState(() {
        _conversionResult = 'Error: $e';
      });
      print (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                onPressed: _convertAndSaveImage,
                child: const Text('Convert PNG to LVGL and Save'),
              ),
              const SizedBox(height: 20),
              Text(_conversionResult),
            ],
          ),
        ),
      ),
    );
  }
}