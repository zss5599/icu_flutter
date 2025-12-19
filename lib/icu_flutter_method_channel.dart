import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'icu_flutter_platform_interface.dart';

/// An implementation of [IcuFlutterPlatform] that uses method channels.
class MethodChannelIcuFlutter extends IcuFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('icu_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
