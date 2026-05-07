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

    test('parses v1 nested file structure into media_formats', () {
      final response = KlipyResponse.fromJson({
        'data': {
          'data': [
            {
              'slug': 'funny-cat-abc123',
              'title': 'Funny Cat',
              'file': {
                'hd': {
                  'gif': {
                    'url': 'https://cdn.klipy.com/hd.gif',
                    'width': 498,
                    'height': 498,
                    'size': 4001918,
                  },
                  'mp4': {
                    'url': 'https://cdn.klipy.com/hd.mp4',
                    'width': 498,
                    'height': 498,
                    'size': 100000,
                  },
                },
                'md': {
                  'gif': {
                    'url': 'https://cdn.klipy.com/md.gif',
                    'width': 320,
                    'height': 320,
                    'size': 1500000,
                  },
                },
                'sm': {
                  'gif': {
                    'url': 'https://cdn.klipy.com/sm.gif',
                    'width': 220,
                    'height': 220,
                    'size': 314884,
                  },
                  'mp4': {
                    'url': 'https://cdn.klipy.com/sm.mp4',
                    'width': 220,
                    'height': 220,
                    'size': 50000,
                  },
                },
                'xs': {
                  'gif': {
                    'url': 'https://cdn.klipy.com/xs.gif',
                    'width': 90,
                    'height': 90,
                    'size': 71468,
                  },
                  'jpg': {
                    'url': 'https://cdn.klipy.com/xs.jpg',
                    'width': 90,
                    'height': 90,
                    'size': 5000,
                  },
                },
              },
              'tags': ['funny', 'cat'],
            },
          ],
          'current_page': 1,
          'has_next': false,
        },
      });

      expect(response.results.length, 1);
      final item = response.results.first as KlipyGifFeedItem;
      expect(item.result.id, 'funny-cat-abc123');

      final tinyGif = item.result.media.tinyGif;
      expect(tinyGif, isNotNull);
      expect(tinyGif!.url, 'https://cdn.klipy.com/sm.gif');

      final preview = item.result.media.preview;
      expect(preview, isNotNull);
      expect(preview!.url, 'https://cdn.klipy.com/xs.jpg');
    });
  });
}
