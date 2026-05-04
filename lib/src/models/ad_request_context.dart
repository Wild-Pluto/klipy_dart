class KlipyAdRequestContext {
  final String customerId;
  final int adMinWidth;
  final int adMaxWidth;
  final int adMinHeight;
  final int adMaxHeight;
  final String? adAppVersion;
  final String? adOs;
  final String? adOsVersion;
  final String? adModel;
  final String? adLanguage;
  final String? adNetwork;
  final int? adDeviceWidth;
  final int? adDeviceHeight;
  final double? adPxRatio;
  final String? adIfa;
  final String? adPosition;
  final bool? adIframe;

  const KlipyAdRequestContext({
    required this.customerId,
    required this.adMinWidth,
    required this.adMaxWidth,
    required this.adMinHeight,
    required this.adMaxHeight,
    this.adAppVersion,
    this.adOs,
    this.adOsVersion,
    this.adModel,
    this.adLanguage,
    this.adNetwork,
    this.adDeviceWidth,
    this.adDeviceHeight,
    this.adPxRatio,
    this.adIfa,
    this.adPosition = '0',
    this.adIframe = true,
  });

  Map<String, dynamic> toQueryParameters() {
    final iframeValue = adIframe == null ? null : (adIframe! ? 1 : 0);
    return {
      'customer_id': customerId,
      'ad-min-width': adMinWidth,
      'ad-max-width': adMaxWidth,
      'ad-min-height': adMinHeight,
      'ad-max-height': adMaxHeight,
      'ad-app-version': adAppVersion,
      'ad-os': adOs,
      'ad-osv': adOsVersion,
      'ad-model': adModel,
      'ad-language': adLanguage,
      'ad-network': adNetwork,
      'ad-device-w': adDeviceWidth,
      'ad-device-h': adDeviceHeight,
      'ad-pxratio': adPxRatio,
      'ad-ifa': adIfa,
      'ad-position': adPosition,
      'ad-iframe': iframeValue,
    };
  }
}
