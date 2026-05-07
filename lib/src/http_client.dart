import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:klipy_dart/klipy_dart.dart';

/// A class for handling requests to HTTP.
///
/// Needed as a class so it is easier to test/mock.
class KlipyHttpClient {
  final http.Client? client;

  const KlipyHttpClient([
    this.client,
  ]);

  http.Client get _client => client ?? http.Client();

  String _resolveFeedEndpointPath(KlipyEndpoint endpoint, bool sticker) {
    final basePath = sticker ? 'stickers' : 'gifs';
    if (endpoint == KlipyEndpoint.featured) {
      return '$basePath/trending';
    }
    return '$basePath/search';
  }

  String _redactUri(Uri uri) {
    final segments = uri.pathSegments.toList();
    final apiIndex = segments.indexOf('api');
    if (apiIndex != -1 &&
        apiIndex + 2 < segments.length &&
        segments[apiIndex + 1] == 'v1') {
      segments[apiIndex + 2] = '***';
      return uri.replace(pathSegments: segments).toString();
    }
    return uri.toString();
  }

  void _logHttpRequest({
    required Uri uri,
    required Map<String, String>? headers,
  }) {
    final safeHeaders = <String, String>{...?headers};

    if (safeHeaders.containsKey('x-api-key')) {
      safeHeaders['x-api-key'] = '***';
    }
    if (safeHeaders.containsKey('authorization')) {
      safeHeaders['authorization'] = '***';
    }

    developer.log(
      '[KlipyHttp][request] uri=${_redactUri(uri)} headers=${jsonEncode(safeHeaders)}',
      name: 'klipy.ads',
    );
    print(
      '[klipy.ads] [KlipyHttp][request] uri=${_redactUri(uri)} headers=$safeHeaders',
    );
  }

  String _previewBody(String body) {
    if (body.length <= 300) {
      return body;
    }
    return '${body.substring(0, 300)}...';
  }

  Future<Map<String, dynamic>> request(
    String url,
    Duration timeout, {
    Map<String, String>? headers,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(klipyApiUrl + url);
      _logHttpRequest(uri: uri, headers: headers);
      late final http.Response response;
      if (method == 'POST') {
        response = await _client
            .post(
              uri,
              headers: {
                ...?headers,
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body ?? <String, dynamic>{}),
            )
            .timeout(timeout);
      } else if (method == 'DELETE') {
        response = await _client.delete(uri, headers: headers).timeout(timeout);
      } else {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      }
      if (response.statusCode != 200 && response.statusCode != 202) {
        developer.log(
          '[KlipyHttp][response] statusCode=${response.statusCode} bodyPreview="${_previewBody(response.body)}"',
          name: 'klipy.ads',
        );
        print(
          '[klipy.ads] [KlipyHttp][response] statusCode=${response.statusCode} bodyPreview="${_previewBody(response.body)}"',
        );
      }
      // get json
      final Map<String, dynamic> json = jsonDecode(response.body);

      // if an error is present, throw it
      if (json['error'] != null ||
          (response.statusCode != 200 && response.statusCode != 202)) {
        throw KlipyApiException(
          code: response.statusCode,
          message: json['errors'].toString(),
        );
      }
      // if no error, return the json for consumption
      return Future.value({
        ...json,
        // pass timeout back for fetchNext
        'timeout': timeout.inMicroseconds,
      });
    } on TimeoutException {
      throw KlipyNetworkException();
    } on http.ClientException catch (e) {
      if (e.runtimeType.toString() == '_ClientSocketException') {
        throw KlipyNetworkException();
      }
      rethrow;
    } catch (e) {
      print(e);
      // let the consumer handle it
      rethrow;
    }
  }

  /// Shared functionality between Search and Featured endpoints.
  Future<KlipyResponse?> getGifs(
    KlipyEndpoint endPoint,
    Duration timeout,
    String parameters, {
    required String appKey,
    int limit = 1,
    KlipyAspectRatioRange? aspectRatioRange,
    List<String>? mediaFilter,
    String? pos,
    bool sticker = false,
    bool random = false,
    Map<String, String>? headers,
  }) async {
    final endpointPath = _resolveFeedEndpointPath(endPoint, sticker);
    var path = '$appKey/$endpointPath$parameters';
    final separator = path.contains('?') ? '&' : '?';
    if (!path.contains('per_page=')) {
      path += '${separator}per_page=${limit.clamp(8, 50)}';
    }
    if (!path.contains('page=')) {
      final page = int.tryParse(pos ?? '1') ?? 1;
      path += '&page=${page < 1 ? 1 : page}';
    }
    if (mediaFilter != null &&
        mediaFilter.isNotEmpty &&
        !path.contains('format_filter=')) {
      path += '&format_filter=${mediaFilter.join(',')}';
    }
    if (aspectRatioRange != null && !path.contains('ar_range=')) {
      path += '&ar_range=${aspectRatioRange.name}';
    }
    if (random && !path.contains('random=')) {
      path += '&random=true';
    }

    var data = await request(path, timeout, headers: headers);
    KlipyResponse? res;
    if (data.isNotEmpty) {
      res = KlipyResponse.fromJson(
        {
          ...data,
          'endpoint': endPoint.name,
          'parameters': parameters,
          'request_headers': headers,
          'app_key': appKey,
        },
      );
    }
    return res;
  }
}
