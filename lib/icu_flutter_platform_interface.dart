import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'icu_flutter_method_channel.dart';

abstract class IcuFlutterPlatform extends PlatformInterface {
  /// Constructs a IcuFlutterPlatform.
  IcuFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static IcuFlutterPlatform _instance = MethodChannelIcuFlutter();

  /// The default instance of [IcuFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelIcuFlutter].
  static IcuFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IcuFlutterPlatform] when
  /// they register themselves.
  static set instance(IcuFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
