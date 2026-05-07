import 'package:klipy_dart/klipy_dart.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

void main() {
  final testAspectRatioRange = KlipyAspectRatioRange.standard;
  final testEndpoint = KlipyEndpoint.categories;
  final testMediaFilter = [KlipyMediaFormat.gif];
  final testNext = '123456';
  final testParameters = 'apiKey=1234&country=US&locale=en_US';
  final testResults = <KlipyFeedItem>[];
  final testDuration = const Duration(seconds: 10);

  setUpAll(() {
    registerFallbackValue(testEndpoint);
    registerFallbackValue(testDuration);
    registerFallbackValue(testParameters);
  });

  group('KlipyResponse >', () {
    test('.fetchNext()', () {
      final mockHttpClient = MockKlipyHttpClient();
      final response = KlipyResponse(
        aspectRatioRange: testAspectRatioRange,
        endpoint: testEndpoint,
        mediaFilter: testMediaFilter,
        next: testNext,
        parameters: testParameters,
        results: testResults,
        timeout: testDuration,
      );

      // stub getGifs
      when(
        () => mockHttpClient.getGifs(
          any(),
          any(),
          any(),
          appKey: any(named: 'appKey'),
          aspectRatioRange: any(named: 'aspectRatioRange'),
          limit: any(named: 'limit'),
          mediaFilter: any(named: 'mediaFilter'),
          pos: any(named: 'pos'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async {
        return response;
      });

      // call fetchNext
      response.fetchNext(limit: 2, httpClient: mockHttpClient);

      // verify getGifs was called
      verify(
        () => (mockHttpClient.getGifs(
          any(),
          any(),
          any(),
          appKey: any(named: 'appKey'),
          aspectRatioRange: any(named: 'aspectRatioRange'),
          limit: any(named: 'limit'),
          mediaFilter: any(named: 'mediaFilter'),
          pos: any(named: 'pos'),
          headers: any(named: 'headers'),
        )),
      ).called(1);
    });

    test('.fromJson()', () {
      final json = {
        'aspect_ratio_range': testAspectRatioRange.name,
        'endpoint': testEndpoint.name,
        'media_filter': testMediaFilter,
        'next': testNext,
        'parameters': testParameters,
        'results': testResults,
        'timeout': testDuration.inMicroseconds,
      };
      final response = KlipyResponse.fromJson(json);
      expect(response.aspectRatioRange, testAspectRatioRange);
      expect(response.endpoint, testEndpoint);
      expect(response.mediaFilter, testMediaFilter);
      expect(response.next, testNext);
      expect(response.parameters, testParameters);
      expect(response.results, testResults);
      expect(response.timeout, testDuration);
    });

    test('.toJson()', () {
      final category = KlipyResponse(
        aspectRatioRange: testAspectRatioRange,
        endpoint: testEndpoint,
        mediaFilter: testMediaFilter,
        next: testNext,
        parameters: testParameters,
        results: testResults,
        timeout: testDuration,
      );
      final json = category.toJson();

      expect(json, {
        'aspect_ratio_range': testAspectRatioRange.name,
        'endpoint': testEndpoint.name,
        'media_filter': testMediaFilter,
        'next': testNext,
        'parameters': testParameters,
        'results': testResults,
        'timeout': testDuration.inMicroseconds,
        'request_headers': null,
        'app_key': null,
      });
    });

    test('parses mixed gif/ad/unknown feed items', () {
      final response = KlipyResponse.fromJson({
        'results': [
          {
            'id': 'gif-1',
            'created': DateTime.now().millisecondsSinceEpoch.toDouble(),
            'hasaudio': false,
            'media_formats': {
              'gif': {
                'url': 'https://example.com/gif.gif',
                'dims': [100, 100],
                'duration': 1.0,
                'size': 10,
              },
            },
            'tags': const [],
            'title': 'gif',
            'content_description': 'gif',
            'itemurl': 'https://example.com/item',
            'hascaption': false,
            'flags': const [],
            'url': 'https://example.com',
          },
          {
            'type': 'ad',
            'content': '<html>ad</html>',
            'width': 320,
            'height': 50,
          },
          {
            'type': 'mystery',
            'value': true,
          },
        ],
      });

      expect(response.results.length, 3);
      expect(response.results[0], isA<KlipyGifFeedItem>());
      expect(response.results[1], isA<KlipyAdFeedItem>());
      expect(response.results[2], isA<KlipyUnknownFeedItem>());
    });
  });
}
