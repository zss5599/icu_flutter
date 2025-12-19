
import 'icu_flutter_platform_interface.dart';

class IcuFlutter {
  Future<String?> getPlatformVersion() {
    return IcuFlutterPlatform.instance.getPlatformVersion();
  }
}
