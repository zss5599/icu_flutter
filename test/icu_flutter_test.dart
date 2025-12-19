import 'package:flutter_test/flutter_test.dart';
import 'package:icu_flutter/icu_flutter.dart';
import 'package:icu_flutter/icu_flutter_platform_interface.dart';
import 'package:icu_flutter/icu_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIcuFlutterPlatform
    with MockPlatformInterfaceMixin
    implements IcuFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IcuFlutterPlatform initialPlatform = IcuFlutterPlatform.instance;

  test('$MethodChannelIcuFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIcuFlutter>());
  });

  test('getPlatformVersion', () async {
    IcuFlutter icuFlutterPlugin = IcuFlutter();
    MockIcuFlutterPlatform fakePlatform = MockIcuFlutterPlatform();
    IcuFlutterPlatform.instance = fakePlatform;

    expect(await icuFlutterPlugin.getPlatformVersion(), '42');
  });
}
