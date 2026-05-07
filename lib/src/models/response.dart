import 'dart:convert';

import 'package:klipy_dart/src/constants/constants.dart';
import 'package:klipy_dart/src/models/models.dart';
import 'package:klipy_dart/src/http_client.dart';

/// Based on [category response object](https://developers.google.com/tenor/guides/response-objects-and-errors#category-object) from the Tenor API.
class KlipyResponse {
  static const _encoder = JsonEncoder.withIndent('  ');

  static KlipyEndpoint? _endpointFromJson(dynamic endpointValue) {
    final endpointName = endpointValue?.toString();
    if (endpointName == null) {
      return null;
    }
    for (final endpoint in KlipyEndpoint.values) {
      if (endpoint.name == endpointName) {
        return endpoint;
      }
    }
    return null;
  }

  static double _createdAtToTimestamp(dynamic createdAt) {
    if (createdAt is num) {
      return createdAt.toDouble();
    }
    if (createdAt is String) {
      final parsedNum = double.tryParse(createdAt);
      if (parsedNum != null) {
        return parsedNum;
      }
      final parsedDate = DateTime.tryParse(createdAt);
      if (parsedDate != null) {
        return parsedDate.millisecondsSinceEpoch.toDouble();
      }
    }
    return DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  static Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static Map<String, dynamic> _buildMediaObject({
    required String url,
    required int width,
    required int height,
    required int size,
  }) {
    return {
      'url': url,
      'dims': [width, height],
      'duration': 0,
      'size': size,
    };
  }

  static Map<String, dynamic> _normalizeV1Gif(Map<String, dynamic> item) {
    final file = _asStringDynamicMap(item['file']) ?? const {};
    final url = file['url']?.toString() ??
        item['url']?.toString() ??
        item['src']?.toString() ??
        '';
    final previewUrl = file['preview_url']?.toString() ??
        file['thumbnail_url']?.toString() ??
        url;
    final width = (file['width'] as num?)?.toInt() ?? 1;
    final height = (file['height'] as num?)?.toInt() ?? 1;
    final size = (file['size'] as num?)?.toInt() ?? 0;
    final slug = item['slug']?.toString() ?? item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? slug;
    final description = item['description']?.toString() ??
        item['content_description']?.toString() ??
        title;
    final tagsRaw = item['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((tag) => tag.toString()).toList()
        : <String>[];
    return {
      'id': slug,
      'created': _createdAtToTimestamp(item['created_at'] ?? item['created']),
      'hasaudio': item['hasaudio'] == true || item['has_audio'] == true,
      'media_formats': {
        KlipyMediaFormat.gif: _buildMediaObject(
          url: url,
          width: width,
          height: height,
          size: size,
        ),
        KlipyMediaFormat.tinyGif: _buildMediaObject(
          url: url,
          width: width,
          height: height,
          size: size,
        ),
        KlipyMediaFormat.preview: _buildMediaObject(
          url: previewUrl,
          width: width,
          height: height,
          size: size,
        ),
      },
      'tags': tags,
      'title': title,
      'content_description': description,
      'itemurl': item['itemurl']?.toString() ?? url,
      'hascaption': item['hascaption'] == true || item['has_caption'] == true,
      'flags': item['flags'] is List
          ? (item['flags'] as List).map((value) => value.toString()).toList()
          : <String>[],
      'bg_color': item['bg_color']?.toString(),
      'url': item['url']?.toString() ?? url,
      'source': item['source']?.toString(),
    };
  }

  static List<Map<String, dynamic>> _extractRawResults(
    Map<String, dynamic> json,
  ) {
    final direct = json['results'];
    if (direct is List) {
      return direct
          .map(_asStringDynamicMap)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    final envelope = _asStringDynamicMap(json['data']) ?? const {};
    final envelopeData = envelope['data'];
    if (envelopeData is List) {
      return envelopeData
          .map(_asStringDynamicMap)
          .whereType<Map<String, dynamic>>()
          .map((item) {
        final type = item['type']?.toString().toLowerCase();
        if (type == 'ad') {
          return {
            'type': 'ad',
            'content': item['content']?.toString() ?? '',
            'width': (item['width'] as num?)?.toInt() ?? 0,
            'height': (item['height'] as num?)?.toInt() ?? 0,
          };
        }
        return _normalizeV1Gif(item);
      }).toList();
    }
    return const [];
  }

  static String? _extractNext(Map<String, dynamic> json) {
    if (json['next'] != null) {
      return json['next']?.toString();
    }
    final envelope = _asStringDynamicMap(json['data']) ?? const {};
    final hasNext = envelope['has_next'] == true;
    if (!hasNext) {
      return '';
    }
    final currentPage = (envelope['current_page'] as num?)?.toInt() ?? 1;
    return '${currentPage + 1}';
  }

  final List<KlipyFeedItem> results;
  final KlipyAspectRatioRange aspectRatioRange;
  final KlipyEndpoint? endpoint;
  final List<String>? mediaFilter;
  final String? next;
  final String? parameters;
  final Duration timeout;
  final Map<String, String>? requestHeaders;
  final String? appKey;

  KlipyResponse({
    required this.results,
    this.aspectRatioRange = KlipyAspectRatioRange.all,
    this.endpoint,
    this.mediaFilter = const [KlipyMediaFormat.tinyGif],
    this.next,
    this.parameters,
    this.timeout = const Duration(seconds: 5),
    this.requestHeaders,
    this.appKey,
  });

  factory KlipyResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = _extractRawResults(json);
    return KlipyResponse(
      results: rawResults.map(KlipyFeedItem.fromJson).toList(),
      aspectRatioRange: KlipyAspectRatioRange.values.firstWhere(
        (value) => value.name == json['aspect_ratio_range'],
        orElse: () => KlipyAspectRatioRange.all,
      ),
      endpoint: _endpointFromJson(json['endpoint']),
      mediaFilter: (json['media_filter'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const [KlipyMediaFormat.tinyGif],
      next: _extractNext(json),
      parameters: json['parameters']?.toString(),
      timeout: json['timeout'] == null
          ? const Duration(seconds: 5)
          : Duration(microseconds: (json['timeout'] as num).toInt()),
      requestHeaders: (json['request_headers'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      appKey: json['app_key']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((result) => result.toJson()).toList(),
      'aspect_ratio_range': aspectRatioRange.name,
      'endpoint': endpoint?.name,
      'media_filter': mediaFilter,
      'next': next,
      'parameters': parameters,
      'timeout': timeout.inMicroseconds,
      'request_headers': requestHeaders,
      'app_key': appKey,
    };
  }

  // TODO look into sticker and random on fetchNext
  Future<KlipyResponse?> fetchNext({
    int limit = 1,
    KlipyHttpClient httpClient = const KlipyHttpClient(),
  }) {
    return httpClient.getGifs(
      endpoint!,
      timeout,
      parameters!,
      appKey: appKey ?? '',
      aspectRatioRange: aspectRatioRange,
      limit: limit,
      mediaFilter: mediaFilter,
      pos: next,
      headers: requestHeaders,
    );
  }

  // coverage:ignore-start
  @override
  String toString() => _encoder.convert(toJson());
  // coverage:ignore-end
}
