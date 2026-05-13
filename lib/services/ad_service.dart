import 'dart:io';

import 'package:flutter/foundation.dart';

class AdService {
  const AdService._();

  static const String bannerAdEnabledRemoteConfigKey = 'banner_ad_enabled';
  static const String showBannerOnSettingsOnlyRemoteConfigKey =
      'show_banner_on_settings_only';

  static const bool bannerAdEnabled = false;
  static const bool showBannerOnSettingsOnly = true;

  static const String androidBannerAdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String iosBannerAdUnitId =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

  static const String _debugAndroidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _debugIosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static String? get bannerAdUnitId {
    if (!bannerAdEnabled || !showBannerOnSettingsOnly || !isSupported) {
      return null;
    }

    if (kDebugMode) {
      return Platform.isAndroid
          ? _debugAndroidBannerAdUnitId
          : _debugIosBannerAdUnitId;
    }

    return Platform.isAndroid ? androidBannerAdUnitId : iosBannerAdUnitId;
  }
}
