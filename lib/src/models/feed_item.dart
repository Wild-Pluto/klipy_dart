import 'package:klipy_dart/src/models/result_object.dart';

abstract class KlipyFeedItem {
  final String type;

  const KlipyFeedItem({required this.type});

  Map<String, dynamic> toJson();

  factory KlipyFeedItem.fromJson(Map<String, dynamic> json) {
    final itemType = json['type']?.toString().toLowerCase();
    if (itemType == 'ad') {
      return KlipyAdFeedItem.fromJson(json);
    }

    if (json['id'] != null && json['media_formats'] != null) {
      return KlipyGifFeedItem.fromJson(json);
    }

    return KlipyUnknownFeedItem.fromJson(json);
  }
}

class KlipyGifFeedItem extends KlipyFeedItem {
  final KlipyResultObject result;

  const KlipyGifFeedItem({required this.result}) : super(type: 'gif');

  factory KlipyGifFeedItem.fromJson(Map<String, dynamic> json) {
    return KlipyGifFeedItem(
      result: KlipyResultObject.fromJson(json),
    );
  }

  @override
  Map<String, dynamic> toJson() => result.toJson();
}

class KlipyAdFeedItem extends KlipyFeedItem {
  final String content;
  final int width;
  final int height;

  const KlipyAdFeedItem({
    required this.content,
    required this.width,
    required this.height,
  }) : super(type: 'ad');

  factory KlipyAdFeedItem.fromJson(Map<String, dynamic> json) {
    return KlipyAdFeedItem(
      content: json['content']?.toString() ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'width': width,
        'height': height,
      };
}

class KlipyUnknownFeedItem extends KlipyFeedItem {
  final Map<String, dynamic> payload;

  const KlipyUnknownFeedItem({
    required this.payload,
    required String rawType,
  }) : super(type: rawType);

  factory KlipyUnknownFeedItem.fromJson(Map<String, dynamic> json) {
    return KlipyUnknownFeedItem(
      payload: json,
      rawType: json['type']?.toString() ?? 'unknown',
    );
  }

  @override
  Map<String, dynamic> toJson() => payload;
}
