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

  final List<KlipyFeedItem> results;
  final KlipyAspectRatioRange aspectRatioRange;
  final KlipyEndpoint? endpoint;
  final List<String>? mediaFilter;
  final String? next;
  final String? parameters;
  final Duration timeout;
  final Map<String, String>? requestHeaders;

  KlipyResponse({
    required this.results,
    this.aspectRatioRange = KlipyAspectRatioRange.all,
    this.endpoint,
    this.mediaFilter = const [KlipyMediaFormat.tinyGif],
    this.next,
    this.parameters,
    this.timeout = const Duration(seconds: 5),
    this.requestHeaders,
  });

  factory KlipyResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = (json['results'] as List<dynamic>? ?? const []);
    return KlipyResponse(
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map(KlipyFeedItem.fromJson)
          .toList(),
      aspectRatioRange: KlipyAspectRatioRange.values.firstWhere(
        (value) => value.name == json['aspect_ratio_range'],
        orElse: () => KlipyAspectRatioRange.all,
      ),
      endpoint: _endpointFromJson(json['endpoint']),
      mediaFilter: (json['media_filter'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const [KlipyMediaFormat.tinyGif],
      next: json['next']?.toString(),
      parameters: json['parameters']?.toString(),
      timeout: json['timeout'] == null
          ? const Duration(seconds: 5)
          : Duration(microseconds: (json['timeout'] as num).toInt()),
      requestHeaders: (json['request_headers'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
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
